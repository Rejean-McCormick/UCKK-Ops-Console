#Requires -Version 7.0
<#
.SYNOPSIS
  Main Données Moodle action layer for UCKK Ops Console.

.DESCRIPTION
  This module exposes the public actions used by the GUI for Données Moodle.

  It coordinates:
    - source file discovery;
    - JSON validation;
    - local simulations;
    - local applications;
    - server simulations;
    - server applications;
    - result shaping.

  It must respect the contract:

    fichier source → validation → simulation → appliquer → vérifier

  This module must not:
    - hide local/server targets;
    - apply server data without confirmation;
    - use raw SQL as a normal workflow;
    - copy database tables directly;
    - handle personal user data;
    - treat Médiathèque as Moodle Data.

  Detailed JSON validation belongs in:
    modules/moodle-data/UckkOps.MoodleData.Json.psm1

  Detailed apply/simulation logic belongs in:
    modules/moodle-data/UckkOps.MoodleData.Apply.psm1
#>

Set-StrictMode -Off
# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

$script:UckkMoodleDataDomain = 'moodle-data'

$script:UckkMoodleDataSupportedDomains = @(
    'categories',
    'courses',
    'programs',
    'pathways'
)

$script:UckkMoodleDataDomainLabels = @{
    categories = 'catégories'
    courses    = 'cours'
    programs   = 'programmes'
    pathways   = 'parcours'
}

$script:UckkMoodleDataDefaultFiles = @{
    categories = 'categories.json'
    courses    = 'courses.json'
    programs   = 'programs.json'
    pathways   = 'pathways.json'
}

# -----------------------------------------------------------------------------
# Generic helpers
# -----------------------------------------------------------------------------

function Get-UckkMoodleDataObjectValue {
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

    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

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

function Test-UckkMoodleDataHasCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    return ($null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue))
}

function Join-UckkMoodleDataPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $BasePath,

        [Parameter(Mandatory)]
        [string] $ChildPath
    )

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        return $ChildPath
    }

    if ([string]::IsNullOrWhiteSpace($ChildPath)) {
        return $BasePath
    }

    if ([System.IO.Path]::IsPathRooted($ChildPath)) {
        return $ChildPath
    }

    return (Join-Path $BasePath $ChildPath)
}

function ConvertTo-UckkMoodleDataArray {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $InputObject
    )

    if ($null -eq $InputObject) {
        return @()
    }

    if ($InputObject -is [string]) {
        return @($InputObject)
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return @($InputObject)
    }

    if ($InputObject -is [System.Collections.IEnumerable]) {
        return @($InputObject)
    }

    return @($InputObject)
}

function New-UckkMoodleDataResult {
    [CmdletBinding()]
    param(
        [bool] $Success = $false,

        [ValidateSet(
            'Prêt',
            'En cours',
            'Réussi',
            'Réussi avec avertissements',
            'Échoué',
            'Annulé',
            'À vérifier dans le navigateur'
        )]
        [string] $Status = 'Prêt',

        [string] $Action = 'Données Moodle',

        [string] $Target = '',

        [ValidateRange(0, 7)]
        [int] $DangerLevel = 1,

        [ValidateSet(
            'navigation',
            'vérification',
            'simulation',
            'application',
            'publication',
            'récupération',
            'test',
            'annulation'
        )]
        [string] $Mode = 'vérification',

        [string] $Summary = '',

        [string[]] $Warnings = @(),

        [string[]] $Errors = @(),

        [string] $NextStep = '',

        [string] $ReportPath = '',

        [string] $LogPath = '',

        [AllowNull()]
        [object] $Data = $null
    )

    return [pscustomobject]@{
        success     = $Success
        status      = $Status
        action      = $Action
        domain      = $script:UckkMoodleDataDomain
        target      = $Target
        dangerLevel = $DangerLevel
        mode        = $Mode
        summary     = $Summary
        warnings    = @($Warnings)
        errors      = @($Errors)
        nextStep    = $NextStep
        reportPath  = $ReportPath
        logPath     = $LogPath
        data        = $Data
    }
}

function Get-UckkMoodleDataDomainLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $DataDomain
    )

    if ($script:UckkMoodleDataDomainLabels.ContainsKey($DataDomain)) {
        return $script:UckkMoodleDataDomainLabels[$DataDomain]
    }

    return $DataDomain
}

function Assert-UckkMoodleDataDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $DataDomain
    )

    if ($script:UckkMoodleDataSupportedDomains -notcontains $DataDomain) {
        throw ("Domaine Données Moodle non supporté : {0}" -f $DataDomain)
    }

    return $true
}

# -----------------------------------------------------------------------------
# Config helpers
# -----------------------------------------------------------------------------

function Get-UckkMoodleDataConfigSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [string] $SectionName
    )

    if ($null -eq $Config) {
        return $null
    }

    return Get-UckkMoodleDataObjectValue `
        -InputObject $Config `
        -Name $SectionName `
        -Default $null
}

function Get-UckkMoodleDataSourceDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [ValidateSet('local', 'server')]
        [string] $Target = 'local'
    )

    $moodleData = Get-UckkMoodleDataConfigSection -Config $Config -SectionName 'moodleData'
    $paths = Get-UckkMoodleDataConfigSection -Config $Config -SectionName 'paths'

    $configured = $null

    if ($null -ne $moodleData) {
        if ($Target -eq 'server') {
            $configured = Get-UckkMoodleDataObjectValue -InputObject $moodleData -Name 'serverSourceDir' -Default $null
        }

        if ([string]::IsNullOrWhiteSpace([string] $configured)) {
            $configured = Get-UckkMoodleDataObjectValue -InputObject $moodleData -Name 'sourceDir' -Default $null
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string] $configured)) {
        return [string] $configured
    }

    if ($Target -eq 'server') {
        $serverSource = Get-UckkMoodleDataObjectValue -InputObject $paths -Name 'serverMoodleSource' -Default ''
        if (-not [string]::IsNullOrWhiteSpace([string] $serverSource)) {
            return (Join-UckkMoodleDataPath -BasePath ([string] $serverSource) -ChildPath 'academic_registry_json')
        }
    }

    $localSource = Get-UckkMoodleDataObjectValue -InputObject $paths -Name 'uckkMoodleSource' -Default ''
    if (-not [string]::IsNullOrWhiteSpace([string] $localSource)) {
        return (Join-UckkMoodleDataPath -BasePath ([string] $localSource) -ChildPath 'academic_registry_json')
    }

    return 'academic_registry_json'
}

function Get-UckkMoodleDataConfiguredFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $DataDomain
    )

    Assert-UckkMoodleDataDomain -DataDomain $DataDomain | Out-Null

    $moodleData = Get-UckkMoodleDataConfigSection -Config $Config -SectionName 'moodleData'
$propertyMap = @{
        categories = 'categoriesFile'
        courses    = 'coursesFile'
        programs   = 'programsFile'
        pathways   = 'pathwaysFile'
    }

    $propertyName = $propertyMap[$DataDomain]

    if ($null -ne $moodleData) {
        $configured = Get-UckkMoodleDataObjectValue `
            -InputObject $moodleData `
            -Name $propertyName `
            -Default $null

        if (-not [string]::IsNullOrWhiteSpace([string] $configured)) {
            return [string] $configured
        }
    }

    return $script:UckkMoodleDataDefaultFiles[$DataDomain]
}

function Get-UckkMoodleDataSourceFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $DataDomain,

        [ValidateSet('local', 'server')]
        [string] $Target = 'local'
    )

    Assert-UckkMoodleDataDomain -DataDomain $DataDomain | Out-Null

    $sourceDir = Get-UckkMoodleDataSourceDir `
        -Config $Config `
        -Target $Target

    $fileName = Get-UckkMoodleDataConfiguredFileName `
        -Config $Config `
        -DataDomain $DataDomain

    return (Join-UckkMoodleDataPath -BasePath $sourceDir -ChildPath $fileName)
}

