#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Security helpers for UCKK Ops Console.

.DESCRIPTION
  Centralizes danger levels, confirmation messages, safety checks,
  backup requirements, and secret masking.

  This module must not execute dangerous actions.
  It only classifies, validates, confirms, and protects output.
#>

$script:UckkDangerLevels = @{
    0 = "Navigation"
    1 = "Lecture / vérification"
    2 = "Modification locale simple"
    3 = "Git"
    4 = "Base Moodle locale"
    5 = "Serveur public"
    6 = "Base Moodle serveur"
    7 = "Récupération"
}

$script:UckkKnownStatuses = @(
    "Prêt",
    "En cours",
    "Réussi",
    "Réussi avec avertissements",
    "Échoué",
    "Annulé",
    "À vérifier dans le navigateur"
)

$script:UckkSecretNamePattern = "(?i)(password|passwd|token|secret|api[_-]?key|private[_-]?key|cookie|session|dbpass)"

function Get-UckkDangerLevelName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel
    )

    return $script:UckkDangerLevels[$DangerLevel]
}

function Get-UckkDangerLevelLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel
    )

    return "$DangerLevel — $($script:UckkDangerLevels[$DangerLevel])"
}

function Test-UckkDangerLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $DangerLevel
    )

    if ($null -eq $DangerLevel) {
        return $false
    }

    $level = 0

    if (-not [int]::TryParse([string] $DangerLevel, [ref] $level)) {
        return $false
    }

    return ($level -ge 0 -and $level -le 7)
}

function Get-UckkDefaultConfirmationMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $false)]
        [string] $Action = "",

        [Parameter(Mandatory = $false)]
        [string] $Target = "",

        [Parameter(Mandatory = $false)]
        [switch] $WouldModifyGit,

        [Parameter(Mandatory = $false)]
        [switch] $WouldModifyServer,

        [Parameter(Mandatory = $false)]
        [switch] $WouldWriteLocalDatabase,

        [Parameter(Mandatory = $false)]
        [switch] $WouldWriteServerDatabase,

        [Parameter(Mandatory = $false)]
        [switch] $RequiresBackup,

        [Parameter(Mandatory = $false)]
        [switch] $IsDestructive
    )

    if ($IsDestructive) {
        return "Cette action peut supprimer, remplacer ou reconstruire des données existantes.`nElle ne doit être lancée que si une sauvegarde existe.`nContinuer ?"
    }

    if ($DangerLevel -eq 7 -or $RequiresBackup) {
        return "Cette action est une récupération, pas une opération normale.`nElle peut modifier plusieurs données.`nUne sauvegarde doit exister avant de continuer.`nContinuer ?"
    }

    if ($WouldWriteServerDatabase -or $DangerLevel -eq 6) {
        if ($WouldModifyServer) {
            return "Cette action modifie uckk.org et écrit dans la base Moodle serveur. Continuer ?"
        }

        return "Cette action écrit dans la base Moodle serveur. Continuer ?"
    }

    if ($WouldModifyServer -or $DangerLevel -eq 5) {
        return "Cette action modifie uckk.org ou son code serveur. Continuer ?"
    }

    if ($WouldWriteLocalDatabase -or $DangerLevel -eq 4) {
        return "Cette action écrit dans la base Moodle locale. Continuer ?"
    }

    if ($WouldModifyGit -or $DangerLevel -eq 3) {
        return "Cette action enregistre ou envoie des changements dans l historique Git.`nVérifie qu aucun secret n est inclus.`nContinuer ?"
    }

    if ($DangerLevel -eq 2) {
        if (-not [string]::IsNullOrWhiteSpace($Target)) {
            return "Cette action modifie seulement le local : $Target. Continuer ?"
        }

        return "Cette action modifie seulement le local. Continuer ?"
    }

    if (-not [string]::IsNullOrWhiteSpace($Action)) {
        return "Lancer l action suivante : $Action ?"
    }

    return "Continuer ?"
}

function New-UckkConfirmationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Confirmed,

        [Parameter(Mandatory = $true)]
        [bool] $Cancelled,

        [Parameter(Mandatory = $true)]
        [bool] $Refused,

        [Parameter(Mandatory = $true)]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [string] $Summary,

        [Parameter(Mandatory = $true)]
        [string] $Reason,

        [Parameter(Mandatory = $false)]
        [string] $Message = ""
    )

    return [pscustomobject]@{
        confirmed = $Confirmed
        cancelled = $Cancelled
        refused   = $Refused
        status    = $Status
        summary   = $Summary
        reason    = $Reason
        message   = $Message
    }
}

