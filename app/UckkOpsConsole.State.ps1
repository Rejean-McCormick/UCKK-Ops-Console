#Requires -Version 7.0
<#
.SYNOPSIS
  Shared runtime state for the UCKK Ops Console GUI.

.DESCRIPTION
  This file stores only interface/runtime state.

  It must not:
    - modify Moodle;
    - modify Git;
    - modify the server;
    - write to the database;
    - run commands;
    - perform recovery;
    - contain business logic.

  The GUI and action layer may read/write this state to know:
    - whether configuration is loaded;
    - what action is currently running;
    - what the last result was;
    - where the last report/log are;
    - which controls are registered;
    - which tab/status should be displayed.
#>

Set-StrictMode -Off
# -----------------------------------------------------------------------------
# Private helpers
# -----------------------------------------------------------------------------

function Get-UckkOpsConsoleDefaultAppRoot {
    [CmdletBinding()]
    param()

    if ($PSScriptRoot) {
        return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
    }

    return (Get-Location).Path
}

function Get-UckkOpsConsoleDefaultConfigPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $AppRoot
    )

    return (Join-Path $AppRoot 'config/uckk-ops-console.config.json')
}

function Get-UckkOpsConsoleObjectValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        [object] $Default = $null
    )

    if ($null -eq $InputObject) {
        return $Default
    }

    $property = $InputObject.PSObject.Properties[$Name]

    if ($null -eq $property) {
        return $Default
    }

    if ($null -eq $property.Value) {
        return $Default
    }

    return $property.Value
}

function Get-UckkOpsConsoleListCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return 0
    }

    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return 0
        }

        return 1
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $count = 0

        foreach ($key in $Value.Keys) {
            $count++
        }

        return $count
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $count = 0

        foreach ($item in $Value) {
            $count++
        }

        return $count
    }

    return 1
}

function Assert-UckkOpsConsoleState {
    [CmdletBinding()]
    param()

    if (-not (Get-Variable -Name UckkOpsConsoleState -Scope Script -ErrorAction SilentlyContinue)) {
        Initialize-UckkOpsConsoleState | Out-Null
    }

    if ($null -eq $script:UckkOpsConsoleState) {
        Initialize-UckkOpsConsoleState | Out-Null
    }
}

function New-UckkOpsConsoleHistoryList {
    [CmdletBinding()]
    param()

    return [System.Collections.Generic.List[object]]::new()
}

# -----------------------------------------------------------------------------
# State creation / reset
# -----------------------------------------------------------------------------

function New-UckkOpsConsoleState {
    [CmdletBinding()]
    param(
        [string] $AppRoot,

        [string] $ConfigPath
    )

    if ([string]::IsNullOrWhiteSpace($AppRoot)) {
        $AppRoot = Get-UckkOpsConsoleDefaultAppRoot
    }

    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        $ConfigPath = Get-UckkOpsConsoleDefaultConfigPath -AppRoot $AppRoot
    }

    return [pscustomobject]@{
        AppRoot             = $AppRoot
        StartedAt           = Get-Date

        ConfigPath          = $ConfigPath
        Config              = $null
        ConfigLoaded        = $false
        ConfigErrors        = @()
        ConfigWarnings      = @()

        ActiveTab           = 'Accueil'

        Busy                = $false
        CurrentAction       = $null
        CurrentActionStartedAt = $null

        Status              = 'Prêt'
        StatusMessage       = 'Prêt.'
        LastResult          = $null
        LastReportPath      = $null
        LastLogPath         = $null
        LastErrorMessage    = $null

        Controls            = @{}
        TabStatus           = @{}

        History             = New-UckkOpsConsoleHistoryList
        MaxHistoryItems     = 50
    }
}

function Initialize-UckkOpsConsoleState {
    [CmdletBinding()]
    param(
        [string] $AppRoot,

        [string] $ConfigPath
    )

    $script:UckkOpsConsoleState = New-UckkOpsConsoleState `
        -AppRoot $AppRoot `
        -ConfigPath $ConfigPath

    return $script:UckkOpsConsoleState
}

function Reset-UckkOpsConsoleState {
    [CmdletBinding()]
    param()

    $oldState = Get-UckkOpsConsoleState

    $script:UckkOpsConsoleState = New-UckkOpsConsoleState `
        -AppRoot $oldState.AppRoot `
        -ConfigPath $oldState.ConfigPath

    return $script:UckkOpsConsoleState
}

function Get-UckkOpsConsoleState {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState
}

# -----------------------------------------------------------------------------
# Configuration state
# -----------------------------------------------------------------------------

function Set-UckkOpsConsoleConfigPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ConfigPath
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.ConfigPath = $ConfigPath

    return $script:UckkOpsConsoleState.ConfigPath
}

function Get-UckkOpsConsoleConfigPath {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.ConfigPath
}

function Set-UckkOpsConsoleConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [string[]] $Warnings = @(),

        [string[]] $Errors = @()
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.Config = $Config
    $script:UckkOpsConsoleState.ConfigWarnings = @($Warnings)
    $script:UckkOpsConsoleState.ConfigErrors = @($Errors)
    $script:UckkOpsConsoleState.ConfigLoaded = ($null -ne $Config -and (Get-UckkOpsConsoleListCount -Value $Errors) -eq 0)

    if ($script:UckkOpsConsoleState.ConfigLoaded) {
        Set-UckkOpsConsoleStatus `
            -Status 'Prêt' `
            -Message 'Configuration chargée.' | Out-Null
    }
    else {
        Set-UckkOpsConsoleStatus `
            -Status 'Échoué' `
            -Message 'Configuration absente ou invalide.' | Out-Null
    }

    return $script:UckkOpsConsoleState.ConfigLoaded
}

function Get-UckkOpsConsoleConfig {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.Config
}

function Test-UckkOpsConsoleConfigLoaded {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return [bool] $script:UckkOpsConsoleState.ConfigLoaded
}

function Clear-UckkOpsConsoleConfig {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.Config = $null
    $script:UckkOpsConsoleState.ConfigLoaded = $false
    $script:UckkOpsConsoleState.ConfigErrors = @()
    $script:UckkOpsConsoleState.ConfigWarnings = @()

    Set-UckkOpsConsoleStatus `
        -Status 'Prêt' `
        -Message 'Configuration non chargée.' | Out-Null
}

# -----------------------------------------------------------------------------
# Active tab
# -----------------------------------------------------------------------------

function Set-UckkOpsConsoleActiveTab {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $TabName
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.ActiveTab = $TabName

    return $script:UckkOpsConsoleState.ActiveTab
}

function Get-UckkOpsConsoleActiveTab {
    [CmdletBinding()]
    param()


    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.ActiveTab
}

# -----------------------------------------------------------------------------
# Status
# -----------------------------------------------------------------------------

function Set-UckkOpsConsoleStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'Prêt',
            'En cours',
            'Réussi',
            'Réussi avec avertissements',
            'Échoué',
            'Annulé',
            'À vérifier dans le navigateur'
        )]
        [string] $Status,

        [string] $Message = ''
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.Status = $Status

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $script:UckkOpsConsoleState.StatusMessage = $Status
    }
    else {
        $script:UckkOpsConsoleState.StatusMessage = $Message
    }

    return [pscustomobject]@{
        Status  = $script:UckkOpsConsoleState.Status
        Message = $script:UckkOpsConsoleState.StatusMessage
    }
}

function Get-UckkOpsConsoleStatus {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return [pscustomobject]@{
        Status  = $script:UckkOpsConsoleState.Status
        Message = $script:UckkOpsConsoleState.StatusMessage
    }
}

function Set-UckkOpsConsoleLastError {
    [CmdletBinding()]
    param(
        [string] $Message
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.LastErrorMessage = $Message

    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        Set-UckkOpsConsoleStatus `
            -Status 'Échoué' `
            -Message $Message | Out-Null
    }
}

function Get-UckkOpsConsoleLastError {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.LastErrorMessage
}

function Clear-UckkOpsConsoleLastError {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.LastErrorMessage = $null
}

# -----------------------------------------------------------------------------
# Busy / action lock
# -----------------------------------------------------------------------------

function Start-UckkOpsConsoleActionState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ActionId,

        [Parameter(Mandatory)]
        [string] $ActionLabel,

        [string] $Domain = '',

        [string] $Target = ''
    )

    Assert-UckkOpsConsoleState

    if ($script:UckkOpsConsoleState.Busy) {
        return [pscustomobject]@{
            Started = $false
            Status  = 'Échoué'
            Message = 'Une autre action est déjà en cours.'
            CurrentAction = $script:UckkOpsConsoleState.CurrentAction
        }
    }

    $action = [pscustomobject]@{
        Id        = $ActionId
        Label     = $ActionLabel
        Domain    = $Domain
        Target    = $Target
        StartedAt = Get-Date
    }

    $script:UckkOpsConsoleState.Busy = $true
    $script:UckkOpsConsoleState.CurrentAction = $action
    $script:UckkOpsConsoleState.CurrentActionStartedAt = $action.StartedAt

    Set-UckkOpsConsoleStatus `
        -Status 'En cours' `
        -Message ("En cours — {0}" -f $ActionLabel) | Out-Null

    return [pscustomobject]@{
        Started = $true
        Status  = 'En cours'
        Message = ("En cours — {0}" -f $ActionLabel)
        CurrentAction = $action
    }
}