function Get-UckkMoodleDataFileMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [ValidateSet('local', 'server')]
        [string] $Target = 'local'
    )

    $map = [ordered]@{}

    foreach ($domainName in $script:UckkMoodleDataSupportedDomains) {
        $map[$domainName] = Get-UckkMoodleDataSourceFile `
            -Config $Config `
            -DataDomain $domainName `
            -Target $Target
    }

    return [pscustomobject]$map
}

function Get-UckkMoodleDataSupportedDomains {
    [CmdletBinding()]
    param()

    return @($script:UckkMoodleDataSupportedDomains)
}

# -----------------------------------------------------------------------------
# Validation actions
# -----------------------------------------------------------------------------

function Test-UckkMoodleDataModuleDependencies {
    [CmdletBinding()]
    param()

    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    $optionalCommands = @(
        'Test-UckkMoodleDataJsonFile',
        'Invoke-UckkMoodleDataApply',
        'Write-UckkReport',
        'Write-UckkLog',
        'Confirm-UckkAction'
    )

    foreach ($commandName in $optionalCommands) {
        if (-not (Test-UckkMoodleDataHasCommand -Name $commandName)) {
            $warnings.Add(("Commande non chargée pour l instant : {0}" -f $commandName))
        }
    }

    $status = if ($errors.Count -gt 0) {
        'Échoué'
    }
    elseif ($warnings.Count -gt 0) {
        'Réussi avec avertissements'
    }
    else {
        'Réussi'
    }

    return New-UckkMoodleDataResult `
        -Success ($errors.Count -eq 0) `
        -Status $status `
        -Action 'Vérifier module Données Moodle' `
        -Target 'Données Moodle' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'Vérification du module Données Moodle terminée.' `
        -Warnings @($warnings) `
        -Errors @($errors) `
        -NextStep 'Continuer avec "Vérifier fichiers JSON Moodle".' `
        -Data @{
            commandsChecked = @($optionalCommands)
        }
}

function Test-UckkMoodleDataSourceFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [ValidateSet('local', 'server')]
        [string] $Target = 'local'
    )

    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $files = [System.Collections.Generic.List[object]]::new()

    foreach ($domainName in $script:UckkMoodleDataSupportedDomains) {
        $path = Get-UckkMoodleDataSourceFile `
            -Config $Config `
            -DataDomain $domainName `
            -Target $Target

        $exists = Test-Path -LiteralPath $path

        if (-not $exists) {
            $errors.Add(("Fichier source introuvable pour {0} : {1}" -f (Get-UckkMoodleDataDomainLabel -DataDomain $domainName), $path))
        }

        $files.Add([pscustomobject]@{
            domain = $domainName
            label  = Get-UckkMoodleDataDomainLabel -DataDomain $domainName
            path   = $path
            exists = $exists
        })
    }

    $success = ($errors.Count -eq 0)
    $status = if ($success) { 'Réussi' } else { 'Échoué' }
    $targetLabel = if ($Target -eq 'server') { 'serveur' } else { 'local' }

    return New-UckkMoodleDataResult `
        -Success $success `
        -Status $status `
        -Action 'Vérifier fichiers sources Données Moodle' `
        -Target $targetLabel `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary ($(if ($success) { 'Tous les fichiers sources Données Moodle existent.' } else { 'Un ou plusieurs fichiers sources Données Moodle sont introuvables.' })) `
        -Warnings @($warnings) `
        -Errors @($errors) `
        -NextStep ($(if ($success) { 'Lancer "Vérifier fichiers JSON Moodle".' } else { 'Corriger les chemins ou créer les fichiers JSON manquants.' })) `
        -Data @{
            target = $Target
            files  = @($files)
        }
}

function Test-UckkMoodleDataJsonFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [ValidateSet('local', 'server')]
        [string] $Target = 'local'
    )

    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($domainName in $script:UckkMoodleDataSupportedDomains) {
        $path = Get-UckkMoodleDataSourceFile `
            -Config $Config `
            -DataDomain $domainName `
            -Target $Target

        if (Test-UckkMoodleDataHasCommand -Name 'Test-UckkMoodleDataJsonFile') {
            $domainResult = Test-UckkMoodleDataJsonFile `
                -Path $path `
                -DataDomain $domainName
        }
        elseif (Test-UckkMoodleDataHasCommand -Name 'Test-UckkJsonFile') {
            $domainResult = Test-UckkJsonFile -Path $path
        }
        else {
            $domainResult = [pscustomobject]@{
                success  = (Test-Path -LiteralPath $path)
                status   = if (Test-Path -LiteralPath $path) { 'Réussi' } else { 'Échoué' }
                warnings = @()
                errors   = if (Test-Path -LiteralPath $path) { @() } else { @("Fichier introuvable : $path") }
                data     = @{
                    path = $path
                }
            }
        }

        $results.Add([pscustomobject]@{
            domain = $domainName
            label  = Get-UckkMoodleDataDomainLabel -DataDomain $domainName
            path   = $path
            result = $domainResult
        })

        foreach ($warning in @($domainResult.warnings)) {
            $warnings.Add(("{0} : {1}" -f (Get-UckkMoodleDataDomainLabel -DataDomain $domainName), $warning))
        }

        foreach ($errorItem in @($domainResult.errors)) {
            $errors.Add(("{0} : {1}" -f (Get-UckkMoodleDataDomainLabel -DataDomain $domainName), $errorItem))
        }

        if ($domainResult.success -eq $false -and @($domainResult.errors).Count -eq 0) {
            $errors.Add(("{0} : validation JSON échouée." -f (Get-UckkMoodleDataDomainLabel -DataDomain $domainName)))
        }
    }

    $success = ($errors.Count -eq 0)
    $status = if ($success -and $warnings.Count -gt 0) {
        'Réussi avec avertissements'
    }
    elseif ($success) {
        'Réussi'
    }
    else {
        'Échoué'
    }

    $targetLabel = if ($Target -eq 'server') { 'serveur' } else { 'local' }

    return New-UckkMoodleDataResult `
        -Success $success `
        -Status $status `
        -Action 'Vérifier fichiers JSON Moodle' `
        -Target $targetLabel `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary ($(if ($success) { 'Les fichiers JSON Moodle sont valides.' } else { 'Un ou plusieurs fichiers JSON Moodle sont invalides.' })) `
        -Warnings @($warnings) `
        -Errors @($errors) `
        -NextStep ($(if ($success) { 'Lancer une simulation avant application.' } else { 'Corriger les fichiers JSON, puis relancer la vérification.' })) `
        -Data @{
            target  = $Target
            results = @($results)
        }
}

# -----------------------------------------------------------------------------
# Generic simulation / apply dispatcher
# -----------------------------------------------------------------------------

function Invoke-UckkMoodleDataDomainAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $DataDomain,

        [Parameter(Mandatory)]
        [ValidateSet('local', 'server')]
        [string] $Target,

        [Parameter(Mandatory)]
        [ValidateSet('simulation', 'application')]
        [string] $Mode,

        [switch] $SkipConfirmation
    )

    Assert-UckkMoodleDataDomain -DataDomain $DataDomain | Out-Null

    $label = Get-UckkMoodleDataDomainLabel -DataDomain $DataDomain
    $targetLabel = if ($Target -eq 'server') { 'serveur' } else { 'local' }

    $actionVerb = if ($Mode -eq 'simulation') { 'Simulation' } else { 'Appliquer' }

    $actionName = if ($Mode -eq 'simulation') {
        "Simulation $label $targetLabel"
    }
    elseif ($Target -eq 'server') {
        "Appliquer $label serveur"
    }
    else {
        "Appliquer $label localement"
    }

    $dangerLevel = if ($Mode -eq 'simulation') {
        1
    }
    elseif ($Target -eq 'server') {
        6
    }
    else {
        4
    }

    $targetText = if ($Mode -eq 'simulation') {
        if ($Target -eq 'server') { 'base Moodle serveur' } else { 'base Moodle locale' }
    }
    else {
        if ($Target -eq 'server') { 'base Moodle serveur' } else { 'base Moodle locale' }
    }

    $sourcePath = Get-UckkMoodleDataSourceFile `
        -Config $Config `
        -DataDomain $DataDomain `
        -Target $Target

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        return New-UckkMoodleDataResult `
            -Success $false `
            -Status 'Échoué' `
            -Action $actionName `
            -Target $targetText `
            -DangerLevel $dangerLevel `
