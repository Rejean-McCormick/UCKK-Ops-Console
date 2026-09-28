Set-StrictMode -Off
# UCKK Ops Console

# Médiathèque main action module.

#

# Role:

# - Expose the official Médiathèque actions used by the interface.

# - Orchestrate manifest validation, simulation, apply, verification, confirmations, reports, and logs.

# - Keep the normal workflow strict:

# manifeste → simulation → appliquer → vérifier

#

# This module must not:

# - use public export as source of truth;

# - use media_original for external references;

# - perform SQL dump/copy-table workflows;

# - run legacy or recovery tools;

# - hide local/server target selection;

# - write to Moodle without confirmation.

function Assert-UckkMediathequeTarget {
param(
[Parameter(Mandatory = $true)]
[string] $Target
)

if ($Target -notin @("local", "server")) {
    throw "Cible Médiathèque invalide : $Target. Valeurs permises : local, server."
}

}

function Get-UckkMediathequeTargetLabel {
param(
[Parameter(Mandatory = $true)]
[string] $Target
)

Assert-UckkMediathequeTarget -Target $Target

if ($Target -eq "local") {
    return "Médiathèque locale"
}

return "Médiathèque serveur"

}

function Get-UckkMediathequeDatabaseTargetLabel {
param(
[Parameter(Mandatory = $true)]
[string] $Target
)

Assert-UckkMediathequeTarget -Target $Target

if ($Target -eq "local") {
    return "base Moodle locale"
}

return "base Moodle serveur"

}

function Get-UckkMediathequeDangerLevel {
param(
[Parameter(Mandatory = $true)]
[string] $Target,

    [Parameter(Mandatory = $true)]
    [ValidateSet("navigation", "verification", "simulation", "application")]
    [string] $Mode
)

Assert-UckkMediathequeTarget -Target $Target

if ($Mode -in @("navigation", "verification", "simulation")) {
    return 1
}

if ($Target -eq "local") {
    return 4
}

return 6

}

function Get-UckkMediathequeManifestPath {
param(
[Parameter(Mandatory = $true)]
[object] $Config
)

if ($null -eq $Config) {
    throw "Configuration absente."
}

if (
    ($Config.PSObject.Properties.Name -contains "mediatheque") -and
    ($null -ne $Config.mediatheque) -and
    ($Config.mediatheque.PSObject.Properties.Name -contains "manifestPath") -and
    (-not [string]::IsNullOrWhiteSpace([string] $Config.mediatheque.manifestPath))
) {
    return [string] $Config.mediatheque.manifestPath
}

if (
    ($Config.PSObject.Properties.Name -contains "paths") -and
    ($null -ne $Config.paths) -and
    ($Config.paths.PSObject.Properties.Name -contains "uckkMoodleSource") -and
    (-not [string]::IsNullOrWhiteSpace([string] $Config.paths.uckkMoodleSource))
) {
    return (Join-Path ([string] $Config.paths.uckkMoodleSource) "content/mediatheque/mediatheque.catalog.json")
}

throw "Chemin du manifeste Médiathèque introuvable dans la configuration."

}

function Get-UckkMediathequeUrl {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $true)]
    [string] $Target
)

Assert-UckkMediathequeTarget -Target $Target

if ($null -eq $Config -or -not ($Config.PSObject.Properties.Name -contains "urls")) {
    throw "Section urls absente de la configuration."
}

if ($Target -eq "local") {
    if ($Config.urls.PSObject.Properties.Name -contains "localMediatheque") {
        return [string] $Config.urls.localMediatheque
    }

    if ($Config.urls.PSObject.Properties.Name -contains "localBase") {
        return ([string] $Config.urls.localBase).TrimEnd("/") + "/local/uckk/mediatheque.php"
    }

    throw "URL Médiathèque locale absente de la configuration."
}

if ($Config.urls.PSObject.Properties.Name -contains "serverMediatheque") {
    return [string] $Config.urls.serverMediatheque
}

if ($Config.urls.PSObject.Properties.Name -contains "serverBase") {
    return ([string] $Config.urls.serverBase).TrimEnd("/") + "/local/uckk/mediatheque.php"
}

throw "URL Médiathèque serveur absente de la configuration."

}

