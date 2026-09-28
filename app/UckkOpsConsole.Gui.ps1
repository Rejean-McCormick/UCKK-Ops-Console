#Requires -Version 7.0
<#
.SYNOPSIS
  UCKK Ops Console GUI.

.DESCRIPTION
  Interface graphique locale pour piloter les opérations UCKK :
  Local, Git, Serveur, Médiathèque, Données Moodle, Tests, Historique et Récupération.

  Ce fichier doit rester une interface mince :
  - il charge la configuration ;
  - il affiche les onglets ;
  - il affiche les actions ;
  - il demande les confirmations ;
  - il appelle les handlers déclarés ;
  - il affiche les résultats.

  La logique métier doit rester dans lib/ et modules/.
#>

[CmdletBinding()]
param(
    [string]$ConfigPath
)

Set-StrictMode -Off
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:GuiRoot = Split-Path -Parent $PSCommandPath
$script:AppRoot = Split-Path -Parent $script:GuiRoot

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $script:AppRoot 'config/uckk-ops-console.config.json'
}

$script:ConfigPath = $ConfigPath
$script:Config = $null
$script:LastResult = $null
$script:LastReportPath = $null
$script:LastLogPath = $null
$script:LoadMessages = New-Object System.Collections.Generic.List[string]

function Add-UckkGuiLoadMessage {
    param([string]$Message)

    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        [void]$script:LoadMessages.Add($Message)
    }
}

function Import-UckkGuiOptionalScript {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        try {
            . $Path
            Add-UckkGuiLoadMessage "Chargé : $Path"
        }
        catch {
            Add-UckkGuiLoadMessage "Erreur de chargement script : $Path — $($_.Exception.Message)"
        }
    }
}

function Import-UckkGuiOptionalModule {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        try {
            Import-Module $Path -Force -DisableNameChecking -ErrorAction Stop
            Add-UckkGuiLoadMessage "Module chargé : $Path"
        }
        catch {
            Add-UckkGuiLoadMessage "Erreur de chargement module : $Path — $($_.Exception.Message)"
        }
    }
}

function Get-UckkGuiPath {
    param([string]$RelativePath)

    return Join-Path $script:AppRoot $RelativePath
}

function Resolve-UckkGuiPathFromConfig {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($Value)) {
        return $Value
    }

    return Join-Path $script:AppRoot $Value
}

function Get-UckkGuiConfigValue {
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [Parameter(Mandatory)]
        [string]$Path,

        [object]$Default = $null
    )

    $current = $Config

    foreach ($part in $Path -split '\.') {
        if ($null -eq $current) {
            return $Default
        }

        $property = $current.PSObject.Properties[$part]

        if ($null -eq $property) {
            return $Default
        }

        $current = $property.Value
    }

    if ($null -eq $current) {
        return $Default
    }

    return $current
}

function Read-UckkGuiConfig {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Configuration introuvable : $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Configuration vide : $Path"
    }

    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Configuration JSON invalide : $($_.Exception.Message)"
    }
}

function New-UckkGuiActionResult {
    param(
        [bool]$Success,
        [string]$Status,
        [string]$Action,
        [string]$Domain,
        [string]$Target,
        [int]$DangerLevel,
        [string]$Mode,
        [string]$Summary,
        [string[]]$Warnings = @(),
        [string[]]$Errors = @(),
        [string]$NextStep = 'Aucune action requise.',
        [string]$ReportPath = $null,
        [string]$LogPath = $null,
        [hashtable]$Data = @{}
    )

    return [pscustomobject]@{
        success     = $Success
        status      = $Status
        action      = $Action
        domain      = $Domain
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

function Get-UckkGuiResultPropertyValue {
    param(
        [object]$Object,
        [string]$Name,
        [object]$Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    $property = $Object.PSObject.Properties[$Name]

    if ($null -eq $property) {
        return $Default
    }

    if ($null -eq $property.Value) {
        return $Default
    }

    return $property.Value
}

function Get-UckkGuiResultListValue {
    param(
        [object]$Object,
        [string]$Name
    )

    $value = Get-UckkGuiResultPropertyValue -Object $Object -Name $Name -Default @()

    if ($null -eq $value) {
        return @()
    }

    if ($value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($value)) {
            return @()
        }

        return @($value)
    }

    return @($value)
}

function Get-UckkGuiValueCount {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value
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

    try {
        if ($Value -is [System.Collections.IDictionary]) {
            return @($Value.Keys).Count
        }

        if ($Value -is [System.Collections.IEnumerable]) {
            $count = 0

            foreach ($item in $Value) {
                $count++
            }

            return $count
        }
    }
    catch {
        Add-UckkGuiLoadMessage ("Comptage GUI ignoré : " + $_.Exception.Message)
        return 1
    }

    return 1
}

function Convert-UckkGuiBoundedText {
    param(
        [AllowNull()][object]$Value,
        [int]$MaxChars = 0
    )

    if ($null -eq $Value) {
        return ''
    }

    if ($MaxChars -le 0) {
        $MaxChars = [int](Get-UckkGuiConfigValue -Config $script:Config -Path 'ui.maxCommandOutputChars' -Default 20000)
    }

    if ($MaxChars -lt 1000) {
        $MaxChars = 1000
    }

    $text = [string]$Value
    if ($text.Length -le $MaxChars) {
        return $text
    }

    return $text.Substring(0, $MaxChars) + [Environment]::NewLine + "... [sortie tronquée dans l'UI après $MaxChars caractères; le rapport/log conserve les données structurées]"
}

function Add-UckkGuiProcessLines {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [AllowNull()][object]$Process,
        [string]$Heading = 'Commande'
    )

    if ($null -eq $Process) {
        return
    }

    $commandLine = Get-UckkGuiResultPropertyValue -Object $Process -Name 'commandLine' -Default ''
    $workingDir = Get-UckkGuiResultPropertyValue -Object $Process -Name 'workingDir' -Default ''
    $exitCode = Get-UckkGuiResultPropertyValue -Object $Process -Name 'exitCode' -Default 'non disponible'
    $timedOut = Get-UckkGuiResultPropertyValue -Object $Process -Name 'timedOut' -Default $false
    $durationSeconds = Get-UckkGuiResultPropertyValue -Object $Process -Name 'durationSeconds' -Default ''
    $stdout = Get-UckkGuiResultPropertyValue -Object $Process -Name 'stdout' -Default ''
    $stderr = Get-UckkGuiResultPropertyValue -Object $Process -Name 'stderr' -Default ''

    [void]$Lines.Add('')
    [void]$Lines.Add("$Heading :")
    [void]$Lines.Add("  Commande : $commandLine")
    [void]$Lines.Add("  Dossier courant : $workingDir")
    [void]$Lines.Add("  Code de sortie : $exitCode")
    [void]$Lines.Add("  Timeout : $timedOut")
    if (-not [string]::IsNullOrWhiteSpace([string]$durationSeconds)) {
        [void]$Lines.Add("  Durée : $durationSeconds s")
    }

    [void]$Lines.Add('  STDOUT :')
    $stdoutText = Convert-UckkGuiBoundedText -Value $stdout
    if ([string]::IsNullOrWhiteSpace($stdoutText)) {
        [void]$Lines.Add('    (vide)')
    }
    else {
        foreach ($line in ($stdoutText -split '\r?\n')) {
            [void]$Lines.Add("    $line")
        }
    }

    [void]$Lines.Add('  STDERR :')
    $stderrText = Convert-UckkGuiBoundedText -Value $stderr
    if ([string]::IsNullOrWhiteSpace($stderrText)) {
        [void]$Lines.Add('    (vide)')
    }
    else {
        foreach ($line in ($stderrText -split '\r?\n')) {
            [void]$Lines.Add("    $line")
        }
    }
}

function Add-UckkGuiResultStepLines {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [AllowNull()][object]$Result,
        [string]$Heading = 'Étapes détaillées'
    )

    if ($null -eq $Result) {
        return
    }

    $steps = @(Get-UckkGuiResultListValue -Object $Result -Name 'steps')
    if ((Get-UckkGuiValueCount -Value $steps) -eq 0) {
        return
    }

    [void]$Lines.Add('')
    [void]$Lines.Add("$Heading :")
    $i = 0

    foreach ($step in $steps) {
        $i++
        $name = Get-UckkGuiResultPropertyValue -Object $step -Name 'name' -Default "Étape $i"
        $stepStatus = Get-UckkGuiResultPropertyValue -Object $step -Name 'status' -Default 'Inconnu'
        $stepSummary = Get-UckkGuiResultPropertyValue -Object $step -Name 'summary' -Default ''
        $stepDetail = Get-UckkGuiResultPropertyValue -Object $step -Name 'detail' -Default ''
        $stepData = Get-UckkGuiResultPropertyValue -Object $step -Name 'data' -Default $null

        [void]$Lines.Add("[$i] $stepStatus — $name")
        if (-not [string]::IsNullOrWhiteSpace([string]$stepSummary)) {
            [void]$Lines.Add("    Résumé : $stepSummary")
        }

        if (-not [string]::IsNullOrWhiteSpace([string]$stepDetail)) {
            [void]$Lines.Add('    Détail :')
            foreach ($line in ((Convert-UckkGuiBoundedText -Value $stepDetail) -split '\r?\n')) {
                [void]$Lines.Add("      $line")
            }
        }

        $nestedProcess = Get-UckkGuiResultPropertyValue -Object $stepData -Name 'process' -Default $null
        if ($null -eq $nestedProcess) {
            $commandLine = Get-UckkGuiResultPropertyValue -Object $stepData -Name 'commandLine' -Default ''
            if (-not [string]::IsNullOrWhiteSpace([string]$commandLine)) {
                $nestedProcess = $stepData
            }
        }

        if ($null -ne $nestedProcess) {
            Add-UckkGuiProcessLines -Lines $Lines -Process $nestedProcess -Heading "    Processus de l'étape $i"
        }
    }
}