-Mode $Mode `

            -Summary 'Le fichier source Données Moodle est introuvable.' `
            -Errors @("Fichier introuvable : $sourcePath") `
            -NextStep 'Corriger la configuration ou créer le fichier source, puis relancer la validation.' `
            -Data @{
                dataDomain = $DataDomain
                sourcePath = $sourcePath
                target     = $Target
            }
    }

    if ($Mode -eq 'application' -and -not $SkipConfirmation) {
        $confirmationMessage = if ($Target -eq 'server') {
            'Cette action écrit dans la base Moodle serveur. Continuer ?'
        }
        else {
            'Cette action écrit dans la base Moodle locale. Continuer ?'
        }

        if (Test-UckkMoodleDataHasCommand -Name 'Confirm-UckkAction') {
            $confirmed = Confirm-UckkAction `
                -Action $actionName `
                -Target $targetText `
                -DangerLevel $dangerLevel `
                -Message $confirmationMessage `
                -WouldWriteDatabase `
                -WouldModifyServer:($Target -eq 'server')

            if (-not $confirmed) {
                return New-UckkMoodleDataResult `
                    -Success $false `
                    -Status 'Annulé' `
                    -Action $actionName `
                    -Target $targetText `
                    -DangerLevel $dangerLevel `
                    -Mode 'annulation' `
                    -Summary 'Annulé — aucune modification n a été faite.' `
                    -NextStep 'Aucune action requise.' `
                    -Data @{
                        dataDomain = $DataDomain
                        sourcePath = $sourcePath
                        target     = $Target
                    }
            }
        }
    }

    if (Test-UckkMoodleDataHasCommand -Name 'Invoke-UckkMoodleDataApply') {
        return Invoke-UckkMoodleDataApply `
            -Config $Config `
            -DataDomain $DataDomain `
            -Target $Target `
            -Mode $Mode `
            -SourcePath $sourcePath
    }

    $summary = if ($Mode -eq 'simulation') {
        "Simulation $label $targetLabel préparée. Aucune donnée Moodle n a été modifiée."
    }
    else {
        "Application $label $targetLabel demandée, mais le moteur d application n est pas encore chargé."
    }

    $warnings = if ($Mode -eq 'application') {
        @('Le moteur d application Données Moodle n est pas encore chargé : Invoke-UckkMoodleDataApply est introuvable.')
    }
    else {
        @('Le moteur de simulation Données Moodle n est pas encore chargé : Invoke-UckkMoodleDataApply est introuvable.')
    }

    $status = if ($Mode -eq 'simulation') { 'Réussi avec avertissements' } else { 'Échoué' }
    $success = ($Mode -eq 'simulation')

    return New-UckkMoodleDataResult `
        -Success $success `
        -Status $status `
        -Action $actionName `
        -Target $targetText `
        -DangerLevel $dangerLevel `
        -Mode $Mode `
        -Summary $summary `
        -Warnings $warnings `
        -Errors ($(if ($success) { @() } else { @('Moteur d application Données Moodle introuvable.') })) `
        -NextStep ($(if ($success) { 'Charger le module d application pour obtenir une vraie simulation détaillée.' } else { 'Charger modules/moodle-data/UckkOps.MoodleData.Apply.psm1, puis relancer.' })) `
        -Data @{
            dataDomain = $DataDomain
            sourcePath = $sourcePath
            target     = $Target
        }
}

# -----------------------------------------------------------------------------
# Generic public actions
# -----------------------------------------------------------------------------

function Invoke-UckkMoodleDataSimulationLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $DataDomain
    )

    return Invoke-UckkMoodleDataDomainAction `
        -Config $Config `
        -DataDomain $DataDomain `
        -Target 'local' `
        -Mode 'simulation'
}

function Invoke-UckkMoodleDataApplyLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $DataDomain,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataDomainAction `
        -Config $Config `
        -DataDomain $DataDomain `
        -Target 'local' `
        -Mode 'application' `
        -SkipConfirmation:$SkipConfirmation
}

function Invoke-UckkMoodleDataSimulationServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $DataDomain
    )

    return Invoke-UckkMoodleDataDomainAction `
        -Config $Config `
        -DataDomain $DataDomain `
        -Target 'server' `
        -Mode 'simulation'
}

function Invoke-UckkMoodleDataApplyServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $DataDomain,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataDomainAction `
        -Config $Config `
        -DataDomain $DataDomain `
        -Target 'server' `
        -Mode 'application' `
        -SkipConfirmation:$SkipConfirmation
}

# -----------------------------------------------------------------------------
# Category wrappers
# -----------------------------------------------------------------------------

function Invoke-UckkMoodleDataCategoriesSimulationLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    return Invoke-UckkMoodleDataSimulationLocal `
        -Config $Config `
        -DataDomain 'categories'
}

function Invoke-UckkMoodleDataCategoriesApplyLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataApplyLocal `
        -Config $Config `
        -DataDomain 'categories' `
        -SkipConfirmation:$SkipConfirmation
}

function Invoke-UckkMoodleDataCategoriesSimulationServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    return Invoke-UckkMoodleDataSimulationServer `
        -Config $Config `
        -DataDomain 'categories'
}

function Invoke-UckkMoodleDataCategoriesApplyServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataApplyServer `
        -Config $Config `
        -DataDomain 'categories' `
        -SkipConfirmation:$SkipConfirmation
}

# -----------------------------------------------------------------------------
# Course wrappers
# -----------------------------------------------------------------------------

function Invoke-UckkMoodleDataCoursesSimulationLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    return Invoke-UckkMoodleDataSimulationLocal `
        -Config $Config `
        -DataDomain 'courses'
}

function Invoke-UckkMoodleDataCoursesApplyLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataApplyLocal `
        -Config $Config `
        -DataDomain 'courses' `
        -SkipConfirmation:$SkipConfirmation
}