function Get-UckkMediathequeTargetConfig {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $true)]
    [string] $Target
)

Assert-UckkMediathequeTarget -Target $Target

if ($null -eq $Config -or -not ($Config.PSObject.Properties.Name -contains "mediatheque")) {
    throw "Section mediatheque absente de la configuration."
}

$Prefix = if ($Target -eq "local") { "local" } else { "server" }

$RequiredFields = @(
    "${Prefix}ArchiveId",
    "${Prefix}CourseId",
    "${Prefix}CmId",
    "${Prefix}ContextId"
)

foreach ($Field in $RequiredFields) {
    if (-not ($Config.mediatheque.PSObject.Properties.Name -contains $Field)) {
        throw "Champ Médiathèque manquant dans la configuration : mediatheque.$Field"
    }
}

return [PSCustomObject]@{
    Target    = $Target
    ArchiveId = $Config.mediatheque."${Prefix}ArchiveId"
    CourseId  = $Config.mediatheque."${Prefix}CourseId"
    CmId      = $Config.mediatheque."${Prefix}CmId"
    ContextId = $Config.mediatheque."${Prefix}ContextId"
}

}

function New-UckkMediathequeActionResult {
param(
[Parameter(Mandatory = $true)]
[bool] $Success,

    [Parameter(Mandatory = $true)]
    [string] $Status,

    [Parameter(Mandatory = $true)]
    [string] $Action,

    [Parameter(Mandatory = $false)]
    [string] $Target = "",

    [Parameter(Mandatory = $false)]
    [int] $DangerLevel = 1,

    [Parameter(Mandatory = $false)]
    [string] $Mode = "vérification",

    [Parameter(Mandatory = $false)]
    [string] $Summary = "",

    [Parameter(Mandatory = $false)]
    [string[]] $Warnings = @(),

    [Parameter(Mandatory = $false)]
    [string[]] $Errors = @(),

    [Parameter(Mandatory = $false)]
    [string] $NextStep = "",

    [Parameter(Mandatory = $false)]
    [string] $ReportPath = "",

    [Parameter(Mandatory = $false)]
    [string] $LogPath = "",

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [object] $Data = $null
)

return [PSCustomObject]@{
    success     = $Success
    status      = $Status
    action      = $Action
    domain      = "mediatheque"
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

function Write-UckkMediathequeFallbackReport {
param(
[Parameter(Mandatory = $true)]
[object] $Result,

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

$ReportsDir = "./reports"

if ($null -ne $Config) {
    if (
        ($Config.PSObject.Properties.Name -contains "reports") -and
        ($null -ne $Config.reports) -and
        ($Config.reports.PSObject.Properties.Name -contains "dir") -and
        (-not [string]::IsNullOrWhiteSpace([string] $Config.reports.dir))
    ) {
        $ReportsDir = [string] $Config.reports.dir
    }
    elseif (
        ($Config.PSObject.Properties.Name -contains "paths") -and
        ($null -ne $Config.paths) -and
        ($Config.paths.PSObject.Properties.Name -contains "reportsDir") -and
        (-not [string]::IsNullOrWhiteSpace([string] $Config.paths.reportsDir))
    ) {
        $ReportsDir = [string] $Config.paths.reportsDir
    }

    if ([string]::IsNullOrWhiteSpace($AppRoot)) {
        if (
            ($Config.PSObject.Properties.Name -contains "app") -and
            ($null -ne $Config.app) -and
            ($Config.app.PSObject.Properties.Name -contains "root")
        ) {
            $AppRoot = [string] $Config.app.root
        }
    }
}

if ([string]::IsNullOrWhiteSpace($AppRoot)) {
    $AppRoot = (Get-Location).Path
}

if (-not [System.IO.Path]::IsPathRooted($ReportsDir)) {
    $ReportsDir = Join-Path $AppRoot $ReportsDir
}

if (-not (Test-Path -LiteralPath $ReportsDir -PathType Container)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

$Timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$ActionSlug = ([string] $Result.action).ToLowerInvariant() -replace "[^a-z0-9]+", "_"
$ActionSlug = $ActionSlug.Trim("_")

if ([string]::IsNullOrWhiteSpace($ActionSlug)) {
    $ActionSlug = "mediatheque"
}

$ReportPath = Join-Path $ReportsDir "${Timestamp}_mediatheque_${ActionSlug}.md"

$WarningsText = if ($Result.warnings.Count -gt 0) {
    ($Result.warnings | ForEach-Object { "- $_" }) -join [Environment]::NewLine
}
else {
    "Aucun."
}

$ErrorsText = if ($Result.errors.Count -gt 0) {
    ($Result.errors | ForEach-Object { "- $_" }) -join [Environment]::NewLine
}
else {
    "Aucune."
}

$DataText = "Non applicable."

if ($null -ne $Result.data) {
    try {
        $DataText = $Result.data | ConvertTo-Json -Depth 12
    }
    catch {
        $DataText = [string] $Result.data
    }
}

$Content = @"

# Rapport — $($Result.action)

## Résumé

Statut : $($Result.status)

$($Result.summary)

## Action demandée

$($Result.action)

## Cible

$($Result.target)

## Niveau de danger

$($Result.dangerLevel)

## Mode

$($Result.mode)

## Source utilisée

Voir les données techniques ci-dessous.

## Étapes exécutées

Non détaillé dans ce rapport minimal.

## Changements

Voir les données techniques ci-dessous.

## Avertissements

$WarningsText

## Erreurs

$ErrorsText

## Résultat final

$($Result.status)

## Prochaine étape

$($Result.nextStep)

## Détail technique

Log : $($Result.logPath)

```json
$DataText

"@

Set-Content -LiteralPath $ReportPath -Value $Content -Encoding UTF8

return $ReportPath

}

function Complete-UckkMediathequeAction {
param(
[Parameter(Mandatory = $true)]
[object] $Result,

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = "",

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [object] $LogContext = $null
)

if ([string]::IsNullOrWhiteSpace($Result.reportPath)) {
    $ReportPath = ""

    if (Get-Command -Name Write-UckkReport -ErrorAction SilentlyContinue) {
        try {
            $ReportPath = Write-UckkReport -Result $Result -Config $Config -AppRoot $AppRoot
        }
        catch {
            $ReportPath = Write-UckkMediathequeFallbackReport -Result $Result -Config $Config -AppRoot $AppRoot
        }
    }
    else {
        $ReportPath = Write-UckkMediathequeFallbackReport -Result $Result -Config $Config -AppRoot $AppRoot
    }

    $Result.reportPath = $ReportPath
}

if ($null -ne $LogContext -and (Get-Command -Name Complete-UckkLog -ErrorAction SilentlyContinue)) {
    Complete-UckkLog -Context $LogContext -Status $Result.status -Summary $Result.summary
}

return $Result

}

function Start-UckkMediathequeLog {
param(
[Parameter(Mandatory = $true)]
[string] $Action,

    [Parameter(Mandatory = $true)]
    [string] $Target,

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

if (Get-Command -Name New-UckkLogContext -ErrorAction SilentlyContinue) {
    return New-UckkLogContext `
        -Action $Action `
        -Domain "mediatheque" `
        -Target $Target `
        -Config $Config `
        -AppRoot $AppRoot
}

return $null

}

function Add-UckkMediathequeLog {
param(
[Parameter(Mandatory = $false)]
[AllowNull()]
[object] $Context,

    [Parameter(Mandatory = $true)]
    [string] $Message,

    [Parameter(Mandatory = $false)]
    [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
    [string] $Level = "INFO",

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [object] $Data = $null
)

if ($null -ne $Context -and (Get-Command -Name Add-UckkLogEntry -ErrorAction SilentlyContinue)) {
    Add-UckkLogEntry -Context $Context -Message $Message -Level $Level -Data $Data
}

}

function Confirm-UckkMediathequeApply {
param(
[Parameter(Mandatory = $true)]
[string] $Target,

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [object] $Config = $null
)

Assert-UckkMediathequeTarget -Target $Target

$Message = if ($Target -eq "local") {
    "Cette action écrit dans la base Moodle locale. Continuer ?"
}
else {
    "Cette action écrit dans la base Moodle serveur. Continuer ?"
}

if (Get-Command -Name Confirm-UckkAction -ErrorAction SilentlyContinue) {
    return Confirm-UckkAction `
        -Action "Appliquer Médiathèque" `
        -Target (Get-UckkMediathequeDatabaseTargetLabel -Target $Target) `
        -DangerLevel (Get-UckkMediathequeDangerLevel -Target $Target -Mode "application") `
        -Message $Message `
        -WouldWriteDatabase $true `
        -WouldModifyServer ($Target -eq "server")
}

$Choice = Read-Host "$Message [oui/non]"
return ($Choice -in @("oui", "o", "yes", "y"))

}

function Open-UckkMediathequeManifest {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

$Action = "Ouvrir manifeste Médiathèque"
$LogContext = Start-UckkMediathequeLog -Action $Action -Target "local" -Config $Config -AppRoot $AppRoot

try {
    $ManifestPath = Get-UckkMediathequeManifestPath -Config $Config

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Manifeste Médiathèque introuvable : $ManifestPath"
    }

    if (Get-Command -Name Open-UckkPath -ErrorAction SilentlyContinue) {
        Open-UckkPath -Path $ManifestPath | Out-Null
    }
    else {
        Invoke-Item -LiteralPath $ManifestPath
    }

    $Result = New-UckkMediathequeActionResult `
        -Success $true `
        -Status "Réussi" `
        -Action $Action `
        -Target "Manifeste Médiathèque" `
        -DangerLevel 0 `
        -Mode "navigation" `
        -Summary "Le manifeste Médiathèque a été ouvert." `
        -NextStep "Modifier le manifeste si nécessaire, puis lancer “Vérifier manifeste Médiathèque”." `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" }) `
        -Data ([PSCustomObject]@{ manifestPath = $ManifestPath })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}
catch {
    Add-UckkMediathequeLog -Context $LogContext -Message $_.Exception.Message -Level "ERROR"

    $Result = New-UckkMediathequeActionResult `
        -Success $false `
        -Status "Échoué" `
        -Action $Action `
        -Target "Manifeste Médiathèque" `
        -DangerLevel 0 `
        -Mode "navigation" `
        -Summary "L’action a échoué. Cause probable : le manifeste Médiathèque est introuvable ou impossible à ouvrir." `
        -Errors @($_.Exception.Message) `
        -NextStep "Vérifier mediatheque.manifestPath dans la configuration." `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}

}

function Test-UckkMediathequeManifestAction {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

$Action = "Vérifier manifeste Médiathèque"
$LogContext = Start-UckkMediathequeLog -Action $Action -Target "Manifeste Médiathèque" -Config $Config -AppRoot $AppRoot

try {
    $ManifestPath = Get-UckkMediathequeManifestPath -Config $Config

    if (-not (Get-Command -Name Test-UckkMediathequeManifest -ErrorAction SilentlyContinue)) {
        throw "Fonction manquante : Test-UckkMediathequeManifest"
    }

    $Validation = Test-UckkMediathequeManifest -ManifestPath $ManifestPath -Config $Config

    $Errors = @()
    $Warnings = @()

    if ($Validation.PSObject.Properties.Name -contains "errors") {
        $Errors = @($Validation.errors)
    }

    if ($Validation.PSObject.Properties.Name -contains "warnings") {
        $Warnings = @($Validation.warnings)
    }

    $Success = ($Errors.Count -eq 0)
    $Status = if ($Success -and $Warnings.Count -gt 0) { "Réussi avec avertissements" } elseif ($Success) { "Réussi" } else { "Échoué" }
    $Summary = if ($Success) {
        "Le manifeste Médiathèque est valide."
    }
    else {
        "Le manifeste Médiathèque contient des erreurs."
    }

    $Result = New-UckkMediathequeActionResult `
        -Success $Success `
        -Status $Status `
        -Action $Action `
        -Target "Manifeste Médiathèque" `
        -DangerLevel 1 `
        -Mode "vérification" `
        -Summary $Summary `
        -Warnings $Warnings `
        -Errors $Errors `
        -NextStep $(if ($Success) { "Lancer une simulation Médiathèque locale ou serveur." } else { "Corriger le manifeste, puis relancer la vérification." }) `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" }) `
        -Data $Validation

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}
catch {
    Add-UckkMediathequeLog -Context $LogContext -Message $_.Exception.Message -Level "ERROR"

    $Result = New-UckkMediathequeActionResult `
        -Success $false `
        -Status "Échoué" `
        -Action $Action `
        -Target "Manifeste Médiathèque" `
        -DangerLevel 1 `
        -Mode "vérification" `
        -Summary "L’action a échoué. Cause probable : le manifeste est introuvable, invalide ou le module de validation est absent." `
        -Errors @($_.Exception.Message) `
        -NextStep "Vérifier le manifeste et le module UckkOps.Mediatheque.Manifest.psm1." `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}
}

function Invoke-UckkMediathequeSimulation {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $true)]
    [ValidateSet("local", "server")]
    [string] $Target,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

Assert-UckkMediathequeTarget -Target $Target

$TargetLabel = Get-UckkMediathequeTargetLabel -Target $Target
$Action = if ($Target -eq "local") { "Simulation Médiathèque locale" } else { "Simulation Médiathèque serveur" }
$LogContext = Start-UckkMediathequeLog -Action $Action -Target $TargetLabel -Config $Config -AppRoot $AppRoot

try {
    $ManifestPath = Get-UckkMediathequeManifestPath -Config $Config
    $TargetConfig = Get-UckkMediathequeTargetConfig -Config $Config -Target $Target

    if (-not (Get-Command -Name Test-UckkMediathequeManifest -ErrorAction SilentlyContinue)) {
        throw "Fonction manquante : Test-UckkMediathequeManifest"
    }

    if (-not (Get-Command -Name Invoke-UckkMediathequeMoodleSimulation -ErrorAction SilentlyContinue)) {
        throw "Fonction manquante : Invoke-UckkMediathequeMoodleSimulation"
    }

    $Validation = Test-UckkMediathequeManifest -ManifestPath $ManifestPath -Config $Config

    if (($Validation.PSObject.Properties.Name -contains "errors") -and (@($Validation.errors).Count -gt 0)) {
        throw "Le manifeste Médiathèque contient des erreurs. Simulation refusée."
    }

    $Simulation = Invoke-UckkMediathequeMoodleSimulation `
        -Config $Config `
        -Target $Target `
        -ManifestPath $ManifestPath `
        -TimeoutSeconds 180

    $Warnings = @()
    $Errors = @()

    if ($Simulation.PSObject.Properties.Name -contains "warnings") {
        $Warnings = @($Simulation.warnings)
    }

    if ($Simulation.PSObject.Properties.Name -contains "errors") {
        $Errors = @($Simulation.errors)
    }

    $Success = ($Errors.Count -eq 0)
    $Status = if ($Success -and $Warnings.Count -gt 0) { "Réussi avec avertissements" } elseif ($Success) { "Réussi" } else { "Échoué" }

    $Summary = if ($Success) {
        "Simulation terminée. Aucune donnée Moodle n’a été modifiée."
    }
    else {
        "La simulation Médiathèque a échoué. Aucune donnée Moodle n’a été modifiée."
    }

    $Result = New-UckkMediathequeActionResult `
        -Success $Success `
        -Status $Status `
        -Action $Action `
        -Target (Get-UckkMediathequeDatabaseTargetLabel -Target $Target) `
        -DangerLevel (Get-UckkMediathequeDangerLevel -Target $Target -Mode "simulation") `
        -Mode "simulation" `
        -Summary $Summary `
        -Warnings $Warnings `
        -Errors $Errors `
        -NextStep $(if ($Success) { "Lire le rapport, puis appliquer seulement si tout est correct." } else { "Corriger les erreurs, puis relancer la simulation." }) `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" }) `
        -Data ([PSCustomObject]@{
            manifestPath = $ManifestPath
            validation   = $Validation
            simulation   = $Simulation
            targetConfig = $TargetConfig
        })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}
catch {
    Add-UckkMediathequeLog -Context $LogContext -Message $_.Exception.Message -Level "ERROR"

    $Result = New-UckkMediathequeActionResult `
        -Success $false `
        -Status "Échoué" `
        -Action $Action `
        -Target (Get-UckkMediathequeDatabaseTargetLabel -Target $Target) `
        -DangerLevel (Get-UckkMediathequeDangerLevel -Target $Target -Mode "simulation") `
        -Mode "simulation" `
        -Summary "L’action a échoué. Aucune donnée Moodle n’a été modifiée." `
        -Errors @($_.Exception.Message) `
        -NextStep "Corriger la cause indiquée, puis relancer la simulation." `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}

}

function Invoke-UckkMediathequeApply {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $true)]
    [ValidateSet("local", "server")]
    [string] $Target,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