function Convert-UckkGuiResultToText {
    param([object]$Result)

    if ($null -eq $Result) {
        return 'Aucun résultat.'
    }

    $status = Get-UckkGuiResultPropertyValue -Object $Result -Name 'status' -Default 'Inconnu'
    $action = Get-UckkGuiResultPropertyValue -Object $Result -Name 'action' -Default 'Action inconnue'
    $domain = Get-UckkGuiResultPropertyValue -Object $Result -Name 'domain' -Default 'non précisé'
    $target = Get-UckkGuiResultPropertyValue -Object $Result -Name 'target' -Default 'non précisée'
    $dangerLevel = Get-UckkGuiResultPropertyValue -Object $Result -Name 'dangerLevel' -Default 0
    $mode = Get-UckkGuiResultPropertyValue -Object $Result -Name 'mode' -Default 'non précisé'
    $summary = Get-UckkGuiResultPropertyValue -Object $Result -Name 'summary' -Default 'Aucun résumé.'
    $nextStep = Get-UckkGuiResultPropertyValue -Object $Result -Name 'nextStep' -Default 'Aucune action requise.'
    $reportPath = Get-UckkGuiResultPropertyValue -Object $Result -Name 'reportPath' -Default $null
    $logPath = Get-UckkGuiResultPropertyValue -Object $Result -Name 'logPath' -Default $null
    $warnings = @(Get-UckkGuiResultListValue -Object $Result -Name 'warnings')
    $errors = @(Get-UckkGuiResultListValue -Object $Result -Name 'errors')
    $data = Get-UckkGuiResultPropertyValue -Object $Result -Name 'data' -Default $null

    $verbose = [bool](Get-UckkGuiConfigValue -Config $script:Config -Path 'ui.verboseResults' -Default $true)

    $lines = New-Object System.Collections.Generic.List[string]

    [void]$lines.Add("Statut : $status")
    [void]$lines.Add("Action : $action")
    [void]$lines.Add("Domaine : $domain")
    [void]$lines.Add("Cible : $target")
    [void]$lines.Add("Niveau de danger : $dangerLevel")
    [void]$lines.Add("Mode : $mode")
    [void]$lines.Add('')
    [void]$lines.Add("Résumé : $summary")
    [void]$lines.Add('')
    [void]$lines.Add("Prochaine étape : $nextStep")

    if ((Get-UckkGuiValueCount -Value $warnings) -gt 0) {
        [void]$lines.Add('')
        [void]$lines.Add('Avertissements :')
        foreach ($warning in $warnings) {
            [void]$lines.Add("- $warning")
        }
    }

    if ((Get-UckkGuiValueCount -Value $errors) -gt 0) {
        [void]$lines.Add('')
        [void]$lines.Add('Erreurs :')
        foreach ($errorItem in $errors) {
            [void]$lines.Add("- $errorItem")
        }
    }

    if ($verbose) {
        Add-UckkGuiResultStepLines -Lines $lines -Result $Result

        $directProcess = Get-UckkGuiResultPropertyValue -Object $data -Name 'process' -Default $null
        if ($null -ne $directProcess) {
            Add-UckkGuiProcessLines -Lines $lines -Process $directProcess -Heading 'Processus principal'
        }

        # Composite Accueil/Publication: expose every child and fully expand the failed child.
        $completed = @(Get-UckkGuiResultPropertyValue -Object $data -Name 'completed' -Default @())
        if ((Get-UckkGuiValueCount -Value $completed) -gt 0) {
            [void]$lines.Add('')
            [void]$lines.Add('Chaîne exécutée :')
            $childIndex = 0
            foreach ($entry in $completed) {
                $childIndex++
                $childId = Get-UckkGuiResultPropertyValue -Object $entry -Name 'id' -Default ''
                $childStatus = Get-UckkGuiResultPropertyValue -Object $entry -Name 'status' -Default 'Inconnu'
                $childLabel = Get-UckkGuiResultPropertyValue -Object $entry -Name 'label' -Default $childId
                $childSummary = Get-UckkGuiResultPropertyValue -Object $entry -Name 'summary' -Default ''
                [void]$lines.Add("[$childIndex] $childStatus — $childId — $childLabel")
                if (-not [string]::IsNullOrWhiteSpace([string]$childSummary)) {
                    [void]$lines.Add("    $childSummary")
                }
            }
        }

        $failedResult = Get-UckkGuiResultPropertyValue -Object $data -Name 'failedResult' -Default $null
        if ($null -ne $failedResult) {
            [void]$lines.Add('')
            [void]$lines.Add('===== DÉTAIL COMPLET DE L ÉTAPE ÉCHOUÉE =====')
            $failedAction = Get-UckkGuiResultPropertyValue -Object $failedResult -Name 'action' -Default 'Étape échouée'
            $failedSummary = Get-UckkGuiResultPropertyValue -Object $failedResult -Name 'summary' -Default ''
            [void]$lines.Add("Action : $failedAction")
            [void]$lines.Add("Résumé : $failedSummary")

            $failedErrors = @(Get-UckkGuiResultListValue -Object $failedResult -Name 'errors')
            if ((Get-UckkGuiValueCount -Value $failedErrors) -gt 0) {
                [void]$lines.Add('Erreurs de l étape :')
                foreach ($failedError in $failedErrors) {
                    [void]$lines.Add("- $failedError")
                }
            }

            Add-UckkGuiResultStepLines -Lines $lines -Result $failedResult -Heading 'Étapes internes de l étape échouée'

            $failedData = Get-UckkGuiResultPropertyValue -Object $failedResult -Name 'data' -Default $null
            $failedProcess = Get-UckkGuiResultPropertyValue -Object $failedData -Name 'process' -Default $null
            if ($null -ne $failedProcess) {
                Add-UckkGuiProcessLines -Lines $lines -Process $failedProcess -Heading 'Processus de l étape échouée'
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$reportPath)) {
        [void]$lines.Add('')
        [void]$lines.Add("Rapport : $reportPath")
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$logPath)) {
        [void]$lines.Add("Log : $logPath")
    }

    return ($lines -join [Environment]::NewLine)
}

function New-UckkGuiAction {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][string]$Tab,
        [Parameter(Mandatory)][string]$Domain,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][int]$DangerLevel,
        [Parameter(Mandatory)][string]$Mode,
        [string]$Handler = $null,
        [bool]$RequiresConfirmation = $false,
        [bool]$RequiresSimulation = $false,
        [bool]$RequiresBackup = $false,
        [bool]$ProducesReport = $true,
        [bool]$ProducesLog = $true,
        [string]$BuiltinType = $null,
        [string]$BuiltinValue = $null
    )

    return [pscustomobject]@{
        id                   = $Id
        label                = $Label
        description          = $Description
        tab                  = $Tab
        domain               = $Domain
        target               = $Target
        dangerLevel          = $DangerLevel
        mode                 = $Mode
        handler              = $Handler
        requiresConfirmation = $RequiresConfirmation
        requiresSimulation   = $RequiresSimulation
        requiresBackup       = $RequiresBackup
        producesReport       = $ProducesReport
        producesLog          = $ProducesLog
        builtinType          = $BuiltinType
        builtinValue         = $BuiltinValue
    }
}

