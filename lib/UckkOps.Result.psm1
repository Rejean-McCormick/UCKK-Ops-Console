#Requires -Version 7.0
Set-StrictMode -Version Latest

<#
.SYNOPSIS
  Standard result objects for UCKK Ops Console actions.

.DESCRIPTION
  This module creates and manages ActionResult objects.

  An ActionResult is the standard return value for every public action.
  It allows the GUI, reports, logs, and modules to speak the same language.

.CONTRACT
  - Do not return raw strings from public action handlers.
  - Return ActionResult.
  - Keep visible status values stable.
  - Keep user-facing messages readable.
#>

# ---------------------------------------------------------------------------
# Official values
# ---------------------------------------------------------------------------

$script:UckkValidStatuses = @(
    "Prêt",
    "En cours",
    "Réussi",
    "Réussi avec avertissements",
    "Échoué",
    "Annulé",
    "À vérifier dans le navigateur"
)

$script:UckkValidDomains = @(
    "local",
    "git",
    "server",
    "mediatheque",
    "moodle-data",
    "tests",
    "history",
    "recovery",
    "configuration"
)

$script:UckkValidModes = @(
    "navigation",
    "vérification",
    "simulation",
    "application",
    "publication",
    "récupération",
    "test",
    "annulation"
)

$script:UckkStepStatuses = @(
    "Non lancée",
    "En cours",
    "Réussi",
    "Réussi avec avertissements",
    "Échoué",
    "Ignoré",
    "Annulé"
)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function Get-UckkResultTimestamp {
    [CmdletBinding()]
    param()

    return (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

function Test-UckkResultStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Status
    )

    return ($script:UckkValidStatuses -contains $Status)
}

function Test-UckkResultDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Domain
    )

    return ($script:UckkValidDomains -contains $Domain)
}

function Test-UckkResultMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Mode
    )

    return ($script:UckkValidModes -contains $Mode)
}

function Test-UckkStepStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Status
    )

    return ($script:UckkStepStatuses -contains $Status)
}

function Test-UckkDangerLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int] $DangerLevel
    )

    return ($DangerLevel -ge 0 -and $DangerLevel -le 7)
}

function ConvertTo-UckkArrayList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object[]] $Items = @()
    )

    $list = [System.Collections.ArrayList]::new()

    if ($null -ne $Items) {
        foreach ($item in $Items) {
            [void] $list.Add($item)
        }
    }

    return $list
}

function Ensure-UckkResultArrayList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result,

        [Parameter(Mandatory = $true)]
        [string] $PropertyName
    )

    if ($Result.PSObject.Properties.Name -notcontains $PropertyName) {
        $Result | Add-Member -MemberType NoteProperty -Name $PropertyName -Value ([System.Collections.ArrayList]::new()) -Force
        return
    }

    if ($null -eq $Result.$PropertyName) {
        $Result.$PropertyName = [System.Collections.ArrayList]::new()
        return
    }

    if ($Result.$PropertyName -isnot [System.Collections.ArrayList]) {
        $Result.$PropertyName = ConvertTo-UckkArrayList -Items @($Result.$PropertyName)
    }
}

function Get-UckkResultListCount {
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

    $countProperty = $Value.PSObject.Properties["Count"]

    if ($null -ne $countProperty) {
        try {
            return [int] $countProperty.Value
        }
        catch {
            # Fall through to enumeration.
        }
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

# ---------------------------------------------------------------------------
# Public constructors
# ---------------------------------------------------------------------------

function New-UckkActionStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet(
            "Non lancée",
            "En cours",
            "Réussi",
            "Réussi avec avertissements",
            "Échoué",
            "Ignoré",
            "Annulé"
        )]
        [string] $Status = "Non lancée",

        [Parameter(Mandatory = $false)]
        [string] $Summary = "",

        [Parameter(Mandatory = $false)]
        [string] $Detail = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null
    )

    return [pscustomobject]@{
        name      = $Name
        status    = $Status
        summary   = $Summary
        detail    = $Detail
        data      = $Data
        timestamp = Get-UckkResultTimestamp
    }
}