Assert-UckkMediathequeTarget -Target $Target

$TargetLabel = Get-UckkMediathequeTargetLabel -Target $Target
$Action = if ($Target -eq "local") { "Appliquer Médiathèque localement" } else { "Appliquer Médiathèque serveur" }
$LogContext = Start-UckkMediathequeLog -Action $Action -Target $TargetLabel -Config $Config -AppRoot $AppRoot

try {
    $Confirmed = Confirm-UckkMediathequeApply -Target $Target -Config $Config

    if (-not $Confirmed) {
        $Result = New-UckkMediathequeActionResult `
            -Success $false `
            -Status "Annulé" `
            -Action $Action `
            -Target (Get-UckkMediathequeDatabaseTargetLabel -Target $Target) `
            -DangerLevel (Get-UckkMediathequeDangerLevel -Target $Target -Mode "application") `
            -Mode "annulation" `
            -Summary "Annulé — aucune modification n’a été faite." `
            -NextStep "Aucune action requise." `
            -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" })

        return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
    }

    $ManifestPath = Get-UckkMediathequeManifestPath -Config $Config
    $TargetConfig = Get-UckkMediathequeTargetConfig -Config $Config -Target $Target

    if (-not (Get-Command -Name Test-UckkMediathequeManifest -ErrorAction SilentlyContinue)) {
        throw "Fonction manquante : Test-UckkMediathequeManifest"
    }

    if (-not (Get-Command -Name Invoke-UckkMediathequeMoodleApply -ErrorAction SilentlyContinue)) {
        throw "Fonction manquante : Invoke-UckkMediathequeMoodleApply"
    }

    $Validation = Test-UckkMediathequeManifest -ManifestPath $ManifestPath -Config $Config

    if (($Validation.PSObject.Properties.Name -contains "errors") -and (@($Validation.errors).Count -gt 0)) {
        throw "Le manifeste Médiathèque contient des erreurs. Application refusée."
    }

    $ApplyResult = Invoke-UckkMediathequeMoodleApply `
        -Config $Config `
        -Target $Target `
        -ManifestPath $ManifestPath `
        -TimeoutSeconds 300

    $Warnings = @()
    $Errors = @()

    if ($ApplyResult.PSObject.Properties.Name -contains "warnings") {
        $Warnings = @($ApplyResult.warnings)
    }

    if ($ApplyResult.PSObject.Properties.Name -contains "errors") {
        $Errors = @($ApplyResult.errors)
    }

    $Success = ($Errors.Count -eq 0)
    $Status = if ($Success -and $Warnings.Count -gt 0) { "Réussi avec avertissements" } elseif ($Success) { "Réussi" } else { "Échoué" }

    $Summary = if ($Success) {
        "Médiathèque appliquée. Des données Moodle ont été modifiées."
    }
    else {
        "L’application Médiathèque a échoué ou n’a pas été complétée."
    }

    $NextStep = if ($Success) {
        if ($Target -eq "server") {
            "Vérifier la Médiathèque serveur dans le navigateur."
        }
        else {
            "Vérifier la Médiathèque locale dans le navigateur."
        }
    }
    else {
        "Lire le rapport, corriger les erreurs, puis relancer une simulation."
    }

    $Result = New-UckkMediathequeActionResult `
        -Success $Success `
        -Status $Status `
        -Action $Action `
        -Target (Get-UckkMediathequeDatabaseTargetLabel -Target $Target) `
        -DangerLevel (Get-UckkMediathequeDangerLevel -Target $Target -Mode "application") `
        -Mode "application" `
        -Summary $Summary `
        -Warnings $Warnings `
        -Errors $Errors `
        -NextStep $NextStep `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" }) `
        -Data ([PSCustomObject]@{
            manifestPath = $ManifestPath
            validation   = $Validation
            apply        = $ApplyResult
            targetConfig = $TargetConfig
        })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}
catch {
    Add-UckkMediathequeLog -Context $LogContext -Message $_.Exception.Message -Level "ERROR"

    $Result = New-UckkMediathequeActionResult `
        -Success $false `
        -Status "Échoué" `
        -Action $Action `
        -Target (Get-UckkMediathequeDatabaseTargetLabel -Target $Target) `
        -DangerLevel (Get-UckkMediathequeDangerLevel -Target $Target -Mode "application") `
        -Mode "application" `
        -Summary "L’action a échoué. Cause probable : validation, configuration ou écriture Moodle impossible." `
        -Errors @($_.Exception.Message) `
        -NextStep "Lire le rapport, corriger la cause, puis relancer une simulation avant d’appliquer." `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}

}