function Get-UckkGuiFallbackActions {
    $actions = @()

    $actions += New-UckkGuiAction `
        -Id "home.local_ready" `
        -Label "Préparer local et ouvrir Moodle" `
        -Description "Exécute la chaîne locale complète : vérifier la configuration et les chemins, diagnostiquer la racine CLI Moodle, synchroniser la source, appliquer l upgrade, purger les caches, démarrer Moodle puis ouvrir UCKK." `
        -Tab "Accueil" `
        -Domain "local" `
        -Target "Moodle local + base locale" `
        -DangerLevel 3 `
        -Mode "application" `
        -Handler "Invoke-UckkOpsHomeLocalReady" `
        -RequiresConfirmation $true `
        -ProducesReport $true `
        -ProducesLog $true

    $actions += New-UckkGuiAction `
        -Id "home.publish_to_uckk" `
        -Label "Publier jusqu'à uckk.org" `
        -Description "Exécute la chaîne complète vers le public : préparation locale, vérifications Git, envoi Git, publication serveur, vérification de uckk.org et ouverture du site public." `
        -Tab "Accueil" `
        -Domain "server" `
        -Target "uckk.org" `
        -DangerLevel 5 `
        -Mode "publication" `
        -Handler "Invoke-UckkOpsHomePublishToUckk" `
        -RequiresConfirmation $true `
        -ProducesReport $true `
        -ProducesLog $true

    $actions += New-UckkGuiAction -Id 'local.check-paths' -Label 'Vérifier les chemins locaux' -Description 'Vérifie source locale, Moodle local, reports et logs.' -Tab 'Local' -Domain 'local' -Target 'local' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkLocalPaths'
    $actions += New-UckkGuiAction -Id 'local.sync-runtime' -Label 'Synchroniser source vers Moodle local' -Description 'Copie le code source vers le dossier exécuté par Moodle local.' -Tab 'Local' -Domain 'local' -Target 'local' -DangerLevel 2 -Mode 'application' -Handler 'Invoke-UckkLocalSourceToRuntimeSync'
    $actions += New-UckkGuiAction -Id 'local.moodle-diagnostic' -Label 'Diagnostiquer Moodle local' -Description 'Détecte la racine CLI, le webroot, PHP et les scripts admin/cli.' -Tab 'Local' -Domain 'local' -Target 'Moodle local' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkLocalMoodleCli'
    $actions += New-UckkGuiAction -Id 'local.moodle-upgrade' -Label 'Mettre à jour Moodle local' -Description 'Applique les upgrades Moodle locaux après synchronisation des plugins.' -Tab 'Local' -Domain 'local' -Target 'base Moodle locale' -DangerLevel 3 -Mode 'application' -Handler 'Invoke-UckkLocalMoodleUpgrade' -RequiresConfirmation $true
    $actions += New-UckkGuiAction -Id 'local.purge-caches' -Label 'Purger les caches locaux' -Description 'Purge les caches Moodle locaux.' -Tab 'Local' -Domain 'local' -Target 'local' -DangerLevel 2 -Mode 'application' -Handler 'Invoke-UckkLocalPurgeCaches'
    $actions += New-UckkGuiAction -Id 'local.open' -Label 'Ouvrir Moodle local' -Description 'Démarre Moodle local si nécessaire, puis ouvre la page locale.' -Tab 'Local' -Domain 'local' -Target 'local' -DangerLevel 2 -Mode 'application' -ProducesReport $true -ProducesLog $true -Handler 'Open-UckkLocalMoodle'
    $actions += New-UckkGuiAction -Id 'local.open-uckk' -Label 'Ouvrir UCKK' -Description 'Ouvre la façade UCKK locale.' -Tab 'Local' -Domain 'local' -Target 'façade UCKK' -DangerLevel 0 -Mode 'navigation' -Handler 'Open-UckkLocalUckkFacade'
    $actions += New-UckkGuiAction -Id 'local.open-ucc' -Label 'Ouvrir UCC' -Description 'Ouvre la façade Univers-Cité Catho locale.' -Tab 'Local' -Domain 'local' -Target 'façade UCC' -DangerLevel 0 -Mode 'navigation' -Handler 'Open-UckkLocalUccFacade'
    $actions += New-UckkGuiAction -Id 'local.open-math' -Label 'Ouvrir Math' -Description 'Ouvre la façade Univers-Cité des mathématiques locale.' -Tab 'Local' -Domain 'local' -Target 'façade Math' -DangerLevel 0 -Mode 'navigation' -Handler 'Open-UckkLocalMathFacade'
    $actions += New-UckkGuiAction -Id 'local.test-facades' -Label 'Tester switcher UCKK / UCC / Math' -Description 'Teste les trois façades locales et leurs marqueurs d identité.' -Tab 'Local' -Domain 'local' -Target 'façades publiques locales' -DangerLevel 1 -Mode 'test' -Handler 'Test-UckkLocalPublicFacades'

    $actions += New-UckkGuiAction -Id 'git.status' -Label 'Vérifier Git' -Description 'Affiche l état Git du projet.' -Tab 'Git' -Domain 'git' -Target 'Git' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkGitStatus'
    $actions += New-UckkGuiAction -Id 'git.diff' -Label 'Afficher les différences Git' -Description 'Affiche les changements avant commit.' -Tab 'Git' -Domain 'git' -Target 'Git' -DangerLevel 1 -Mode 'vérification' -Handler 'Show-UckkGitDiff'
    $actions += New-UckkGuiAction -Id 'git.secrets' -Label 'Vérifier les fichiers sensibles' -Description 'Cherche les fichiers ou contenus sensibles avant commit/push.' -Tab 'Git' -Domain 'git' -Target 'Git' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkGitSensitiveFiles'
    $actions += New-UckkGuiAction -Id 'git.commit' -Label 'Créer un commit Git' -Description 'Enregistre les changements dans Git.' -Tab 'Git' -Domain 'git' -Target 'Git' -DangerLevel 3 -Mode 'application' -Handler 'Invoke-UckkGitCommit' -RequiresConfirmation $true
    $actions += New-UckkGuiAction -Id 'git.push' -Label 'Envoyer les changements vers Git' -Description 'Envoie les commits vers le dépôt distant.' -Tab 'Git' -Domain 'git' -Target 'Git' -DangerLevel 3 -Mode 'application' -Handler 'Invoke-UckkGitPush' -RequiresConfirmation $true

    $actions += New-UckkGuiAction -Id 'server.connection' -Label 'Tester connexion serveur' -Description 'Teste la connexion SSH au serveur.' -Tab 'Serveur' -Domain 'server' -Target 'serveur' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkServerConnection'
    $actions += New-UckkGuiAction -Id 'server.status' -Label 'Vérifier état serveur' -Description 'Lit l état serveur sans modifier.' -Tab 'Serveur' -Domain 'server' -Target 'serveur' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkServerStatus'
    $actions += New-UckkGuiAction -Id 'server.pull' -Label 'Récupérer dernier code sur serveur' -Description 'Met à jour la source serveur depuis Git.' -Tab 'Serveur' -Domain 'server' -Target 'serveur' -DangerLevel 5 -Mode 'application' -Handler 'Invoke-UckkServerGitPull' -RequiresConfirmation $true
    $actions += New-UckkGuiAction -Id 'server.sync-runtime' -Label 'Synchroniser source serveur vers Moodle serveur' -Description 'Copie la source serveur vers le dossier exécuté par Moodle serveur.' -Tab 'Serveur' -Domain 'server' -Target 'serveur' -DangerLevel 5 -Mode 'application' -Handler 'Invoke-UckkServerSourceToRuntimeSync' -RequiresConfirmation $true
    $actions += New-UckkGuiAction -Id 'server.moodle-upgrade' -Label 'Mettre à jour Moodle serveur' -Description 'Lance la mise à jour Moodle serveur si nécessaire.' -Tab 'Serveur' -Domain 'server' -Target 'base Moodle serveur' -DangerLevel 6 -Mode 'application' -Handler 'Invoke-UckkServerMoodleUpgrade' -RequiresConfirmation $true
    $actions += New-UckkGuiAction -Id 'server.purge-caches' -Label 'Purger les caches serveur' -Description 'Purge les caches Moodle serveur.' -Tab 'Serveur' -Domain 'server' -Target 'serveur' -DangerLevel 5 -Mode 'application' -Handler 'Invoke-UckkServerPurgeCaches' -RequiresConfirmation $true
    $actions += New-UckkGuiAction -Id 'server.reload-php' -Label 'Recharger PHP-FPM' -Description 'Recharge le service PHP-FPM serveur.' -Tab 'Serveur' -Domain 'server' -Target 'serveur' -DangerLevel 5 -Mode 'application' -Handler 'Invoke-UckkServerReloadPhpFpm' -RequiresConfirmation $true
    $actions += New-UckkGuiAction -Id 'server.verify-public' -Label 'Vérifier uckk.org — UCKK / UCC / Math' -Description 'Vérifie les pages publiques et les trois façades du switcher.' -Tab 'Serveur' -Domain 'server' -Target 'serveur' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkServerPublicPages'

    $actions += New-UckkGuiAction -Id 'mediatheque.open-manifest' -Label 'Ouvrir manifeste Médiathèque' -Description 'Ouvre le fichier source de vérité Médiathèque.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'aucune cible modifiée' -DangerLevel 0 -Mode 'navigation' -ProducesReport $false -ProducesLog $false -BuiltinType 'OpenPath' -BuiltinValue 'mediatheque.manifestPath'
    $actions += New-UckkGuiAction -Id 'mediatheque.validate' -Label 'Vérifier manifeste Médiathèque' -Description 'Valide le manifeste Médiathèque.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'aucune cible modifiée' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkMediathequeManifest'
    $actions += New-UckkGuiAction -Id 'mediatheque.sim.local' -Label 'Simulation Médiathèque locale' -Description 'Montre ce qui serait écrit dans la base Moodle locale.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'base Moodle locale' -DangerLevel 1 -Mode 'simulation' -Handler 'Invoke-UckkMediathequeSimulationLocal'
    $actions += New-UckkGuiAction -Id 'mediatheque.apply.local' -Label 'Appliquer Médiathèque localement' -Description 'Écrit la Médiathèque dans la base Moodle locale.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'base Moodle locale' -DangerLevel 4 -Mode 'application' -Handler 'Invoke-UckkMediathequeApplyLocal' -RequiresConfirmation $true -RequiresSimulation $true
    $actions += New-UckkGuiAction -Id 'mediatheque.verify.local' -Label 'Vérifier Médiathèque locale' -Description 'Vérifie la page et le service Médiathèque local.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'Médiathèque locale' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkMediathequeLocal'
    $actions += New-UckkGuiAction -Id 'mediatheque.sim.server' -Label 'Simulation Médiathèque serveur' -Description 'Montre ce qui serait écrit dans la base Moodle serveur.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'base Moodle serveur' -DangerLevel 1 -Mode 'simulation' -Handler 'Invoke-UckkMediathequeSimulationServer'
    $actions += New-UckkGuiAction -Id 'mediatheque.apply.server' -Label 'Appliquer Médiathèque serveur' -Description 'Écrit la Médiathèque dans la base Moodle serveur.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'base Moodle serveur' -DangerLevel 6 -Mode 'application' -Handler 'Invoke-UckkMediathequeApplyServer' -RequiresConfirmation $true -RequiresSimulation $true
    $actions += New-UckkGuiAction -Id 'mediatheque.verify.server' -Label 'Vérifier Médiathèque serveur' -Description 'Vérifie la page et le service Médiathèque serveur.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'Médiathèque serveur' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkMediathequeServer'
    $actions += New-UckkGuiAction -Id 'mediatheque.open.server' -Label 'Ouvrir Médiathèque serveur' -Description 'Ouvre la page Médiathèque serveur.' -Tab 'Médiathèque' -Domain 'mediatheque' -Target 'serveur' -DangerLevel 0 -Mode 'navigation' -ProducesReport $false -ProducesLog $false -BuiltinType 'OpenUrl' -BuiltinValue 'urls.serverMediatheque'

    $actions += New-UckkGuiAction -Id 'moodledata.validate' -Label 'Vérifier fichiers JSON Moodle' -Description 'Valide les fichiers JSON des Données Moodle.' -Tab 'Données Moodle' -Domain 'moodle-data' -Target 'aucune cible modifiée' -DangerLevel 1 -Mode 'vérification' -Handler 'Test-UckkMoodleDataJson'
    $actions += New-UckkGuiAction -Id 'moodledata.categories.sim.local' -Label 'Simulation catégories locales' -Description 'Montre les changements de catégories en local.' -Tab 'Données Moodle' -Domain 'moodle-data' -Target 'base Moodle locale' -DangerLevel 1 -Mode 'simulation' -Handler 'Invoke-UckkMoodleDataCategoriesSimulationLocal'
    $actions += New-UckkGuiAction -Id 'moodledata.categories.apply.local' -Label 'Appliquer catégories localement' -Description 'Écrit les catégories dans la base Moodle locale.' -Tab 'Données Moodle' -Domain 'moodle-data' -Target 'base Moodle locale' -DangerLevel 4 -Mode 'application' -Handler 'Invoke-UckkMoodleDataCategoriesApplyLocal' -RequiresConfirmation $true -RequiresSimulation $true
    $actions += New-UckkGuiAction -Id 'moodledata.categories.sim.server' -Label 'Simulation catégories serveur' -Description 'Montre les changements de catégories sur serveur.' -Tab 'Données Moodle' -Domain 'moodle-data' -Target 'base Moodle serveur' -DangerLevel 1 -Mode 'simulation' -Handler 'Invoke-UckkMoodleDataCategoriesSimulationServer'
    $actions += New-UckkGuiAction -Id 'moodledata.categories.apply.server' -Label 'Appliquer catégories serveur' -Description 'Écrit les catégories dans la base Moodle serveur.' -Tab 'Données Moodle' -Domain 'moodle-data' -Target 'base Moodle serveur' -DangerLevel 6 -Mode 'application' -Handler 'Invoke-UckkMoodleDataCategoriesApplyServer' -RequiresConfirmation $true -RequiresSimulation $true
    $actions += New-UckkGuiAction -Id 'moodledata.courses.sim.server' -Label 'Simulation cours serveur' -Description 'Montre les changements de cours sur serveur.' -Tab 'Données Moodle' -Domain 'moodle-data' -Target 'base Moodle serveur' -DangerLevel 1 -Mode 'simulation' -Handler 'Invoke-UckkMoodleDataCoursesSimulationServer'
    $actions += New-UckkGuiAction -Id 'moodledata.courses.apply.server' -Label 'Appliquer cours serveur' -Description 'Écrit les cours dans la base Moodle serveur.' -Tab 'Données Moodle' -Domain 'moodle-data' -Target 'base Moodle serveur' -DangerLevel 6 -Mode 'application' -Handler 'Invoke-UckkMoodleDataCoursesApplyServer' -RequiresConfirmation $true -RequiresSimulation $true

    $actions += New-UckkGuiAction -Id 'tests.local-pages' -Label 'Tester les pages locales' -Description 'Teste les pages locales importantes.' -Tab 'Tests' -Domain 'tests' -Target 'local' -DangerLevel 1 -Mode 'test' -Handler 'Test-UckkLocalPages'
    $actions += New-UckkGuiAction -Id 'tests.server-pages' -Label 'Tester les pages serveur' -Description 'Teste les pages serveur importantes.' -Tab 'Tests' -Domain 'tests' -Target 'serveur' -DangerLevel 1 -Mode 'test' -Handler 'Test-UckkServerPages'
    $actions += New-UckkGuiAction -Id 'tests.mediatheque-server' -Label 'Tester Médiathèque serveur' -Description 'Teste la page et le service Médiathèque serveur.' -Tab 'Tests' -Domain 'tests' -Target 'Médiathèque serveur' -DangerLevel 1 -Mode 'test' -Handler 'Test-UckkMediathequeServer'

    $actions += New-UckkGuiAction -Id 'history.open-reports' -Label 'Ouvrir dossier reports' -Description 'Ouvre le dossier des rapports.' -Tab 'Historique' -Domain 'history' -Target 'aucune cible modifiée' -DangerLevel 0 -Mode 'navigation' -ProducesReport $false -ProducesLog $false -BuiltinType 'OpenPath' -BuiltinValue 'paths.reportsDir'
    $actions += New-UckkGuiAction -Id 'history.open-logs' -Label 'Ouvrir dossier logs' -Description 'Ouvre le dossier des logs.' -Tab 'Historique' -Domain 'history' -Target 'aucune cible modifiée' -DangerLevel 0 -Mode 'navigation' -ProducesReport $false -ProducesLog $false -BuiltinType 'OpenPath' -BuiltinValue 'paths.logsDir'
    $actions += New-UckkGuiAction -Id 'history.open-latest-report' -Label 'Ouvrir le dernier rapport' -Description 'Ouvre le dernier rapport Markdown.' -Tab 'Historique' -Domain 'history' -Target 'aucune cible modifiée' -DangerLevel 0 -Mode 'navigation' -ProducesReport $false -ProducesLog $false -BuiltinType 'OpenLatestReport'

    $actions += New-UckkGuiAction -Id 'recovery.open-folder' -Label 'Ouvrir dossier recovery' -Description 'Ouvre le dossier recovery sans lancer d action.' -Tab 'Récupération' -Domain 'recovery' -Target 'aucune cible modifiée' -DangerLevel 0 -Mode 'navigation' -ProducesReport $false -ProducesLog $false -BuiltinType 'OpenPath' -BuiltinValue 'paths.recoveryDir'
    $actions += New-UckkGuiAction -Id 'recovery.open-legacy' -Label 'Ouvrir dossier legacy' -Description 'Ouvre le dossier legacy sans lancer d action.' -Tab 'Récupération' -Domain 'recovery' -Target 'aucune cible modifiée' -DangerLevel 0 -Mode 'navigation' -ProducesReport $false -ProducesLog $false -BuiltinType 'OpenPath' -BuiltinValue 'paths.legacyDir'

    return $actions
}