function New-UckkActionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery",
            "configuration"
        )]
        [string] $Domain,

        [Parameter(Mandatory = $true)]
        [string] $Target,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "navigation",
            "vérification",
            "simulation",
            "application",
            "publication",
            "récupération",
            "test",
            "annulation"
        )]
        [string] $Mode,

        [Parameter(Mandatory = $false)]
        [ValidateSet(
            "Prêt",
            "En cours",
            "Réussi",
            "Réussi avec avertissements",
            "Échoué",
            "Annulé",
            "À vérifier dans le navigateur"
        )]
        [string] $Status = "Prêt",

        [Parameter(Mandatory = $false)]
        [bool] $Success = $false,

        [Parameter(Mandatory = $false)]
        [string] $Summary = "",

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "",

        [Parameter(Mandatory = $false)]
        [string] $ReportPath = "",

        [Parameter(Mandatory = $false)]
        [string] $LogPath = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null,

        [Parameter(Mandatory = $false)]
        [object[]] $Warnings = @(),

        [Parameter(Mandatory = $false)]
        [object[]] $Errors = @(),

        [Parameter(Mandatory = $false)]
        [object[]] $Steps = @()
    )

    $now = Get-UckkResultTimestamp

    return [pscustomobject]@{
        success         = $Success
        status          = $Status
        action          = $Action
        domain          = $Domain
        target          = $Target
        dangerLevel     = $DangerLevel
        mode            = $Mode
        summary         = $Summary
        warnings        = ConvertTo-UckkArrayList -Items $Warnings
        errors          = ConvertTo-UckkArrayList -Items $Errors
        nextStep        = $NextStep
        reportPath      = $ReportPath
        logPath         = $LogPath
        data            = $Data
        steps           = ConvertTo-UckkArrayList -Items $Steps
        startedAt       = $now
        finishedAt      = ""
        durationSeconds = $null
    }
}

function New-UckkSuccessResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery",
            "configuration"
        )]
        [string] $Domain,

        [Parameter(Mandatory = $true)]
        [string] $Target,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "navigation",
            "vérification",
            "simulation",
            "application",
            "publication",
            "récupération",
            "test",
            "annulation"
        )]
        [string] $Mode,

        [Parameter(Mandatory = $true)]
        [string] $Summary,

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "Aucune action requise.",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null
    )

    return New-UckkActionResult `
        -Action $Action `
        -Domain $Domain `
        -Target $Target `
        -DangerLevel $DangerLevel `
        -Mode $Mode `
        -Status "Réussi" `
        -Success $true `
        -Summary $Summary `
        -NextStep $NextStep `
        -Data $Data
}