function Test-UckkMediathequeTarget {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $true)]
    [ValidateSet("local", "server")]
    [string] $Target,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

Assert-UckkMediathequeTarget -Target $Target

$TargetLabel = Get-UckkMediathequeTargetLabel -Target $Target
$Action = if ($Target -eq "local") { "Vérifier Médiathèque locale" } else { "Vérifier Médiathèque serveur" }
$LogContext = Start-UckkMediathequeLog -Action $Action -Target $TargetLabel -Config $Config -AppRoot $AppRoot

try {
    $Url = Get-UckkMediathequeUrl -Config $Config -Target $Target
    $TargetConfig = Get-UckkMediathequeTargetConfig -Config $Config -Target $Target

    if (-not (Get-Command -Name Invoke-UckkMediathequeMoodleVerify -ErrorAction SilentlyContinue)) {
        throw "Fonction manquante : Invoke-UckkMediathequeMoodleVerify"
    }

    $Verification = Invoke-UckkMediathequeMoodleVerify `
        -Config $Config `
        -Target $Target `
        -TimeoutSeconds 120
    # Url and TargetConfig are kept in report data.

    $Warnings = @()
    $Errors = @()

    if ($Verification.PSObject.Properties.Name -contains "warnings") {
        $Warnings = @($Verification.warnings)
    }

    if ($Verification.PSObject.Properties.Name -contains "errors") {
        $Errors = @($Verification.errors)
    }

    $Success = ($Errors.Count -eq 0)
    $Status = if ($Success -and $Warnings.Count -gt 0) { "Réussi avec avertissements" } elseif ($Success) { "Réussi" } else { "Échoué" }

    $NextStep = if ($Success) {
        "Ouvrir la Médiathèque dans le navigateur pour vérifier l’affichage."
    }
    else {
        "Lire le rapport et corriger la cause de l’échec."
    }

    $Result = New-UckkMediathequeActionResult `
        -Success $Success `
        -Status $Status `
        -Action $Action `
        -Target $TargetLabel `
        -DangerLevel 1 `
        -Mode "vérification" `
        -Summary $(if ($Success) { "La vérification Médiathèque est terminée." } else { "La vérification Médiathèque a échoué." }) `
        -Warnings $Warnings `
        -Errors $Errors `
        -NextStep $NextStep `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" }) `
        -Data ([PSCustomObject]@{
            url          = $Url
            targetConfig = $TargetConfig
            verification = $Verification
        })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}