function Get-UckkGuiObjectValue {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $Default
    }

    try {
        if ($Object -is [hashtable]) {
            if ($Object.ContainsKey($Name)) {
                return $Object[$Name]
            }

            return $Default
        }

        if ($Object -is [System.Collections.IDictionary]) {
            if ($Object.Contains($Name)) {
                return $Object[$Name]
            }

            return $Default
        }

        $properties = $null

        try {
            $properties = $Object.PSObject.Properties.Match($Name)
        }
        catch {
            $properties = $null
        }

        foreach ($property in @($properties)) {
            if ($null -ne $property) {
                try {
                    if ($null -ne $property.Value) {
                        return $property.Value
                    }
                }
                catch {
                    Add-UckkGuiLoadMessage ("Lecture propriété GUI ignorée : " + $Name + " — " + $_.Exception.Message)
                    return $Default
                }
            }
        }

        try {
            foreach ($property in @($Object.PSObject.Properties)) {
                if ($null -ne $property -and $property.Name -ieq $Name) {
                    try {
                        if ($null -ne $property.Value) {
                            return $property.Value
                        }
                    }
                    catch {
                        Add-UckkGuiLoadMessage ("Lecture propriété GUI ignorée : " + $Name + " — " + $_.Exception.Message)
                        return $Default
                    }
                }
            }
        }
        catch {
            Add-UckkGuiLoadMessage ("Lecture propriétés GUI ignorée : " + $Name + " — " + $_.Exception.Message)
            return $Default
        }
    }
    catch {
        Add-UckkGuiLoadMessage ("Lecture propriété GUI ignorée : " + $Name + " — " + $_.Exception.Message)
        return $Default
    }

    return $Default
}

function ConvertTo-UckkGuiStringArray {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value
    )

    $items = @()

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return @()
        }

        return @([string]$Value)
    }

    try {
        if (
            $Value -is [System.Collections.IEnumerable] -and
            $Value -isnot [System.Collections.IDictionary]
        ) {
            foreach ($item in $Value) {
                if ($null -eq $item) {
                    continue
                }

                $text = [string]$item

                if (-not [string]::IsNullOrWhiteSpace($text)) {
                    $items += $text
                }
            }

            return @($items)
        }
    }
    catch {
        Add-UckkGuiLoadMessage ("Conversion liste GUI ignorée : " + $_.Exception.Message)
        return @()
    }

    try {
        $single = [string]$Value

        if (-not [string]::IsNullOrWhiteSpace($single)) {
            $items += $single
        }
    }
    catch {
        Add-UckkGuiLoadMessage ("Conversion texte GUI ignorée : " + $_.Exception.Message)
    }

    return @($items)
}

function ConvertTo-UckkGuiBoolean {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [bool]$Default = $false
    )

    if ($null -eq $Value) {
        return $Default
    }

    if ($Value -is [bool]) {
        return [bool]$Value
    }

    $text = ([string]$Value).Trim().ToLowerInvariant()

    if ($text -in @('true', '1', 'yes', 'oui', 'vrai')) {
        return $true
    }

    if ($text -in @('false', '0', 'no', 'non', 'faux')) {
        return $false
    }

    return $Default
}

function ConvertTo-UckkGuiInteger {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [int]$Default = 0
    )

    if ($null -eq $Value) {
        return $Default
    }

    try {
        return [int]$Value
    }
    catch {
        return $Default
    }
}

function Convert-UckkRegistryActionsToGuiActions {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$RegisteredActions
    )

    $guiActions = @()
    $failedActions = @()
    $sourceActions = @()
    $index = 0

    try {
        if ($null -ne $RegisteredActions) {
            if (
                $RegisteredActions -is [System.Collections.IEnumerable] -and
                $RegisteredActions -isnot [string] -and
                $RegisteredActions -isnot [System.Collections.IDictionary]
            ) {
                foreach ($item in $RegisteredActions) {
                    if ($null -ne $item) {
                        $sourceActions += $item
                    }
                }
            }
            else {
                $sourceActions += $RegisteredActions
            }
        }
    }
    catch {
        Add-UckkGuiLoadMessage ("ActionRegistry : énumération impossible : " + $_.Exception.GetType().FullName + " — " + $_.Exception.Message)
        return @()
    }

    foreach ($registeredAction in @($sourceActions)) {
        $index++

        if ($null -eq $registeredAction) {
            Add-UckkGuiLoadMessage ("ActionRegistry : entrée nulle ignorée #" + $index)
            continue
        }

        $actionId = "registry.action.$index"
        $actionLabel = "Action"

        try {
            $actionId = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "id" -Default "")
            $actionLabel = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "label" -Default "Action")

            if ([string]::IsNullOrWhiteSpace($actionId)) {
                $actionId = "registry.action.$index"
            }

            if ([string]::IsNullOrWhiteSpace($actionLabel)) {
                $actionLabel = $actionId
            }

            $visibleRaw = Get-UckkGuiObjectValue -Object $registeredAction -Name "visible" -Default $true
            $visible = ConvertTo-UckkGuiBoolean -Value $visibleRaw -Default $true

            if (-not $visible) {
                continue
            }

            $tabsRaw = Get-UckkGuiObjectValue -Object $registeredAction -Name "tabs" -Default $null
            $tabs = @(ConvertTo-UckkGuiStringArray -Value $tabsRaw)
            $singleTab = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "tab" -Default "")

            if ((Get-UckkGuiValueCount -Value $tabs) -eq 0 -and -not [string]::IsNullOrWhiteSpace($singleTab)) {
                $tabs = @($singleTab)
            }

            if ((Get-UckkGuiValueCount -Value $tabs) -eq 0) {
                Add-UckkGuiLoadMessage ("ActionRegistry : action ignorée sans onglet id=" + $actionId + " label=" + $actionLabel)
                continue
            }

            $description = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "description" -Default "")
            $domain = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "domain" -Default "configuration")
            $target = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "target" -Default "aucune cible modifiée")
            $dangerLevel = ConvertTo-UckkGuiInteger -Value (Get-UckkGuiObjectValue -Object $registeredAction -Name "dangerLevel" -Default 0) -Default 0
            $mode = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "mode" -Default "vérification")
            $handler = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "handler" -Default "")
            $requiresConfirmation = ConvertTo-UckkGuiBoolean -Value (Get-UckkGuiObjectValue -Object $registeredAction -Name "requiresConfirmation" -Default $false) -Default $false
            $requiresSimulation = ConvertTo-UckkGuiBoolean -Value (Get-UckkGuiObjectValue -Object $registeredAction -Name "requiresSimulation" -Default $false) -Default $false
            $requiresBackup = ConvertTo-UckkGuiBoolean -Value (Get-UckkGuiObjectValue -Object $registeredAction -Name "requiresBackup" -Default $false) -Default $false
            $producesReport = ConvertTo-UckkGuiBoolean -Value (Get-UckkGuiObjectValue -Object $registeredAction -Name "producesReport" -Default $true) -Default $true
            $producesLog = ConvertTo-UckkGuiBoolean -Value (Get-UckkGuiObjectValue -Object $registeredAction -Name "producesLog" -Default $true) -Default $true
            $confirmationMessage = [string](Get-UckkGuiObjectValue -Object $registeredAction -Name "confirmationMessage" -Default "")

            $addedForAction = 0

            foreach ($tab in @($tabs)) {
                $tabName = [string]$tab

                if ([string]::IsNullOrWhiteSpace($tabName)) {
                    continue
                }

                $guiAction = New-Object psobject

                $guiAction | Add-Member -MemberType NoteProperty -Name id -Value $actionId
                $guiAction | Add-Member -MemberType NoteProperty -Name label -Value $actionLabel
                $guiAction | Add-Member -MemberType NoteProperty -Name description -Value $description
                $guiAction | Add-Member -MemberType NoteProperty -Name tab -Value $tabName
                $guiAction | Add-Member -MemberType NoteProperty -Name domain -Value $domain
                $guiAction | Add-Member -MemberType NoteProperty -Name target -Value $target
                $guiAction | Add-Member -MemberType NoteProperty -Name dangerLevel -Value $dangerLevel
                $guiAction | Add-Member -MemberType NoteProperty -Name mode -Value $mode
                $guiAction | Add-Member -MemberType NoteProperty -Name handler -Value $handler
                $guiAction | Add-Member -MemberType NoteProperty -Name requiresConfirmation -Value $requiresConfirmation
                $guiAction | Add-Member -MemberType NoteProperty -Name requiresSimulation -Value $requiresSimulation
                $guiAction | Add-Member -MemberType NoteProperty -Name requiresBackup -Value $requiresBackup
                $guiAction | Add-Member -MemberType NoteProperty -Name producesReport -Value $producesReport
                $guiAction | Add-Member -MemberType NoteProperty -Name producesLog -Value $producesLog
                $guiAction | Add-Member -MemberType NoteProperty -Name builtinType -Value $null
                $guiAction | Add-Member -MemberType NoteProperty -Name builtinValue -Value $null
                $guiAction | Add-Member -MemberType NoteProperty -Name actionDefinition -Value $registeredAction
                $guiAction | Add-Member -MemberType NoteProperty -Name confirmationMessage -Value $confirmationMessage

                $guiActions += $guiAction
                $addedForAction++
            }

            if ($addedForAction -eq 0) {
                Add-UckkGuiLoadMessage ("ActionRegistry : action ignorée sans onglet utilisable id=" + $actionId + " label=" + $actionLabel)
            }
        }
        catch {
            $message = "ActionRegistry : conversion ignorée #" + $index + " id=" + $actionId + " label=" + $actionLabel + " : " + $_.Exception.GetType().FullName + " — " + $_.Exception.Message
            Add-UckkGuiLoadMessage $message
            $failedActions += $message
            continue
        }
    }

    if ((Get-UckkGuiValueCount -Value $failedActions) -gt 0) {
        Add-UckkGuiLoadMessage ("ActionRegistry : " + (Get-UckkGuiValueCount -Value $failedActions) + " action(s) ignorée(s), " + (Get-UckkGuiValueCount -Value $guiActions) + " action(s) GUI conservée(s).")
    }

    return @($guiActions)
}