function New-UckkWarningResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery",
            "configuration"
        )]
        [string] $Domain,

        [Parameter(Mandatory = $true)]
        [string] $Target,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "navigation",
            "vérification",
            "simulation",
            "application",
            "publication",
            "récupération",
            "test",
            "annulation"
        )]
        [string] $Mode,

        [Parameter(Mandatory = $true)]
        [string] $Summary,

        [Parameter(Mandatory = $true)]
        [string] $Warning,

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "Lire le rapport avant de continuer.",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null
    )

    return New-UckkActionResult `
        -Action $Action `
        -Domain $Domain `
        -Target $Target `
        -DangerLevel $DangerLevel `
        -Mode $Mode `
        -Status "Réussi avec avertissements" `
        -Success $true `
        -Summary $Summary `
        -Warnings @($Warning) `
        -NextStep $NextStep `
        -Data $Data
}

function New-UckkFailureResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery",
            "configuration"
        )]
        [string] $Domain,

        [Parameter(Mandatory = $true)]
        [string] $Target,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "navigation",
            "vérification",
            "simulation",
            "application",
            "publication",
            "récupération",
            "test",
            "annulation"
        )]
        [string] $Mode,

        [Parameter(Mandatory = $true)]
        [string] $Cause,

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "Lire le rapport et le log technique.",

        [Parameter(Mandatory = $false)]
        [string] $TechnicalDetail = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null
    )

    $message = "L’action a échoué.`nCause probable : $Cause`nProchaine étape : $NextStep"

    if (-not [string]::IsNullOrWhiteSpace($TechnicalDetail)) {
        $message += "`nDétail technique : $TechnicalDetail"
    }

    return New-UckkActionResult `
        -Action $Action `
        -Domain $Domain `
        -Target $Target `
        -DangerLevel $DangerLevel `
        -Mode $Mode `
        -Status "Échoué" `
        -Success $false `
        -Summary $message `
        -Errors @($Cause) `
        -NextStep $NextStep `
        -Data $Data
}

function New-UckkErrorResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery",
            "configuration"
        )]
        [string] $Domain,

        [Parameter(Mandatory = $true)]
        [string] $Target,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "navigation",
            "vérification",
            "simulation",
            "application",
            "publication",
            "récupération",
            "test",
            "annulation"
        )]
        [string] $Mode,

        [Parameter(Mandatory = $true)]
        [string] $Cause,

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "Lire le rapport et le log technique.",

        [Parameter(Mandatory = $false)]
        [string] $TechnicalDetail = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null
    )

    return New-UckkFailureResult `
        -Action $Action `
        -Domain $Domain `
        -Target $Target `
        -DangerLevel $DangerLevel `
        -Mode $Mode `
        -Cause $Cause `
        -NextStep $NextStep `
        -TechnicalDetail $TechnicalDetail `
        -Data $Data
}