function Invoke-UckkMoodleDataCoursesSimulationServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    return Invoke-UckkMoodleDataSimulationServer `
        -Config $Config `
        -DataDomain 'courses'
}

function Invoke-UckkMoodleDataCoursesApplyServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataApplyServer `
        -Config $Config `
        -DataDomain 'courses' `
        -SkipConfirmation:$SkipConfirmation
}

# -----------------------------------------------------------------------------
# Program wrappers
# -----------------------------------------------------------------------------

function Invoke-UckkMoodleDataProgramsSimulationLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    return Invoke-UckkMoodleDataSimulationLocal `
        -Config $Config `
        -DataDomain 'programs'
}

function Invoke-UckkMoodleDataProgramsApplyLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataApplyLocal `
        -Config $Config `
        -DataDomain 'programs' `
        -SkipConfirmation:$SkipConfirmation
}

function Invoke-UckkMoodleDataProgramsSimulationServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    return Invoke-UckkMoodleDataSimulationServer `
        -Config $Config `
        -DataDomain 'programs'
}

function Invoke-UckkMoodleDataProgramsApplyServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,
[switch] $SkipConfirmation

    )

    return Invoke-UckkMoodleDataApplyServer `
        -Config $Config `
        -DataDomain 'programs' `
        -SkipConfirmation:$SkipConfirmation
}

# -----------------------------------------------------------------------------
# Pathway wrappers
# -----------------------------------------------------------------------------

function Invoke-UckkMoodleDataPathwaysSimulationLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    return Invoke-UckkMoodleDataSimulationLocal `
        -Config $Config `
        -DataDomain 'pathways'
}

function Invoke-UckkMoodleDataPathwaysApplyLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataApplyLocal `
        -Config $Config `
        -DataDomain 'pathways' `
        -SkipConfirmation:$SkipConfirmation
}