function Get-UckkGuiActions {
    $registryCommand = Get-Command -Name "Get-UckkOpsActionRegistry" -ErrorAction SilentlyContinue

    if ($null -ne $registryCommand) {
        $registered = $null

        try {
            $registered = @(& $registryCommand)
            Add-UckkGuiLoadMessage ("ActionRegistry chargé : " + (Get-UckkGuiValueCount -Value $registered) + " action(s)")
        }
        catch {
            Add-UckkGuiLoadMessage "ActionRegistry impossible à appeler : $($_.Exception.GetType().FullName) — $($_.Exception.Message)"
            $registered = $null
        }

        if ($null -ne $registered -and (Get-UckkGuiValueCount -Value $registered) -gt 0) {
            $converted = @()

            try {
                $converted = @(Convert-UckkRegistryActionsToGuiActions -RegisteredActions $registered)
            }
            catch {
                Add-UckkGuiLoadMessage "ActionRegistry chargé, mais conversion GUI globale échouée : $($_.Exception.GetType().FullName) — $($_.Exception.Message)"

                if ($_.ScriptStackTrace) {
                    Add-UckkGuiLoadMessage ("Trace conversion GUI : " + ($_.ScriptStackTrace -replace [Environment]::NewLine, " | "))
                }

                $converted = @()
            }

            if ((Get-UckkGuiValueCount -Value $converted) -gt 0) {
                Add-UckkGuiLoadMessage ("Actions chargées depuis le registre : " + (Get-UckkGuiValueCount -Value $converted))
                return @($converted)
            }

            Add-UckkGuiLoadMessage "ActionRegistry chargé, mais aucune action valide n'a pu être associée à un onglet. Utilisation des actions de secours."
        }
    }
    else {
        Add-UckkGuiLoadMessage "Commande Get-UckkOpsActionRegistry introuvable. Utilisation des actions de secours."
    }

    $fallback = @(Get-UckkGuiFallbackActions)
    Add-UckkGuiLoadMessage ("Actions de secours chargées : " + (Get-UckkGuiValueCount -Value $fallback))
    return @($fallback)
}

function Get-UckkGuiConfirmationMessage {
    param([object]$Action)

    $explicitMessage = [string](Get-UckkGuiObjectValue -Object $Action -Name "confirmationMessage" -Default "")

    if (-not [string]::IsNullOrWhiteSpace($explicitMessage)) {
        return $explicitMessage
    }

    if ($Action.dangerLevel -eq 3) {
        return "Cette action enregistre ou envoie des changements dans l'historique Git.`nVérifie qu'aucun secret n'est inclus.`nContinuer ?"
    }

    if ($Action.dangerLevel -eq 4) {
        return "Cette action écrit dans la base Moodle locale. Continuer ?"
    }

    if ($Action.dangerLevel -eq 5) {
        return "Cette action modifie uckk.org ou son code serveur. Continuer ?"
    }

    if ($Action.dangerLevel -eq 6) {
        return "Cette action écrit dans la base Moodle serveur. Continuer ?"
    }

    if ($Action.dangerLevel -eq 7) {
        return "Cette action est une récupération, pas une opération normale.`nElle peut modifier plusieurs données.`nUne sauvegarde doit exister avant de continuer.`nContinuer ?"
    }

    return "Cette action peut modifier des données.`nContinuer ?"
}