catch {
    Add-UckkMediathequeLog -Context $LogContext -Message $_.Exception.Message -Level "ERROR"

    $Result = New-UckkMediathequeActionResult `
        -Success $false `
        -Status "Échoué" `
        -Action $Action `
        -Target $TargetLabel `
        -DangerLevel 1 `
        -Mode "vérification" `
        -Summary "L’action a échoué. Cause probable : URL, configuration ou service Médiathèque indisponible." `
        -Errors @($_.Exception.Message) `
        -NextStep "Vérifier la configuration et l’état de Moodle, puis relancer la vérification." `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}

}

function Open-UckkMediathequePage {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $true)]
    [ValidateSet("local", "server")]
    [string] $Target,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

Assert-UckkMediathequeTarget -Target $Target
$TargetLabel = Get-UckkMediathequeTargetLabel -Target $Target
$Action = if ($Target -eq "local") { "Ouvrir Médiathèque locale" } else { "Ouvrir Médiathèque serveur" }
$LogContext = Start-UckkMediathequeLog -Action $Action -Target $TargetLabel -Config $Config -AppRoot $AppRoot

try {
    $Url = Get-UckkMediathequeUrl -Config $Config -Target $Target

    if (Get-Command -Name Open-UckkUrl -ErrorAction SilentlyContinue) {
        Open-UckkUrl -Url $Url | Out-Null
    }
    else {
        Start-Process $Url
    }

    $Result = New-UckkMediathequeActionResult `
        -Success $true `
        -Status "Réussi" `
        -Action $Action `
        -Target $TargetLabel `
        -DangerLevel 0 `
        -Mode "navigation" `
        -Summary "La page Médiathèque a été ouverte dans le navigateur." `
        -NextStep "Vérifier visuellement que les cartes Médiathèque se chargent." `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" }) `
        -Data ([PSCustomObject]@{ url = $Url })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}