function Confirm-UckkAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel,

        [Parameter(Mandatory = $false)]
        [string] $Target = "",

        [Parameter(Mandatory = $false)]
        [string] $Message = "",

        [Parameter(Mandatory = $false)]
        [switch] $RequiresConfirmation,

        [Parameter(Mandatory = $false)]
        [switch] $RequiresBackup,

        [Parameter(Mandatory = $false)]
        [switch] $BackupVerified,

        [Parameter(Mandatory = $false)]
        [switch] $WouldModifyGit,

        [Parameter(Mandatory = $false)]
        [switch] $WouldModifyServer,

        [Parameter(Mandatory = $false)]
        [switch] $WouldWriteLocalDatabase,

        [Parameter(Mandatory = $false)]
        [switch] $WouldWriteServerDatabase,

        [Parameter(Mandatory = $false)]
        [switch] $IsDestructive,

        [Parameter(Mandatory = $false)]
        [switch] $AssumeYes,

        [Parameter(Mandatory = $false)]
        [switch] $NonInteractive
    )

    $mustConfirm = (
        $RequiresConfirmation -or
        $RequiresBackup -or
        $IsDestructive -or
        $DangerLevel -ge 3 -or
        $WouldModifyGit -or
        $WouldModifyServer -or
        $WouldWriteLocalDatabase -or
        $WouldWriteServerDatabase
    )

    if (($RequiresBackup -or $IsDestructive -or $DangerLevel -eq 7) -and -not $BackupVerified) {
        return New-UckkConfirmationResult `
            -Confirmed $false `
            -Cancelled $false `
            -Refused $true `
            -Status "Échoué" `
            -Summary "Action refusée — aucune sauvegarde vérifiée." `
            -Reason "backup_required" `
            -Message "Une sauvegarde doit exister avant de continuer."
    }

    if (-not $mustConfirm) {
        return New-UckkConfirmationResult `
            -Confirmed $true `
            -Cancelled $false `
            -Refused $false `
            -Status "Réussi" `
            -Summary "Aucune confirmation requise." `
            -Reason "confirmation_not_required"
    }

    if ($AssumeYes) {
        return New-UckkConfirmationResult `
            -Confirmed $true `
            -Cancelled $false `
            -Refused $false `
            -Status "Réussi" `
            -Summary "Confirmation automatique acceptée." `
            -Reason "assume_yes"
    }

    if ($NonInteractive) {
        return New-UckkConfirmationResult `
            -Confirmed $false `
            -Cancelled $false `
            -Refused $true `
            -Status "Échoué" `
            -Summary "Action refusée — confirmation interactive impossible." `
            -Reason "non_interactive_confirmation_required" `
            -Message "Cette action exige une confirmation utilisateur."
    }

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = Get-UckkDefaultConfirmationMessage `
            -DangerLevel $DangerLevel `
            -Action $Action `
            -Target $Target `
            -WouldModifyGit:$WouldModifyGit `
            -WouldModifyServer:$WouldModifyServer `
            -WouldWriteLocalDatabase:$WouldWriteLocalDatabase `
            -WouldWriteServerDatabase:$WouldWriteServerDatabase `
            -RequiresBackup:$RequiresBackup `
            -IsDestructive:$IsDestructive
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "Confirmation requise"
    Write-Host "============================================================"
    Write-Host "Action : $Action"

    if (-not [string]::IsNullOrWhiteSpace($Target)) {
        Write-Host "Cible  : $Target"
    }

    Write-Host "Danger : $(Get-UckkDangerLevelLabel -DangerLevel $DangerLevel)"
    Write-Host ""
    Write-Host $Message
    Write-Host ""

    $answer = Read-Host "Répondre OUI pour continuer"

    if ($answer -ceq "OUI") {
        return New-UckkConfirmationResult `
            -Confirmed $true `
            -Cancelled $false `
            -Refused $false `
            -Status "Réussi" `
            -Summary "Confirmation utilisateur obtenue." `
            -Reason "confirmed" `
            -Message $Message
    }

    return New-UckkConfirmationResult `
        -Confirmed $false `
        -Cancelled $true `
        -Refused $false `
        -Status "Annulé" `
        -Summary "Annulé — aucune modification n a été faite." `
        -Reason "user_cancelled" `
        -Message $Message
}

function Get-UckkHashtableValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Hashtable,

        [Parameter(Mandatory = $true)]
[string] $Key,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Default = $null
    )

    if ($Hashtable.ContainsKey($Key)) {
        return $Hashtable[$Key]
    }

    return $Default
}

function Test-UckkActionSafety {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $ActionMetadata,

        [Parameter(Mandatory = $false)]
        [hashtable] $Config = @{}
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    foreach ($field in @("id", "label", "domain", "target", "dangerLevel", "mode", "handler")) {
        if (-not $ActionMetadata.ContainsKey($field) -or [string]::IsNullOrWhiteSpace([string] $ActionMetadata[$field])) {
            $errors.Add("Métadonnée manquante : $field")
        }
    }

    if ($ActionMetadata.ContainsKey("dangerLevel")) {
        if (-not (Test-UckkDangerLevel -DangerLevel $ActionMetadata["dangerLevel"])) {
            $errors.Add("Niveau de danger invalide : $($ActionMetadata["dangerLevel"])")
        }
    }

    $dangerLevel = 0

    if ($ActionMetadata.ContainsKey("dangerLevel")) {
        [void] [int]::TryParse([string] $ActionMetadata["dangerLevel"], [ref] $dangerLevel)
    }

    $requiresConfirmation = ($ActionMetadata.ContainsKey("requiresConfirmation") -and [bool] $ActionMetadata["requiresConfirmation"])
    $requiresBackup = ($ActionMetadata.ContainsKey("requiresBackup") -and [bool] $ActionMetadata["requiresBackup"])
    $requiresSimulation = ($ActionMetadata.ContainsKey("requiresSimulation") -and [bool] $ActionMetadata["requiresSimulation"])

    if ($dangerLevel -ge 3 -and -not $requiresConfirmation) {
        $errors.Add("Action sensible sans confirmation obligatoire.")
    }

    if ($dangerLevel -eq 7 -and -not $requiresBackup) {
        $errors.Add("Action de récupération sans sauvegarde obligatoire.")
    }

    if ($dangerLevel -eq 6 -and -not $requiresSimulation) {
        $warnings.Add("Action serveur/base Moodle serveur sans simulation déclarée.")
    }

    if ($ActionMetadata.ContainsKey("label")) {
        $label = [string] $ActionMetadata["label"]

        if ($label -match "^(Run|Go|Sync|Apply|Fix|Repair|Reset|Import|Export|Deploy|Clean)$") {
            $errors.Add("Libellé interdit ou trop vague : $label")
        }
    }

    if ($ActionMetadata.ContainsKey("target")) {
        $target = [string] $ActionMetadata["target"]

        if (($dangerLevel -ge 4) -and [string]::IsNullOrWhiteSpace($target)) {
            $errors.Add("Action sensible sans cible claire.")
        }
    }

    return [pscustomobject]@{
        ok       = ($errors.Count -eq 0)
        errors   = @($errors)
        warnings = @($warnings)
    }
}

function Mask-UckkSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $text = [string] $Value

    $patterns = @(
        "(?i)(password\s*[:=]\s*)\S+",
        "(?i)(passwd\s*[:=]\s*)\S+",
        "(?i)(token\s*[:=]\s*)\S+",
        "(?i)(secret\s*[:=]\s*)\S+",
        "(?i)(api[_-]?key\s*[:=]\s*)\S+",
        "(?i)(private[_-]?key\s*[:=]\s*)\S+",
        "(?i)(cookie\s*[:=]\s*)\S+",
        "(?i)(session\s*[:=]\s*)\S+",
        "(?i)(dbpass\s*[:=]\s*)\S+",
        "(?i)(ssh-rsa\s+)\S+",
        "(?is)(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)"
    )

    foreach ($pattern in $patterns) {
        $text = [regex]::Replace($text, $pattern, {
            param($match)

            if ($match.Groups.Count -ge 2) {
                return "$($match.Groups[1].Value)[masqué]"
            }

            return "[masqué]"
        })
    }

    return $text
}

function Mask-UckkSecretsInObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [string]) {
        return Mask-UckkSecret -Value $InputObject
    }

    if ($InputObject -is [hashtable]) {
        $copy = @{}

        foreach ($key in $InputObject.Keys) {
            $keyText = [string] $key

            if ($keyText -match $script:UckkSecretNamePattern) {
                $copy[$key] = "[masqué]"
            }
            else {
                $copy[$key] = Mask-UckkSecretsInObject -InputObject $InputObject[$key]
            }
        }

        return $copy
    }

    if ($InputObject -is [pscustomobject]) {
        $copy = [ordered] @{}

        foreach ($prop in $InputObject.PSObject.Properties) {
            if ($prop.Name -match $script:UckkSecretNamePattern) {
                $copy[$prop.Name] = "[masqué]"
            }
            else {
                $copy[$prop.Name] = Mask-UckkSecretsInObject -InputObject $prop.Value
            }
        }

        return [pscustomobject] $copy
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $items = @()

        foreach ($item in $InputObject) {
            $items += Mask-UckkSecretsInObject -InputObject $item
        }

        return $items
    }

    return $InputObject
}

function Test-UckkTextForSecretRisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string] $Text
    )

    $findings = [System.Collections.Generic.List[string]]::new()

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return [pscustomobject]@{
            hasRisk  = $false
            findings = @()
        }
    }

    $checks = [ordered] @{
        "mot de passe possible"   = "(?i)password|passwd|dbpass"
        "token possible"          = "(?i)token|bearer\s+[A-Za-z0-9._-]+"
        "clé API possible"        = "(?i)api[_-]?key"
        "secret possible"         = "(?i)secret"
        "clé privée possible"     = "(?i)BEGIN [A-Z ]*PRIVATE KEY"
        "cookie/session possible" = "(?i)cookie|session"
        "config.php possible"     = "(?i)config\.php"
        "dump SQL possible"       = "(?i)\.sql\b|dump"
        "fichier .env possible"   = "(?i)(^|[\\/])\.env\b"
    }

    foreach ($label in $checks.Keys) {
        if ($Text -match $checks[$label]) {
            $findings.Add($label)
        }
    }

    return [pscustomobject]@{
        hasRisk  = ($findings.Count -gt 0)
        findings = @($findings)
    }
}

function Test-UckkBackupRequirement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch] $RequiresBackup,

        [Parameter(Mandatory = $false)]
        [switch] $BackupVerified,

        [Parameter(Mandatory = $false)]
        [string] $BackupPath = ""
    )

    if (-not $RequiresBackup) {
        return [pscustomobject]@{
            ok      = $true
            message = "Sauvegarde non requise."
        }
    }

    if ($BackupVerified) {
        return [pscustomobject]@{
            ok      = $true
            message = "Sauvegarde vérifiée."
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($BackupPath) -and (Test-Path -LiteralPath $BackupPath)) {
        return [pscustomobject]@{
            ok      = $true
            message = "Sauvegarde trouvée : $BackupPath"
        }
    }

    return [pscustomobject]@{
        ok      = $false
        message = "Sauvegarde requise, mais aucune sauvegarde vérifiée."
    }
}

function New-UckkSecurityRefusal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [string] $Cause,

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "Vérifier le contrat de sécurité avant de relancer.",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 7)]
        [int] $DangerLevel = 1
    )

    return [pscustomobject]@{
        success     = $false
        status      = "Échoué"
        action      = $Action
        domain      = "security"
        target      = "aucune cible modifiée"
        dangerLevel = $DangerLevel
        mode        = "vérification"
        summary     = "Action refusée. Cause : $Cause"
        warnings    = @()
        errors      = @($Cause)
        nextStep    = $NextStep
        reportPath  = ""
        logPath     = ""
        data        = @{
            refusal = $true
        }
    }
}

Export-ModuleMember -Function @(
    "Get-UckkDangerLevelName",
    "Get-UckkDangerLevelLabel",
    "Test-UckkDangerLevel",
    "Get-UckkDefaultConfirmationMessage",
    "Confirm-UckkAction",
    "Test-UckkActionSafety",
    "Mask-UckkSecret",
    "Mask-UckkSecretsInObject",
    "Test-UckkTextForSecretRisk",
    "Test-UckkBackupRequirement",
    "New-UckkSecurityRefusal"
)