function Confirm-UckkGuiAction {
    param([object]$Action)

    if (-not $Action.requiresConfirmation) {
        return $true
    }

    $message = Get-UckkGuiConfirmationMessage -Action $Action

    $answer = [System.Windows.Forms.MessageBox]::Show(
        $message,
        "Confirmation requise — $($Action.label)",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    return ($answer -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Invoke-UckkGuiOpenPath {
    param(
        [object]$Action,
        [string]$ConfigPathValue
    )

    $value = Get-UckkGuiConfigValue -Config $script:Config -Path $ConfigPathValue

    if ([string]::IsNullOrWhiteSpace($value)) {
        return New-UckkGuiActionResult -Success $false -Status 'Échoué' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "Chemin absent dans la configuration : $ConfigPathValue" -Errors @("Chemin absent : $ConfigPathValue") -NextStep 'Vérifier la configuration.'
    }

    $resolved = Resolve-UckkGuiPathFromConfig -Value $value

    if (-not (Test-Path -LiteralPath $resolved)) {
        return New-UckkGuiActionResult -Success $false -Status 'Échoué' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "Chemin introuvable : $resolved" -Errors @("Chemin introuvable : $resolved") -NextStep 'Créer le fichier/dossier ou corriger la configuration.'
    }

    Start-Process -FilePath $resolved

    return New-UckkGuiActionResult -Success $true -Status 'Réussi' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "Ouvert : $resolved" -NextStep 'Aucune action requise.'
}

function Invoke-UckkGuiOpenUrl {
    param(
        [object]$Action,
        [string]$ConfigPathValue
    )

    $url = Get-UckkGuiConfigValue -Config $script:Config -Path $ConfigPathValue

    if ([string]::IsNullOrWhiteSpace($url)) {
        return New-UckkGuiActionResult -Success $false -Status 'Échoué' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "URL absente dans la configuration : $ConfigPathValue" -Errors @("URL absente : $ConfigPathValue") -NextStep 'Vérifier la configuration.'
    }

    if ($url -notmatch '^https?://') {
        return New-UckkGuiActionResult -Success $false -Status 'Échoué' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "URL invalide : $url" -Errors @("URL invalide : $url") -NextStep 'Corriger la configuration.'
    }

    Start-Process -FilePath $url

    return New-UckkGuiActionResult -Success $true -Status 'Réussi' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "Ouvert : $url" -NextStep 'Vérifier dans le navigateur si nécessaire.'
}

function Invoke-UckkGuiOpenLatestReport {
    param([object]$Action)

    $reportsDirValue = Get-UckkGuiConfigValue -Config $script:Config -Path 'paths.reportsDir' -Default './reports'
    $reportsDir = Resolve-UckkGuiPathFromConfig -Value $reportsDirValue

    if (-not (Test-Path -LiteralPath $reportsDir)) {
        return New-UckkGuiActionResult -Success $false -Status 'Échoué' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "Dossier reports introuvable : $reportsDir" -Errors @("Dossier reports introuvable.") -NextStep 'Créer le dossier reports ou corriger la configuration.'
    }

    $latest = Get-ChildItem -LiteralPath $reportsDir -Filter '*.md' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $latest) {
        return New-UckkGuiActionResult -Success $false -Status 'Prêt' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary 'Aucun rapport disponible pour le moment.' -NextStep 'Lancer une action qui produit un rapport.'
    }

    Start-Process -FilePath $latest.FullName

    return New-UckkGuiActionResult -Success $true -Status 'Réussi' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "Rapport ouvert : $($latest.FullName)" -ReportPath $latest.FullName -NextStep 'Lire le rapport.'
}

function Resolve-UckkGuiHandlerName {
    param(
        [Parameter(Mandatory)]
        [string]$HandlerName
    )

    $handlerMap = @{
        # Accueil workflows.
        "Invoke-UckkOpsHomeLocalReady"                 = "Invoke-UckkOpsHomeLocalReady"
        "Invoke-UckkOpsHomePublishToUckk"             = "Invoke-UckkOpsHomePublishToUckk"

        # Local.
        "Invoke-UckkLocalSourceToRuntimeSync"         = "Sync-UckkSourceToLocalMoodle"
        "Invoke-UckkLocalPurgeCaches"                 = "Clear-UckkLocalMoodleCaches"
        "Invoke-UckkLocalCachePurge"                  = "Clear-UckkLocalMoodleCaches"
        "Open-UckkLocalSourceFolder"                  = "Invoke-UckkOpsOpenLocalSourceFolder"
        "Open-UckkLocalMoodleRuntimeFolder"           = "Invoke-UckkOpsOpenLocalMoodleRuntimeFolder"

        # Git.
        "Test-UckkGitStatus"                          = "Get-UckkGitStatus"
        "Show-UckkGitDiff"                            = "Get-UckkGitDiff"
        "Invoke-UckkGitCommit"                        = "New-UckkGitCommit"
        "Invoke-UckkGitPush"                          = "Push-UckkGitChanges"
        "Invoke-UckkGitPull"                          = "Pull-UckkGitChanges"

        # Server.
        "Test-UckkServerStatus"                       = "Test-UckkServerState"
        "Test-UckkServerPages"                        = "Invoke-UckkServerPageTests"
        "Test-UckkPublicSite"                         = "Test-UckkServerPublicPages"
        "Publish-UckkServer"                          = "Invoke-UckkServerPublish"
        "Invoke-UckkServerGitPull"                    = "Update-UckkServerSourceFromGit"
        "Invoke-UckkServerSourceToRuntimeSync"        = "Sync-UckkServerSourceToMoodleRuntime"
        "Invoke-UckkServerPurgeCaches"                = "Clear-UckkServerMoodleCaches"
        "Invoke-UckkServerCachePurge"                 = "Clear-UckkServerMoodleCaches"
        "Invoke-UckkServerReloadPhpFpm"               = "Invoke-UckkServerPhpFpmReload"
        "Restart-UckkServerPhpFpm"                    = "Invoke-UckkServerPhpFpmReload"
        "Open-UckkPublicSite"                         = "Invoke-UckkOpsOpenPublicSite"

        # Médiathèque.
        "Open-UckkMediathequeManifest"                = "Open-UckkMediathequeManifest"
        "Test-UckkMediathequeManifest"                = "Test-UckkMediathequeManifestAction"
        "Invoke-UckkMediathequeLocalSimulation"       = "Invoke-UckkMediathequeSimulationLocal"
        "Invoke-UckkMediathequeServerSimulation"      = "Invoke-UckkMediathequeSimulationServer"
        "Invoke-UckkMediathequeLocalApply"            = "Invoke-UckkMediathequeApplyLocal"
        "Invoke-UckkMediathequeServerApply"           = "Invoke-UckkMediathequeApplyServer"

        # Données Moodle.
        "Test-UckkMoodleDataJson"                     = "Test-UckkMoodleDataJsonFiles"
        "Invoke-UckkMoodleDataLocalCategoriesSimulation"  = "Invoke-UckkMoodleDataCategoriesSimulationLocal"
        "Invoke-UckkMoodleDataLocalCategoriesApply"       = "Invoke-UckkMoodleDataCategoriesApplyLocal"
        "Invoke-UckkMoodleDataServerCategoriesSimulation" = "Invoke-UckkMoodleDataCategoriesSimulationServer"
        "Invoke-UckkMoodleDataServerCategoriesApply"      = "Invoke-UckkMoodleDataCategoriesApplyServer"
        "Invoke-UckkMoodleDataLocalCoursesSimulation"     = "Invoke-UckkMoodleDataCoursesSimulationLocal"
        "Invoke-UckkMoodleDataLocalCoursesApply"          = "Invoke-UckkMoodleDataCoursesApplyLocal"
        "Invoke-UckkMoodleDataServerCoursesSimulation"    = "Invoke-UckkMoodleDataCoursesSimulationServer"
        "Invoke-UckkMoodleDataServerCoursesApply"         = "Invoke-UckkMoodleDataCoursesApplyServer"
        "Invoke-UckkMoodleDataLocalProgramsSimulation"    = "Invoke-UckkMoodleDataProgramsSimulationLocal"
        "Invoke-UckkMoodleDataLocalProgramsApply"         = "Invoke-UckkMoodleDataProgramsApplyLocal"
        "Invoke-UckkMoodleDataServerProgramsSimulation"   = "Invoke-UckkMoodleDataProgramsSimulationServer"
        "Invoke-UckkMoodleDataServerProgramsApply"        = "Invoke-UckkMoodleDataProgramsApplyServer"
        "Invoke-UckkMoodleDataLocalPathwaysSimulation"    = "Invoke-UckkMoodleDataPathwaysSimulationLocal"
        "Invoke-UckkMoodleDataLocalPathwaysApply"         = "Invoke-UckkMoodleDataPathwaysApplyLocal"
        "Invoke-UckkMoodleDataServerPathwaysSimulation"   = "Invoke-UckkMoodleDataPathwaysSimulationServer"
        "Invoke-UckkMoodleDataServerPathwaysApply"        = "Invoke-UckkMoodleDataPathwaysApplyServer"

        # GUI / utility actions.
        "Open-UckkLatestReport"                    = "Invoke-UckkOpsOpenCurrentReport"
        "Open-UckkReportsFolder"                   = "Invoke-UckkOpsOpenReportsFolder"
        "Open-UckkLogsFolder"                      = "Invoke-UckkOpsOpenLogsFolder"
        "Open-UckkRecoveryFolder"                  = "Invoke-UckkOpsOpenRecoveryFolder"
        "Open-UckkLegacyFolder"                    = "Invoke-UckkOpsOpenLegacyFolder"
    }

    if ($handlerMap.ContainsKey($HandlerName)) {
        return $handlerMap[$HandlerName]
    }

    return $HandlerName
}

function Test-UckkGuiParameterIsMandatory {
    param([object]$Parameter)

    foreach ($attribute in $Parameter.Attributes) {
        if (
            $attribute -is [System.Management.Automation.ParameterAttribute] -and
            $attribute.Mandatory
        ) {
            return $true
        }
    }

    return $false
}
function Get-UckkGuiDefaultMessage {
    param([object]$Action)

    if (
        $Action.id -eq 'git.commit' -or
        $Action.handler -eq 'Invoke-UckkGitCommit' -or
        $Action.label -match 'commit'
    ) {
        return 'Fix local Moodle auto-start and Git commit prompt'
    }

    return ''
}

function Show-UckkGuiTextPrompt {
    param(
        [string]$Title,
        [string]$Prompt,
        [string]$DefaultText = ''
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Width = 540
    $form.Height = 230
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MinimizeBox = $false
    $form.MaximizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Prompt
    $label.Left = 12
    $label.Top = 12
    $label.Width = 500
    $label.Height = 24

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Left = 12
    $textBox.Top = 42
    $textBox.Width = 500
    $textBox.Height = 72
    $textBox.Multiline = $true
    $textBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $textBox.Text = $DefaultText

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = 'OK'
    $okButton.Left = 334
    $okButton.Top = 132
    $okButton.Width = 82
    $okButton.Height = 28
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Annuler'
    $cancelButton.Left = 428
    $cancelButton.Top = 132
    $cancelButton.Width = 82
    $cancelButton.Height = 28
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton

    [void]$form.Controls.Add($label)
    [void]$form.Controls.Add($textBox)
    [void]$form.Controls.Add($okButton)
    [void]$form.Controls.Add($cancelButton)

    $form.Add_Shown({
        $textBox.Focus()
        $textBox.SelectAll()
    })

    try {
        $dialogResult = $form.ShowDialog()

        if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
            return $null
        }

        return $textBox.Text
    }
    finally {
        $form.Dispose()
    }
}
function Get-UckkGuiHandlerArguments {
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.CommandInfo]$Command,

        [Parameter(Mandatory)]
        [object]$Action,

        [bool]$Confirmed = $false
    )

    $arguments = @{}

    if ($Command.Parameters.ContainsKey("Config")) {
        $configParameter = $Command.Parameters["Config"]

        if (
            $configParameter.ParameterType -eq [string] -or
            $configParameter.ParameterType -eq [System.IO.FileInfo]
        ) {
            $arguments["Config"] = $script:ConfigPath
        }
        else {
            $arguments["Config"] = $script:Config
        }
    }

    if ($Command.Parameters.ContainsKey("ConfigPath")) {
        $arguments["ConfigPath"] = $script:ConfigPath
    }

    if ($Command.Parameters.ContainsKey("Action")) {
        $arguments["Action"] = $Action
    }

    if (
        $Command.Parameters.ContainsKey("State") -or
        $Command.Parameters.ContainsKey("AppState") -or
        $Command.Parameters.ContainsKey("ActionDefinition") -or
        $Command.Parameters.ContainsKey("ActionId")
    ) {
        $state = [pscustomobject]@{
            Config         = $script:Config
            ConfigPath     = $script:ConfigPath
            ActionRegistry = $null
            IsBusy         = $false
            LastResult     = $script:LastResult
            LastReportPath = $script:LastReportPath
            LastLogPath    = $script:LastLogPath
            Controls       = @{}
        }

        $registryCommand = Get-Command -Name "Get-UckkOpsActionRegistry" -ErrorAction SilentlyContinue

        if ($null -ne $registryCommand) {
            try {
                $state.ActionRegistry = & $registryCommand
            }
            catch {
                $state.ActionRegistry = $null
            }
        }

        if ($Command.Parameters.ContainsKey("State")) {
            $arguments["State"] = $state
        }

        if ($Command.Parameters.ContainsKey("AppState")) {
            $arguments["AppState"] = $state
        }

        if ($Command.Parameters.ContainsKey("ActionDefinition")) {
            $arguments["ActionDefinition"] = Get-UckkGuiObjectValue -Object $Action -Name "actionDefinition" -Default $Action
        }

        if ($Command.Parameters.ContainsKey("ActionId")) {
            $arguments["ActionId"] = [string](Get-UckkGuiObjectValue -Object $Action -Name "id" -Default "")
        }
    }

    if ($Command.Parameters.ContainsKey("Confirmed") -and $Confirmed) {
        $arguments["Confirmed"] = $true
    }

    if ($Command.Parameters.ContainsKey("Message") -and -not $arguments.ContainsKey("Message")) {
        $defaultMessage = Get-UckkGuiDefaultMessage -Action $Action

        $message = Show-UckkGuiTextPrompt `
            -Title "Message requis — $($Action.label)" `
            -Prompt "Message de commit Git :" `
            -DefaultText $defaultMessage

        if ($null -eq $message) {
            return $null
        }

        if ([string]::IsNullOrWhiteSpace($message)) {
            return $null
        }

        $arguments["Message"] = $message.Trim()
    }

    if ($Command.Parameters.ContainsKey("AddAll") -and -not $arguments.ContainsKey("AddAll")) {
        if (
            $Action.id -eq "git.commit" -or
            $Action.handler -eq "Invoke-UckkGitCommit" -or
            $Action.handler -eq "New-UckkGitCommit" -or
            $Action.label -match "commit"
        ) {
            $arguments["AddAll"] = $true
        }
    }

    return $arguments
}

function Get-UckkGuiMissingMandatoryHandlerParameters {
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.CommandInfo]$Command,

        [Parameter(Mandatory)]
        [hashtable]$Arguments
    )

    $missing = New-Object System.Collections.Generic.List[string]

    foreach ($parameter in $Command.Parameters.Values) {
        if (
            (Test-UckkGuiParameterIsMandatory -Parameter $parameter) -and
            -not $Arguments.ContainsKey($parameter.Name)
        ) {
            [void]$missing.Add($parameter.Name)
        }
    }

    return @($missing)
}

function Invoke-UckkGuiDeclaredHandler {
    param([object]$Action, [bool]$Confirmed = $false)

    if ([string]::IsNullOrWhiteSpace($Action.handler)) {
        return New-UckkGuiActionResult -Success $false -Status 'Prêt' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary 'Action déclarée, mais aucun handler n est encore associé.' -Warnings @('Handler absent.') -NextStep 'Coder le handler dans le module correspondant.'
    }

    $resolvedHandler = Resolve-UckkGuiHandlerName -HandlerName $Action.handler

    $command = Get-Command -Name $resolvedHandler -ErrorAction SilentlyContinue

    if ($null -eq $command) {
        return New-UckkGuiActionResult -Success $false -Status 'Prêt' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "Action déclarée, mais le handler n est pas encore codé : $resolvedHandler" -Warnings @("Handler introuvable : $resolvedHandler") -NextStep 'Coder le handler dans le module correspondant.'
    }

	$handlerArguments = Get-UckkGuiHandlerArguments -Command $command -Action $Action -Confirmed:$Confirmed

	if ($null -eq $handlerArguments) {
		return New-UckkGuiActionResult `
			-Success $false `
			-Status 'Annulé' `
			-Action $Action.label `
			-Domain $Action.domain `
			-Target $Action.target `
			-DangerLevel $Action.dangerLevel `
			-Mode 'annulation' `
			-Summary 'Annulé — aucun message fourni.' `
			-NextStep 'Relancer l action et saisir un message.'
	}

$missingMandatory = Get-UckkGuiMissingMandatoryHandlerParameters -Command $command -Arguments $handlerArguments

    if ((Get-UckkGuiValueCount -Value $missingMandatory) -gt 0) {
        return New-UckkGuiActionResult -Success $false -Status 'Échoué' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "Le handler demande des paramètres que le GUI ne sait pas fournir : $($missingMandatory -join ', ')." -Errors @("Paramètres obligatoires non fournis : $($missingMandatory -join ', ')") -NextStep 'Corriger le handler ou ajouter le passage de paramètres dans le GUI.'
    }

    try {
        $result = & $command @handlerArguments

        if ($null -eq $result) {
            return New-UckkGuiActionResult -Success $false -Status 'Échoué' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary 'Le handler n a retourné aucun résultat.' -Errors @('Résultat absent.') -NextStep 'Corriger le handler pour retourner un ActionResult.'
        }

        return $result
    }
    catch {
        return New-UckkGuiActionResult -Success $false -Status 'Échoué' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode $Action.mode -Summary "L action a échoué." -Errors @($_.Exception.Message) -NextStep 'Lire le détail technique et corriger le module.'
    }
}