catch {
    Add-UckkMediathequeLog -Context $LogContext -Message $_.Exception.Message -Level "ERROR"

    $Result = New-UckkMediathequeActionResult `
        -Success $false `
        -Status "Échoué" `
        -Action $Action `
        -Target $TargetLabel `
        -DangerLevel 0 `
        -Mode "navigation" `
        -Summary "L’action a échoué. Cause probable : URL Médiathèque absente ou impossible à ouvrir." `
        -Errors @($_.Exception.Message) `
        -NextStep "Vérifier la section urls de la configuration." `
        -LogPath $(if ($null -ne $LogContext) { $LogContext.LogPath } else { "" })

    return Complete-UckkMediathequeAction -Result $Result -Config $Config -AppRoot $AppRoot -LogContext $LogContext
}

}

function Invoke-UckkMediathequeSimulationLocal {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

return Invoke-UckkMediathequeSimulation -Config $Config -Target "local" -AppRoot $AppRoot

}

function Invoke-UckkMediathequeSimulationServer {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

return Invoke-UckkMediathequeSimulation -Config $Config -Target "server" -AppRoot $AppRoot

}

function Invoke-UckkMediathequeApplyLocal {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

return Invoke-UckkMediathequeApply -Config $Config -Target "local" -AppRoot $AppRoot

}