function Invoke-UckkMoodleDataPathwaysSimulationServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    return Invoke-UckkMoodleDataSimulationServer `
        -Config $Config `
        -DataDomain 'pathways'
}

function Invoke-UckkMoodleDataPathwaysApplyServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config,

        [switch] $SkipConfirmation
    )

    return Invoke-UckkMoodleDataApplyServer `
        -Config $Config `
        -DataDomain 'pathways' `
        -SkipConfirmation:$SkipConfirmation
}

# -----------------------------------------------------------------------------
# UI helper
# -----------------------------------------------------------------------------

function Get-UckkMoodleDataActionSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Config
    )

    $localMap = Get-UckkMoodleDataFileMap -Config $Config -Target 'local'
    $serverMap = Get-UckkMoodleDataFileMap -Config $Config -Target 'server'

    return [pscustomobject]@{
        domain           = $script:UckkMoodleDataDomain
        supportedDomains = @($script:UckkMoodleDataSupportedDomains)
        localFiles       = $localMap
        serverFiles      = $serverMap
        workflow         = 'fichier source → validation → simulation → appliquer → vérifier'
        normalActions    = @(
            'Vérifier fichiers JSON Moodle',
            'Simulation catégories locales',
            'Appliquer catégories localement',
            'Simulation catégories serveur',
            'Appliquer catégories serveur',
            'Simulation cours locaux',
            'Appliquer cours localement',
            'Simulation cours serveur',
            'Appliquer cours serveur',
            'Simulation programmes locaux',
            'Appliquer programmes localement',
            'Simulation programmes serveur',
            'Appliquer programmes serveur',
            'Simulation parcours locaux',
            'Appliquer parcours localement',
            'Simulation parcours serveur',
            'Appliquer parcours serveur'
        )
    }
}

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

Export-ModuleMember -Function @(
    'Get-UckkMoodleDataSupportedDomains',
    'Get-UckkMoodleDataDomainLabel',
    'Get-UckkMoodleDataSourceDir',
    'Get-UckkMoodleDataSourceFile',
    'Get-UckkMoodleDataFileMap',
    'Test-UckkMoodleDataModuleDependencies',
    'Test-UckkMoodleDataSourceFiles',
    'Test-UckkMoodleDataJsonFiles',
    'Invoke-UckkMoodleDataSimulationLocal',
    'Invoke-UckkMoodleDataApplyLocal',
    'Invoke-UckkMoodleDataSimulationServer',
    'Invoke-UckkMoodleDataApplyServer',
    'Invoke-UckkMoodleDataCategoriesSimulationLocal',
    'Invoke-UckkMoodleDataCategoriesApplyLocal',
    'Invoke-UckkMoodleDataCategoriesSimulationServer',
    'Invoke-UckkMoodleDataCategoriesApplyServer',
    'Invoke-UckkMoodleDataCoursesSimulationLocal',
    'Invoke-UckkMoodleDataCoursesApplyLocal',
    'Invoke-UckkMoodleDataCoursesSimulationServer',
    'Invoke-UckkMoodleDataCoursesApplyServer',
    'Invoke-UckkMoodleDataProgramsSimulationLocal',
    'Invoke-UckkMoodleDataProgramsApplyLocal',
    'Invoke-UckkMoodleDataProgramsSimulationServer',
    'Invoke-UckkMoodleDataProgramsApplyServer',
    'Invoke-UckkMoodleDataPathwaysSimulationLocal',
    'Invoke-UckkMoodleDataPathwaysApplyLocal',
    'Invoke-UckkMoodleDataPathwaysSimulationServer',
    'Invoke-UckkMoodleDataPathwaysApplyServer',
    'Get-UckkMoodleDataActionSummary'
)