function New-UckkCancelledResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery",
            "configuration"
        )]
        [string] $Domain,

        [Parameter(Mandatory = $true)]
        [string] $Target,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $false)]
        [string] $Summary = "Annulé — aucune modification n’a été faite."
    )

    return New-UckkActionResult `
        -Action $Action `
        -Domain $Domain `
        -Target $Target `
        -DangerLevel $DangerLevel `
        -Mode "annulation" `
        -Status "Annulé" `
        -Success $false `
        -Summary $Summary `
        -NextStep "Aucune action lancée."
}

function New-UckkRefusedResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery",
            "configuration"
        )]
        [string] $Domain,

        [Parameter(Mandatory = $true)]
        [string] $Target,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "navigation",
            "vérification",
            "simulation",
            "application",
            "publication",
            "récupération",
            "test",
            "annulation"
        )]
        [string] $Mode,

        [Parameter(Mandatory = $true)]
        [string] $Cause,

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "Corriger la condition de sécurité, puis relancer."
    )

    $summary = "Action refusée.`nCause : $Cause`nProchaine étape : $NextStep"

    return New-UckkActionResult `
        -Action $Action `
        -Domain $Domain `
        -Target $Target `
        -DangerLevel $DangerLevel `
        -Mode $Mode `
        -Status "Échoué" `
        -Success $false `
        -Summary $summary `
        -Errors @($Cause) `
        -NextStep $NextStep
}

# ---------------------------------------------------------------------------
# Mutators
# ---------------------------------------------------------------------------

function Add-UckkActionWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result,

        [Parameter(Mandatory = $true)]
        [string] $Warning
    )

    Ensure-UckkResultArrayList -Result $Result -PropertyName "warnings"

    [void] $Result.warnings.Add($Warning)

    if ($Result.status -eq "Réussi") {
        $Result.status = "Réussi avec avertissements"
    }

    return $Result
}

function Add-UckkActionError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result,

        [Parameter(Mandatory = $true)]
        [string] $ErrorMessage
    )

    Ensure-UckkResultArrayList -Result $Result -PropertyName "errors"

    [void] $Result.errors.Add($ErrorMessage)

    $Result.success = $false
    $Result.status = "Échoué"

    return $Result
}

function Add-UckkActionStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result,

        [Parameter(Mandatory = $true)]
        [psobject] $Step
    )

    Ensure-UckkResultArrayList -Result $Result -PropertyName "steps"

    if (-not (Test-UckkStepStatus -Status $Step.status)) {
        throw "Invalid step status: $($Step.status)"
    }

    [void] $Result.steps.Add($Step)

    return $Result
}

function Set-UckkActionResultStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "Prêt",
            "En cours",
            "Réussi",
            "Réussi avec avertissements",
            "Échoué",
            "Annulé",
            "À vérifier dans le navigateur"
        )]
        [string] $Status,

        [Parameter(Mandatory = $false)]
        [Nullable[bool]] $Success = $null
    )

    $Result.status = $Status

    if ($null -ne $Success) {
        $Result.success = [bool] $Success
    }
    elseif ($Status -eq "Réussi" -or $Status -eq "Réussi avec avertissements" -or $Status -eq "À vérifier dans le navigateur") {
        $Result.success = $true
    }
    else {
        $Result.success = $false
    }

    return $Result
}

function Set-UckkActionResultFromSteps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result
    )

    Ensure-UckkResultArrayList -Result $Result -PropertyName "steps"

    if ((Get-UckkResultListCount -Value $Result.steps) -eq 0) {
        return $Result
    }

    $hasFailed = $false
    $hasWarnings = $false
    $hasCancelled = $false
    $hasBrowserCheck = $false

    foreach ($step in $Result.steps) {
        switch ($step.status) {
            "Échoué" {
                $hasFailed = $true
            }
            "Réussi avec avertissements" {
                $hasWarnings = $true
            }
            "Annulé" {
                $hasCancelled = $true
            }
        }

        if ($step.summary -match "navigateur") {
            $hasBrowserCheck = $true
        }
    }

    if ($hasFailed) {
        $Result.status = "Échoué"
        $Result.success = $false
    }
    elseif ($hasCancelled) {
        $Result.status = "Annulé"
        $Result.success = $false
    }
    elseif ($hasWarnings) {
        $Result.status = "Réussi avec avertissements"
        $Result.success = $true
    }
    elseif ($hasBrowserCheck) {
        $Result.status = "À vérifier dans le navigateur"
        $Result.success = $true
    }
    else {
        $Result.status = "Réussi"
        $Result.success = $true
    }

    return $Result
}

function Complete-UckkActionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result,

        [Parameter(Mandatory = $false)]
        [string] $Summary = "",

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "",

        [Parameter(Mandatory = $false)]
        [string] $ReportPath = "",

        [Parameter(Mandatory = $false)]
        [string] $LogPath = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($Summary)) {
        $Result.summary = $Summary
    }

    if (-not [string]::IsNullOrWhiteSpace($NextStep)) {
        $Result.nextStep = $NextStep
    }

    if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
        $Result.reportPath = $ReportPath
    }

    if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
        $Result.logPath = $LogPath
    }

    $Result.finishedAt = Get-UckkResultTimestamp

    try {
        $start = [datetime]::ParseExact($Result.startedAt, "yyyy-MM-dd HH:mm:ss", $null)
        $finish = [datetime]::ParseExact($Result.finishedAt, "yyyy-MM-dd HH:mm:ss", $null)
        $Result.durationSeconds = [math]::Round(($finish - $start).TotalSeconds, 3)
    }
    catch {
        $Result.durationSeconds = $null
    }

    $Result = Set-UckkActionResultFromSteps -Result $Result

    Ensure-UckkResultArrayList -Result $Result -PropertyName "errors"
    Ensure-UckkResultArrayList -Result $Result -PropertyName "warnings"

    if ((Get-UckkResultListCount -Value $Result.errors) -gt 0) {
        $Result.status = "Échoué"
        $Result.success = $false
    }
    elseif ((Get-UckkResultListCount -Value $Result.warnings) -gt 0 -and $Result.status -eq "Réussi") {
        $Result.status = "Réussi avec avertissements"
        $Result.success = $true
    }

    return $Result
}

# ---------------------------------------------------------------------------
# Summary / validation
# ---------------------------------------------------------------------------

function ConvertTo-UckkActionResultSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result
    )

    Ensure-UckkResultArrayList -Result $Result -PropertyName "warnings"
    Ensure-UckkResultArrayList -Result $Result -PropertyName "errors"

    $lines = [System.Collections.Generic.List[string]]::new()

    $lines.Add("Statut : $($Result.status)")
    $lines.Add("Action : $($Result.action)")
    $lines.Add("Cible : $($Result.target)")

    if (-not [string]::IsNullOrWhiteSpace($Result.summary)) {
        $lines.Add("Résumé : $($Result.summary)")
    }

    if ((Get-UckkResultListCount -Value $Result.warnings) -gt 0) {
        $lines.Add("Avertissements : $(Get-UckkResultListCount -Value $Result.warnings)")
    }

    if ((Get-UckkResultListCount -Value $Result.errors) -gt 0) {
        $lines.Add("Erreurs : $(Get-UckkResultListCount -Value $Result.errors)")
    }

    if (-not [string]::IsNullOrWhiteSpace($Result.nextStep)) {
        $lines.Add("Prochaine étape : $($Result.nextStep)")
    }

    if (-not [string]::IsNullOrWhiteSpace($Result.reportPath)) {
        $lines.Add("Rapport : $($Result.reportPath)")
    }

    return ($lines -join [Environment]::NewLine)
}

function Test-UckkActionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [psobject] $Result
    )

    if ($null -eq $Result) {
        return $false
    }

    $required = @(
        "success",
        "status",
        "action",
        "domain",
        "target",
        "dangerLevel",
        "mode",
        "summary",
        "warnings",
        "errors",
        "nextStep",
        "reportPath",
        "logPath",
        "data"
    )

    foreach ($field in $required) {
        if (-not ($Result.PSObject.Properties.Name -contains $field)) {
            return $false
        }
    }

    if (-not (Test-UckkResultStatus -Status $Result.status)) {
        return $false
    }

    if (-not (Test-UckkResultDomain -Domain $Result.domain)) {
        return $false
    }

    if (-not (Test-UckkResultMode -Mode $Result.mode)) {
        return $false
    }

    if (-not (Test-UckkDangerLevel -DangerLevel ([int] $Result.dangerLevel))) {
        return $false
    }

    return $true
}

function Assert-UckkActionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject] $Result
    )

    if ($null -eq $Result) {
        throw "Invalid ActionResult: result is null."
    }

    $required = @(
        "success",
        "status",
        "action",
        "domain",
        "target",
        "dangerLevel",
        "mode",
        "summary",
        "warnings",
        "errors",
        "nextStep",
        "reportPath",
        "logPath",
        "data"
    )

    foreach ($field in $required) {
        if (-not ($Result.PSObject.Properties.Name -contains $field)) {
            throw "Invalid ActionResult: missing field $field."
        }
    }

    if (-not (Test-UckkResultStatus -Status $Result.status)) {
        throw "Invalid ActionResult status: $($Result.status)"
    }

    if (-not (Test-UckkResultDomain -Domain $Result.domain)) {
        throw "Invalid ActionResult domain: $($Result.domain)"
    }

    if (-not (Test-UckkResultMode -Mode $Result.mode)) {
        throw "Invalid ActionResult mode: $($Result.mode)"
    }

    if (-not (Test-UckkDangerLevel -DangerLevel ([int] $Result.dangerLevel))) {
        throw "Invalid ActionResult dangerLevel: $($Result.dangerLevel)"
    }

    return $true
}

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

Export-ModuleMember -Function @(
    "New-UckkActionStep",
    "New-UckkActionResult",
    "New-UckkSuccessResult",
    "New-UckkWarningResult",
    "New-UckkFailureResult",
    "New-UckkErrorResult",
    "New-UckkCancelledResult",
    "New-UckkRefusedResult",
    "Add-UckkActionWarning",
    "Add-UckkActionError",
    "Add-UckkActionStep",
    "Set-UckkActionResultStatus",
    "Set-UckkActionResultFromSteps",
    "Complete-UckkActionResult",
    "ConvertTo-UckkActionResultSummary",
    "Test-UckkActionResult",
    "Assert-UckkActionResult"
)