function Invoke-UckkMediathequeApplyServer {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

return Invoke-UckkMediathequeApply -Config $Config -Target "server" -AppRoot $AppRoot

}

function Test-UckkMediathequeLocal {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

return Test-UckkMediathequeTarget -Config $Config -Target "local" -AppRoot $AppRoot

}

function Test-UckkMediathequeServer {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

return Test-UckkMediathequeTarget -Config $Config -Target "server" -AppRoot $AppRoot

}

function Open-UckkMediathequeLocal {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

return Open-UckkMediathequePage -Config $Config -Target "local" -AppRoot $AppRoot

}

function Open-UckkMediathequeServer {
param(
[Parameter(Mandatory = $true)]
[object] $Config,

    [Parameter(Mandatory = $false)]
    [string] $AppRoot = ""
)

return Open-UckkMediathequePage -Config $Config -Target "server" -AppRoot $AppRoot

}

Export-ModuleMember -Function @(
"Open-UckkMediathequeManifest",
"Test-UckkMediathequeManifestAction",
"Invoke-UckkMediathequeSimulation",
"Invoke-UckkMediathequeSimulationLocal",
"Invoke-UckkMediathequeSimulationServer",
"Invoke-UckkMediathequeApply",
"Invoke-UckkMediathequeApplyLocal",
"Invoke-UckkMediathequeApplyServer",
"Test-UckkMediathequeTarget",
"Test-UckkMediathequeLocal",
"Test-UckkMediathequeServer",
"Open-UckkMediathequePage",
"Open-UckkMediathequeLocal",
"Open-UckkMediathequeServer",
"Get-UckkMediathequeManifestPath",
"Get-UckkMediathequeUrl",
"Get-UckkMediathequeTargetConfig"
)