function Stop-UckkOpsConsoleActionState {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Result = $null
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.Busy = $false
    $script:UckkOpsConsoleState.CurrentAction = $null
    $script:UckkOpsConsoleState.CurrentActionStartedAt = $null

    if ($null -ne $Result) {
        Set-UckkOpsConsoleLastResult -Result $Result | Out-Null
    }
    else {
        Set-UckkOpsConsoleStatus `
            -Status 'Prêt' `
            -Message 'Prêt.' | Out-Null
    }

    return $true
}

function Test-UckkOpsConsoleBusy {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return [bool] $script:UckkOpsConsoleState.Busy
}

function Get-UckkOpsConsoleCurrentAction {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.CurrentAction
}

# -----------------------------------------------------------------------------
# Last result / report / log
# -----------------------------------------------------------------------------

function Set-UckkOpsConsoleLastResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Result
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.LastResult = $Result

    $status = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'status' `
        -Default 'Prêt'

    $summary = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'summary' `
        -Default $status

    $reportPath = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'reportPath' `
        -Default $null

    $logPath = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'logPath' `
        -Default $null

    if (-not [string]::IsNullOrWhiteSpace([string] $reportPath)) {
        $script:UckkOpsConsoleState.LastReportPath = [string] $reportPath
    }

    if (-not [string]::IsNullOrWhiteSpace([string] $logPath)) {
        $script:UckkOpsConsoleState.LastLogPath = [string] $logPath
    }

    Set-UckkOpsConsoleStatus `
        -Status $status `
        -Message $summary | Out-Null

    Add-UckkOpsConsoleHistoryItem -Result $Result | Out-Null

    return $script:UckkOpsConsoleState.LastResult
}

function Get-UckkOpsConsoleLastResult {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.LastResult
}

function Clear-UckkOpsConsoleLastResult {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.LastResult = $null
    $script:UckkOpsConsoleState.LastReportPath = $null
    $script:UckkOpsConsoleState.LastLogPath = $null
}

function Set-UckkOpsConsoleLastReportPath {
    [CmdletBinding()]
    param(
        [string] $ReportPath
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.LastReportPath = $ReportPath

    return $script:UckkOpsConsoleState.LastReportPath
}

function Get-UckkOpsConsoleLastReportPath {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.LastReportPath
}

function Set-UckkOpsConsoleLastLogPath {
    [CmdletBinding()]
    param(
        [string] $LogPath
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.LastLogPath = $LogPath

    return $script:UckkOpsConsoleState.LastLogPath
}

function Get-UckkOpsConsoleLastLogPath {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.LastLogPath
}

# -----------------------------------------------------------------------------
# History
# -----------------------------------------------------------------------------

function Add-UckkOpsConsoleHistoryItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Result
    )

    Assert-UckkOpsConsoleState

    if ($null -eq $Result) {
        return $null
    }

    $item = [pscustomobject]@{
        CreatedAt  = Get-Date
        Status     = Get-UckkOpsConsoleObjectValue -InputObject $Result -Name 'status' -Default ''
        Action     = Get-UckkOpsConsoleObjectValue -InputObject $Result -Name 'action' -Default ''
        Domain     = Get-UckkOpsConsoleObjectValue -InputObject $Result -Name 'domain' -Default ''
        Target     = Get-UckkOpsConsoleObjectValue -InputObject $Result -Name 'target' -Default ''
        Summary    = Get-UckkOpsConsoleObjectValue -InputObject $Result -Name 'summary' -Default ''
        ReportPath = Get-UckkOpsConsoleObjectValue -InputObject $Result -Name 'reportPath' -Default ''
        LogPath    = Get-UckkOpsConsoleObjectValue -InputObject $Result -Name 'logPath' -Default ''
        Result     = $Result
    }

    $script:UckkOpsConsoleState.History.Insert(0, $item)

    while ((Get-UckkOpsConsoleListCount -Value $script:UckkOpsConsoleState.History) -gt $script:UckkOpsConsoleState.MaxHistoryItems) {
        $lastIndex = (Get-UckkOpsConsoleListCount -Value $script:UckkOpsConsoleState.History) - 1
        $script:UckkOpsConsoleState.History.RemoveAt($lastIndex)
    }

    return $item
}