function Set-UckkGuiResultProperty {
    param(
        [Parameter(Mandatory)][object]$Result,
        [Parameter(Mandatory)][string]$Name,
        [AllowNull()][object]$Value
    )

    $property = $Result.PSObject.Properties[$Name]
    if ($null -ne $property) {
        $property.Value = $Value
        return
    }

    $Result | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function Add-UckkGuiArtifactWarning {
    param(
        [Parameter(Mandatory)][object]$Result,
        [Parameter(Mandatory)][string]$Message
    )

    $warnings = Get-UckkGuiResultPropertyValue -Object $Result -Name 'warnings' -Default $null

    if ($warnings -is [System.Collections.ArrayList]) {
        [void]$warnings.Add($Message)
        return
    }

    $current = @(Get-UckkGuiResultListValue -Object $Result -Name 'warnings')
    Set-UckkGuiResultProperty -Result $Result -Name 'warnings' -Value @($current + $Message)
}

function Complete-UckkGuiActionArtifacts {
    param(
        [Parameter(Mandatory)][object]$Action,
        [Parameter(Mandatory)][object]$Result
    )

    if ($null -eq $Result) {
        return $Result
    }

    $producesLog = [bool](Get-UckkGuiResultPropertyValue -Object $Action -Name 'producesLog' -Default $false)
    $producesReport = [bool](Get-UckkGuiResultPropertyValue -Object $Action -Name 'producesReport' -Default $false)

    if ($producesLog -and (Get-Command -Name Write-UckkLog -ErrorAction SilentlyContinue)) {
        try {
            $status = [string](Get-UckkGuiResultPropertyValue -Object $Result -Name 'status' -Default '')
            $level = if ($status -eq 'Échoué') { 'ERROR' } elseif ($status -eq 'Réussi avec avertissements') { 'WARNING' } else { 'INFO' }
            $summary = [string](Get-UckkGuiResultPropertyValue -Object $Result -Name 'summary' -Default '')

            $logPath = Write-UckkLog `
                -Action ([string]$Action.label) `
                -Domain ([string]$Action.domain) `
                -Target ([string]$Action.target) `
                -Message $summary `
                -Data $Result `
                -Config $script:Config `
                -AppRoot $script:AppRoot `
                -Level $level

            Set-UckkGuiResultProperty -Result $Result -Name 'logPath' -Value $logPath
        }
        catch {
            Add-UckkGuiArtifactWarning -Result $Result -Message "Le log technique n a pas pu être écrit : $($_.Exception.Message)"
        }
    }

    if ($producesReport -and (Get-Command -Name Write-UckkReport -ErrorAction SilentlyContinue)) {
        try {
            $reportPath = Write-UckkReport `
                -Result $Result `
                -Config $script:Config `
                -BasePath $script:AppRoot

            Set-UckkGuiResultProperty -Result $Result -Name 'reportPath' -Value $reportPath
        }
        catch {
            Add-UckkGuiArtifactWarning -Result $Result -Message "Le rapport n a pas pu être écrit : $($_.Exception.Message)"
        }
    }

    return $Result
}

function Invoke-UckkGuiAction {
    param([object]$Action)

    $confirmed = Confirm-UckkGuiAction -Action $Action
    if (-not $confirmed) {
        return New-UckkGuiActionResult -Success $false -Status 'Annulé' -Action $Action.label -Domain $Action.domain -Target $Action.target -DangerLevel $Action.dangerLevel -Mode 'annulation' -Summary 'Annulé — aucune modification n a été faite.' -NextStep 'Aucune action requise.'
    }

    $result = $null

    switch ($Action.builtinType) {
        'OpenUrl' {
            $result = Invoke-UckkGuiOpenUrl -Action $Action -ConfigPathValue $Action.builtinValue
        }

        'OpenPath' {
            $result = Invoke-UckkGuiOpenPath -Action $Action -ConfigPathValue $Action.builtinValue
        }

        'OpenLatestReport' {
            $result = Invoke-UckkGuiOpenLatestReport -Action $Action
        }

        default {
            $result = Invoke-UckkGuiDeclaredHandler -Action $Action -Confirmed:$confirmed
        }
    }

    if ($null -eq $result) {
        return $result
    }

    return Complete-UckkGuiActionArtifacts -Action $Action -Result $result
}

function Add-UckkGuiLogEntry {
    param(
        [System.Windows.Forms.TextBox]$ResultBox,
        [string]$Text
    )

    if ($null -eq $ResultBox) {
        return
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $separator = ('=' * 72)

    $entry = @(
        $separator
        "[$timestamp]"
        $Text
    ) -join [Environment]::NewLine

    if ([string]::IsNullOrWhiteSpace($ResultBox.Text)) {
        $ResultBox.Text = $entry
    }
    else {
        $ResultBox.AppendText([Environment]::NewLine)
        $ResultBox.AppendText([Environment]::NewLine)
        $ResultBox.AppendText($entry)
    }

    $ResultBox.SelectionStart = $ResultBox.TextLength
    $ResultBox.ScrollToCaret()
}

function Set-UckkGuiResult {
    param(
        [object]$Result,
        [System.Windows.Forms.TextBox]$ResultBox,
        [System.Windows.Forms.Label]$StatusLabel
    )

    $script:LastResult = $Result

    if ($null -ne $Result) {
        $script:LastReportPath = Get-UckkGuiResultPropertyValue -Object $Result -Name 'reportPath' -Default $null
        $script:LastLogPath = Get-UckkGuiResultPropertyValue -Object $Result -Name 'logPath' -Default $null
    }

    $status = Get-UckkGuiResultPropertyValue -Object $Result -Name 'status' -Default 'Inconnu'
    $action = Get-UckkGuiResultPropertyValue -Object $Result -Name 'action' -Default 'Action inconnue'

    Add-UckkGuiLogEntry -ResultBox $ResultBox -Text (Convert-UckkGuiResultToText -Result $Result)
    $StatusLabel.Text = "Statut : $status — $action"
}


function New-UckkGuiActionCard {
    param(
        [object]$Action,
        [System.Windows.Forms.TextBox]$ResultBox,
        [System.Windows.Forms.Label]$StatusLabel
    )

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Width = 360
    $panel.Height = 128
    $panel.Margin = New-Object System.Windows.Forms.Padding(8)
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $title = New-Object System.Windows.Forms.Label
    $title.Text = $Action.label
    $title.Left = 10
    $title.Top = 8
    $title.Width = 330
    $title.Height = 22
    $title.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

    $description = New-Object System.Windows.Forms.Label
    $description.Text = $Action.description
    $description.Left = 10
    $description.Top = 34
    $description.Width = 330
    $description.Height = 42
    $description.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $description.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)

    $meta = New-Object System.Windows.Forms.Label
    $meta.Text = "Danger $($Action.dangerLevel) · $($Action.mode) · $($Action.target)"
    $meta.Left = 10
    $meta.Top = 78
    $meta.Width = 220
    $meta.Height = 18
    $meta.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $meta.ForeColor = [System.Drawing.Color]::FromArgb(110, 110, 110)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = 'Lancer'
    $button.Left = 244
    $button.Top = 88
    $button.Width = 96
    $button.Height = 28
    $button.Tag = $Action

    $button.Add_Click({
        param($sender, $eventArgs)

        $actionToRun = $sender.Tag
        $sender.Enabled = $false
        $previousText = $sender.Text
        $sender.Text = 'En cours'

        try {
            $StatusLabel.Text = "Statut : En cours — $($actionToRun.label)"
            [System.Windows.Forms.Application]::DoEvents()

            $result = Invoke-UckkGuiAction -Action $actionToRun
            Set-UckkGuiResult -Result $result -ResultBox $ResultBox -StatusLabel $StatusLabel
        }
        catch {
            $message = $_.Exception.Message
            $result = New-UckkGuiActionResult `
                -Success $false `
                -Status 'Échoué' `
                -Action $actionToRun.label `
                -Domain $actionToRun.domain `
                -Target $actionToRun.target `
                -DangerLevel $actionToRun.dangerLevel `
                -Mode $actionToRun.mode `
                -Summary "Erreur capturée par l'interface." `
                -Errors @($message) `
                -NextStep 'Copier ce résultat et corriger le module indiqué.'

            Set-UckkGuiResult -Result $result -ResultBox $ResultBox -StatusLabel $StatusLabel
        }
        finally {
            $sender.Text = $previousText
            $sender.Enabled = $true
        }
    })

    [void]$panel.Controls.Add($title)
    [void]$panel.Controls.Add($description)
    [void]$panel.Controls.Add($meta)
    [void]$panel.Controls.Add($button)

    return $panel
}

function New-UckkGuiTabPage {
    param(
        [string]$Name,
        [object[]]$Actions,
        [System.Windows.Forms.TextBox]$ResultBox,
        [System.Windows.Forms.Label]$StatusLabel
    )

    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = $Name

    $panel = New-Object System.Windows.Forms.FlowLayoutPanel
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.AutoScroll = $true
    $panel.WrapContents = $true
    $panel.Padding = New-Object System.Windows.Forms.Padding(8)

    foreach ($action in $Actions) {
        [void]$panel.Controls.Add((New-UckkGuiActionCard -Action $action -ResultBox $ResultBox -StatusLabel $StatusLabel))
    }

    [void]$tab.Controls.Add($panel)

    return $tab
}

function Initialize-UckkGuiEnvironment {
    Import-UckkGuiOptionalScript -Path (Get-UckkGuiPath 'app/UckkOpsConsole.State.ps1')
    Import-UckkGuiOptionalScript -Path (Get-UckkGuiPath 'app/UckkOpsConsole.Layout.ps1')
    Import-UckkGuiOptionalScript -Path (Get-UckkGuiPath 'app/UckkOpsConsole.Actions.ps1')

    $modulePaths = @(
        'lib/UckkOps.Config.psm1',
        'lib/UckkOps.Result.psm1',
        'lib/UckkOps.Report.psm1',
        'lib/UckkOps.Log.psm1',
        'lib/UckkOps.Security.psm1',
        'lib/UckkOps.Command.psm1',
        'lib/UckkOps.Path.psm1',
        'lib/UckkOps.Url.psm1',
        'lib/UckkOps.Json.psm1',
        'lib/UckkOps.ActionRegistry.psm1',
        'modules/local/UckkOps.Local.psm1',
        'modules/git/UckkOps.Git.psm1',
        'modules/server/UckkOps.Server.psm1',
        'modules/mediatheque/UckkOps.Mediatheque.psm1',
        'modules/mediatheque/UckkOps.Mediatheque.Manifest.psm1',
        'modules/mediatheque/UckkOps.Mediatheque.Moodle.psm1',
        'modules/moodle-data/UckkOps.MoodleData.psm1',
        'modules/moodle-data/UckkOps.MoodleData.Json.psm1',
        'modules/moodle-data/UckkOps.MoodleData.Apply.psm1',
        'modules/tests/UckkOps.Tests.psm1'
    )

    foreach ($relativePath in $modulePaths) {
        Import-UckkGuiOptionalModule -Path (Get-UckkGuiPath $relativePath)
    }

    $script:Config = Read-UckkGuiConfig -Path $script:ConfigPath

    $reportsDir = Resolve-UckkGuiPathFromConfig -Value (Get-UckkGuiConfigValue -Config $script:Config -Path 'paths.reportsDir' -Default './reports')
    $logsDir = Resolve-UckkGuiPathFromConfig -Value (Get-UckkGuiConfigValue -Config $script:Config -Path 'paths.logsDir' -Default './logs')

    foreach ($dir in @($reportsDir, $logsDir)) {
        if (-not (Test-Path -LiteralPath $dir)) {
            [void](New-Item -ItemType Directory -Path $dir -Force)
        }
    }
}

function Start-UckkOpsConsoleGui {
    Initialize-UckkGuiEnvironment

    [System.Windows.Forms.Application]::EnableVisualStyles()

    $appName = Get-UckkGuiConfigValue -Config $script:Config -Path 'app.name' -Default 'UCKK Ops Console'
    $appVersion = Get-UckkGuiConfigValue -Config $script:Config -Path 'app.version' -Default '0.1.0'

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$appName — $appVersion"
    $form.Width = 1220
    $form.Height = 820
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.MinimumSize = New-Object System.Drawing.Size(980, 680)

    $main = New-Object System.Windows.Forms.TableLayoutPanel
    $main.Dock = [System.Windows.Forms.DockStyle]::Fill
    $main.RowCount = 3
    $main.ColumnCount = 1
    $main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 42))) | Out-Null
    $main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 68))) | Out-Null
    $main.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 32))) | Out-Null

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = 'Statut : prêt'
    $statusLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $statusLabel.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
    $statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = [System.Windows.Forms.DockStyle]::Fill

    $resultBox = New-Object System.Windows.Forms.TextBox
    $resultBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $resultBox.Multiline = $true
    $resultBox.ReadOnly = $true
    $resultBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $resultBox.Font = New-Object System.Drawing.Font('Consolas', 10)

    $resultPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $resultPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $resultPanel.RowCount = 2
    $resultPanel.ColumnCount = 1
    $resultPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 36))) | Out-Null
    $resultPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null

    $resultToolbar = New-Object System.Windows.Forms.FlowLayoutPanel
    $resultToolbar.Dock = [System.Windows.Forms.DockStyle]::Fill
    $resultToolbar.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
    $resultToolbar.WrapContents = $false
    $resultToolbar.Padding = New-Object System.Windows.Forms.Padding(8, 4, 8, 4)

    $copyLogButton = New-Object System.Windows.Forms.Button
    $copyLogButton.Text = 'Copier le log'
    $copyLogButton.Width = 110
    $copyLogButton.Height = 26
    $copyLogButton.Add_Click({
        if (-not [string]::IsNullOrWhiteSpace($resultBox.Text)) {
            [System.Windows.Forms.Clipboard]::SetText($resultBox.Text)
            $statusLabel.Text = 'Statut : log copié'
        }
    })

    $clearLogButton = New-Object System.Windows.Forms.Button
    $clearLogButton.Text = 'Effacer le log'
    $clearLogButton.Width = 110
    $clearLogButton.Height = 26
    $clearLogButton.Add_Click({
        $resultBox.Clear()
        $statusLabel.Text = 'Statut : log effacé'
    })

    $openReportButton = New-Object System.Windows.Forms.Button
    $openReportButton.Text = 'Ouvrir rapport'
    $openReportButton.Width = 120
    $openReportButton.Height = 26
    $openReportButton.Add_Click({
        if (-not [string]::IsNullOrWhiteSpace([string]$script:LastReportPath) -and (Test-Path -LiteralPath $script:LastReportPath -PathType Leaf)) {
            Start-Process -FilePath $script:LastReportPath | Out-Null
            $statusLabel.Text = 'Statut : rapport ouvert'
        }
        else {
            $statusLabel.Text = 'Statut : aucun rapport disponible pour la dernière action'
        }
    })

    $openTechnicalLogButton = New-Object System.Windows.Forms.Button
    $openTechnicalLogButton.Text = 'Ouvrir log'
    $openTechnicalLogButton.Width = 105
    $openTechnicalLogButton.Height = 26
    $openTechnicalLogButton.Add_Click({
        if (-not [string]::IsNullOrWhiteSpace([string]$script:LastLogPath) -and (Test-Path -LiteralPath $script:LastLogPath -PathType Leaf)) {
            Start-Process -FilePath $script:LastLogPath | Out-Null
            $statusLabel.Text = 'Statut : log technique ouvert'
        }
        else {
            $statusLabel.Text = 'Statut : aucun log technique disponible pour la dernière action'
        }
    })

    [void]$resultToolbar.Controls.Add($copyLogButton)
    [void]$resultToolbar.Controls.Add($clearLogButton)
    [void]$resultToolbar.Controls.Add($openReportButton)
    [void]$resultToolbar.Controls.Add($openTechnicalLogButton)

    [void]$resultPanel.Controls.Add($resultToolbar, 0, 0)
    [void]$resultPanel.Controls.Add($resultBox, 0, 1)

    $actions = Get-UckkGuiActions

    $tabOrder = @(
        'Accueil',
        'Local',
        'Git',
        'Serveur',
        'Médiathèque',
        'Données Moodle',
        'Tests',
        'Historique',
        'Récupération'
    )

    foreach ($tabName in $tabOrder) {
        $tabActions = @($actions | Where-Object { $_.tab -eq $tabName })
        [void]$tabs.TabPages.Add((New-UckkGuiTabPage -Name $tabName -Actions $tabActions -ResultBox $resultBox -StatusLabel $statusLabel))
    }

    Add-UckkGuiLoadMessage ("Actions GUI disponibles : " + (Get-UckkGuiValueCount -Value $actions))

    foreach ($tabName in $tabOrder) {
        $tabActions = @($actions | Where-Object { $_.tab -eq $tabName })
        Add-UckkGuiLoadMessage ("Onglet " + $tabName + " : " + (Get-UckkGuiValueCount -Value $tabActions) + " action(s)")
    }

    [void]$main.Controls.Add($statusLabel, 0, 0)
    [void]$main.Controls.Add($tabs, 0, 1)
    [void]$main.Controls.Add($resultPanel, 0, 2)

    [void]$form.Controls.Add($main)

    $loadMessageLines = @()

    foreach ($loadMessage in @($script:LoadMessages)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$loadMessage)) {
            $loadMessageLines += ("- " + [string]$loadMessage)
        }
    }

    if ((Get-UckkGuiValueCount -Value $loadMessageLines) -eq 0) {
        $loadMessageLines += "- Aucun message de chargement."
    }

    $configSummaryLines = @(
        "Configuration : $script:ConfigPath",
        "App root : $script:AppRoot",
        "",
        "Messages de chargement :"
    )

    $configSummaryLines += $loadMessageLines
    $configSummary = $configSummaryLines -join [Environment]::NewLine

    $initialResult = New-UckkGuiActionResult `
        -Success $true `
        -Status 'Prêt' `
        -Action 'Démarrage de l interface' `
        -Domain 'configuration' `
        -Target 'aucune cible modifiée' `
        -DangerLevel 0 `
        -Mode 'vérification' `
        -Summary 'Interface chargée. Les actions sans handler sont visibles mais ne modifieront rien.' `
        -Warnings @('Certains handlers peuvent ne pas encore être codés.') `
        -NextStep 'Choisir une action dans un onglet.' `
        -Data @{ load = $configSummary }

    Add-UckkGuiLogEntry -ResultBox $resultBox -Text ((Convert-UckkGuiResultToText -Result $initialResult) + [Environment]::NewLine + [Environment]::NewLine + $configSummary)

    [void][System.Windows.Forms.Application]::Run($form)
}

function Start-UckkOpsConsole {
    [CmdletBinding()]
    param(
        [string]$AppRoot,
        [string]$ConfigPath
    )

    if (-not [string]::IsNullOrWhiteSpace($AppRoot)) {
        $script:AppRoot = $AppRoot
        $script:GuiRoot = Join-Path $script:AppRoot 'app'
    }

    if (-not [string]::IsNullOrWhiteSpace($ConfigPath)) {
        $script:ConfigPath = $ConfigPath
    }

    Start-UckkOpsConsoleGui
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Start-UckkOpsConsoleGui
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "L application n a pas pu démarrer.`n`nCause probable : $($_.Exception.Message)`n`nProchaine étape : vérifier la configuration et les modules.",
            'UCKK Ops Console — erreur de démarrage',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null

        throw
    }
}