function Get-UckkOpsConsoleHistory {
    [CmdletBinding()]
    param(
        [int] $First = 0
    )


    Assert-UckkOpsConsoleState

    $items = @($script:UckkOpsConsoleState.History)

    if ($First -gt 0) {
        return @($items | Select-Object -First $First)
    }

    return $items
}

function Clear-UckkOpsConsoleHistory {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.History.Clear()

    return $true
}

# -----------------------------------------------------------------------------
# Control registry
# -----------------------------------------------------------------------------

function Register-UckkOpsConsoleControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Control
    )

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.Controls[$Name] = $Control

    return $Control
}

function Get-UckkOpsConsoleControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    Assert-UckkOpsConsoleState

    if (-not $script:UckkOpsConsoleState.Controls.ContainsKey($Name)) {
        return $null
    }

    return $script:UckkOpsConsoleState.Controls[$Name]
}

function Get-UckkOpsConsoleControls {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return $script:UckkOpsConsoleState.Controls
}

function Clear-UckkOpsConsoleControls {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.Controls.Clear()

    return $true
}

# -----------------------------------------------------------------------------
# Tab status
# -----------------------------------------------------------------------------

function Set-UckkOpsConsoleTabStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $TabName,

        [Parameter(Mandatory)]
        [ValidateSet(
            'Prêt',
            'En cours',
            'Réussi',
            'Réussi avec avertissements',
            'Échoué',
            'Annulé',
            'À vérifier dans le navigateur'
        )]
        [string] $Status,

        [string] $Message = ''
    )

    Assert-UckkOpsConsoleState

    $entry = [pscustomobject]@{
        TabName   = $TabName
        Status    = $Status
        Message   = $Message
        UpdatedAt = Get-Date
    }

    $script:UckkOpsConsoleState.TabStatus[$TabName] = $entry

    return $entry
}

function Get-UckkOpsConsoleTabStatus {
    [CmdletBinding()]
    param(
        [string] $TabName = ''
    )

    Assert-UckkOpsConsoleState

    if ([string]::IsNullOrWhiteSpace($TabName)) {
        return $script:UckkOpsConsoleState.TabStatus
    }

    if (-not $script:UckkOpsConsoleState.TabStatus.ContainsKey($TabName)) {
        return [pscustomobject]@{
            TabName   = $TabName
            Status    = 'Prêt'
            Message   = ''
            UpdatedAt = $null
        }
    }

    return $script:UckkOpsConsoleState.TabStatus[$TabName]
}

function Clear-UckkOpsConsoleTabStatus {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    $script:UckkOpsConsoleState.TabStatus.Clear()

    return $true
}

# -----------------------------------------------------------------------------
# Display helpers
# -----------------------------------------------------------------------------

function ConvertTo-UckkOpsConsoleResultSummary {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Result
    )

    if ($null -eq $Result) {
        return 'Aucun résultat.'
    }

    $status = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'status' `
        -Default 'Prêt'

    $action = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'action' `
        -Default ''

    $target = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'target' `
        -Default ''

    $summary = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'summary' `
        -Default ''

    $nextStep = Get-UckkOpsConsoleObjectValue `
        -InputObject $Result `
        -Name 'nextStep' `
        -Default ''

    $lines = [System.Collections.Generic.List[string]]::new()

    $lines.Add(("Statut : {0}" -f $status))

    if (-not [string]::IsNullOrWhiteSpace([string] $action)) {
        $lines.Add(("Action : {0}" -f $action))
    }

    if (-not [string]::IsNullOrWhiteSpace([string] $target)) {
        $lines.Add(("Cible : {0}" -f $target))
    }

    if (-not [string]::IsNullOrWhiteSpace([string] $summary)) {
        $lines.Add(("Résumé : {0}" -f $summary))
    }

    if (-not [string]::IsNullOrWhiteSpace([string] $nextStep)) {
        $lines.Add(("Prochaine étape : {0}" -f $nextStep))
    }

    return ($lines -join [Environment]::NewLine)
}

function Get-UckkOpsConsoleLastResultSummary {
    [CmdletBinding()]
    param()

    Assert-UckkOpsConsoleState

    return ConvertTo-UckkOpsConsoleResultSummary `
        -Result $script:UckkOpsConsoleState.LastResult
}

# -----------------------------------------------------------------------------
# Initialize on dot-source
# -----------------------------------------------------------------------------

Initialize-UckkOpsConsoleState | Out-Null
