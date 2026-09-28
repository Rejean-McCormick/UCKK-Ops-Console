#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Central action registry for UCKK Ops Console.

.DESCRIPTION
  This module declares all UI-exposed actions.

  Each action has stable metadata:
    id
    label
    description
    domain
    target
    dangerLevel
    mode
    requiresConfirmation
    requiresSimulation
    requiresBackup
    producesReport
    producesLog
    handler

  The UI should read this registry instead of inventing button labels or action
  behavior directly in the GUI.

.RULES
  - No dangerous action without a danger level.
  - No server/database/recovery action without the required flags.
  - No vague labels.
  - No legacy or recovery action in normal tabs.
  - Handlers are named here but implemented in their domain modules.
#>

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function Get-UckkActionRegistryListCount {
    [CmdletBinding()]
    param(
        [Parameter()]
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
# Action metadata factory
# ---------------------------------------------------------------------------

function New-UckkActionDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Id,

        [Parameter(Mandatory = $true)]
        [string] $Label,

        [Parameter(Mandatory = $true)]
        [string] $Description,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "configuration",
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery"
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
        [bool] $RequiresConfirmation,

        [Parameter(Mandatory = $true)]
        [bool] $RequiresSimulation,

        [Parameter(Mandatory = $true)]
        [bool] $RequiresBackup,

        [Parameter(Mandatory = $true)]
        [bool] $ProducesReport,

        [Parameter(Mandatory = $true)]
        [bool] $ProducesLog,

        [Parameter(Mandatory = $true)]
        [string] $Handler,

        [Parameter(Mandatory = $false)]
        [string[]] $Tabs = @(),

        [Parameter(Mandatory = $false)]
        [string] $ConfirmationMessage = "",

        [Parameter(Mandatory = $false)]
        [string] $Contract = "",

        [Parameter(Mandatory = $false)]
        [int] $SortOrder = 1000,

        [Parameter(Mandatory = $false)]
        [bool] $Visible = $true,

        [Parameter(Mandatory = $false)]
        [string[]] $RequiresBeforeRun = @()
    )

    return [pscustomobject]@{
        id                   = $Id
        label                = $Label
        description          = $Description
        domain               = $Domain
        target               = $Target
        dangerLevel          = $DangerLevel
        mode                 = $Mode
        requiresConfirmation = $RequiresConfirmation
        requiresSimulation   = $RequiresSimulation
        requiresBackup       = $RequiresBackup
        producesReport       = $ProducesReport
        producesLog          = $ProducesLog
        handler              = $Handler
        tabs                 = @($Tabs)
        confirmationMessage  = $ConfirmationMessage
        contract             = $Contract
        sortOrder            = $SortOrder
        visible              = $Visible
        requiresBeforeRun    = @($RequiresBeforeRun)
    }
}

function New-UckkActionFromMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $Map
    )

    return New-UckkActionDefinition @Map
}

# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

function Get-UckkActionRegistry {
    $nl = [Environment]::NewLine

    $actions = @(
        # -------------------------------------------------------------------
        # Accueil — workflows principaux
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "home.local_ready"
            Label = "Préparer local et ouvrir Moodle"
            Description = "Exécute la chaîne locale complète : vérifier la configuration et les chemins, synchroniser la source, appliquer l upgrade Moodle local, purger les caches, démarrer Moodle puis ouvrir UCKK."
            Domain = "local"
            Target = "Moodle local + base locale"
            DangerLevel = 3
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkOpsHomeLocalReady"
            Tabs = @("Accueil")
            ConfirmationMessage = "Cette préparation peut exécuter admin/cli/upgrade.php et modifier la base Moodle locale. Elle ne touche pas au serveur. Continuer ?"
            Contract = "docs/03_INTERFACE_ACCUEIL.md"
            SortOrder = 10
        }

        New-UckkActionFromMap -Map @{
            Id = "home.publish_to_uckk"
            Label = "Publier jusqu'à uckk.org"
            Description = "Exécute la chaîne complète vers le public : préparation locale, vérifications Git, envoi Git, publication serveur, vérification de uckk.org et ouverture du site public."
            Domain = "server"
            Target = "uckk.org"
            DangerLevel = 5
            Mode = "publication"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkOpsHomePublishToUckk"
            Tabs = @("Accueil")
            ConfirmationMessage = "Cette action va pousser le travail jusqu'à uckk.org." + $nl + "Elle enchaîne des actions locales, Git et serveur." + $nl + "La séquence s'arrête automatiquement à la première erreur." + $nl + "Continuer ?"
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 20
        }

        # -------------------------------------------------------------------
        # Configuration
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "configuration.verify"
            Label = "Vérifier la configuration"
            Description = "Vérifie que le fichier de configuration existe, est lisible et contient les valeurs nécessaires."
            Domain = "configuration"
            Target = "configuration"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkConfigAction"
            Tabs = @("Local", "Serveur")
            Contract = "docs/05_CONFIGURATION_ET_CHEMINS.md"
            SortOrder = 100
        }

        # -------------------------------------------------------------------
        # Local
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "local.verify.paths"
            Label = "Vérifier les chemins locaux"
            Description = "Vérifie les chemins locaux configurés sans modifier Moodle."
            Domain = "local"
            Target = "local"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkLocalPaths"
            Tabs = @("Local")
            Contract = "docs/05_CONFIGURATION_ET_CHEMINS.md"
            SortOrder = 200
        }

        New-UckkActionFromMap -Map @{
            Id = "local.sync.source_to_runtime"
            Label = "Synchroniser source vers Moodle local"
            Description = "Copie les fichiers nécessaires depuis la source locale vers le dossier exécuté par Moodle local."
            Domain = "local"
            Target = "dossier exécuté par Moodle local"
            DangerLevel = 2
            Mode = "application"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Sync-UckkSourceToLocalMoodle"
            Tabs = @("Local")
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 210
        }


        New-UckkActionFromMap -Map @{
            Id = "local.moodle_diagnostic"
            Label = "Diagnostiquer Moodle local"
            Description = "Vérifie racine Moodle / webroot, PHP CLI, scripts admin/cli, version, release, branche et maturité. Signale si --allow-unstable sera requis."
            Domain = "local"
            Target = "Moodle local"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkLocalMoodleCli"
            Tabs = @("Local", "Tests")
            Contract = "docs/14_DIAGNOSTIC_LOCAL_VERBOSE.md"
            SortOrder = 212
        }

        New-UckkActionFromMap -Map @{
            Id = "local.moodle_upgrade"
            Label = "Mettre à jour Moodle local"
            Description = "Exécute l upgrade Moodle local. Si version.php indique Alpha/Beta/RC, ajoute --allow-unstable uniquement après confirmation."
            Domain = "local"
            Target = "base Moodle locale"
            DangerLevel = 3
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkLocalMoodleUpgrade"
            Tabs = @("Local")
            ConfirmationMessage = "Cette action peut modifier la base Moodle locale. Si Moodle est Alpha/Beta/RC, --allow-unstable sera ajouté automatiquement pour cette exécution. Continuer ?"
            Contract = "docs/13_SWITCHER_MULTI_FACADES.md"
            SortOrder = 215
        }

        New-UckkActionFromMap -Map @{
            Id = "local.purge_caches"
            Label = "Purger les caches locaux"
            Description = "Vide les caches Moodle locaux afin que Moodle relise les changements."
            Domain = "local"
            Target = "Moodle local"
            DangerLevel = 2
            Mode = "application"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Clear-UckkLocalMoodleCaches"
            Tabs = @("Local")
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 220
        }

        New-UckkActionFromMap -Map @{
            Id = "local.start_moodle"
            Label = "Démarrer Moodle local"
            Description = "Démarre Moodle local si le mode de lancement local est configuré."
            Domain = "local"
            Target = "Moodle local"
            DangerLevel = 2
            Mode = "application"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Start-UckkLocalMoodle"
            Tabs = @("Local")
            Contract = "docs/03_INTERFACE_ACCUEIL.md"
            SortOrder = 230
        }

        New-UckkActionFromMap -Map @{
            Id = "local.open_moodle"
            Label = "Ouvrir Moodle local"
            Description = "Démarre Moodle local si nécessaire, puis ouvre Moodle local dans le navigateur."
            Domain = "local"
            Target = "Moodle local"
            DangerLevel = 2
            Mode = "application"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Open-UckkLocalMoodle"
            Tabs = @("Local")
            Contract = "docs/03_INTERFACE_ACCUEIL.md"
            SortOrder = 240
        }

        New-UckkActionFromMap -Map @{
            Id = "local.open_uckk"
            Label = "Ouvrir UCKK"
            Description = "Ouvre Moodle local avec le thème/session UCKK."
            Domain = "local"
            Target = "façade UCKK"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Open-UckkLocalUckkFacade"
            Tabs = @("Local")
            Contract = "docs/13_SWITCHER_MULTI_FACADES.md"
            SortOrder = 242
        }

        New-UckkActionFromMap -Map @{
            Id = "local.open_ucc"
            Label = "Ouvrir UCC"
            Description = "Ouvre Moodle local avec le thème/session Univers-Cité Catho."
            Domain = "local"
            Target = "façade UCC"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Open-UckkLocalUccFacade"
            Tabs = @("Local")
            Contract = "docs/13_SWITCHER_MULTI_FACADES.md"
            SortOrder = 243
        }

        New-UckkActionFromMap -Map @{
            Id = "local.open_math"
            Label = "Ouvrir Math"
            Description = "Ouvre Moodle local avec le thème/session Univers-Cité des mathématiques."
            Domain = "local"
            Target = "façade Math"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Open-UckkLocalMathFacade"
            Tabs = @("Local")
            Contract = "docs/13_SWITCHER_MULTI_FACADES.md"
            SortOrder = 244
        }

        New-UckkActionFromMap -Map @{
            Id = "local.test_facades"
            Label = "Tester switcher UCKK / UCC / Math"
            Description = "Teste les trois thèmes par URL, les pages publiques principales et un marqueur d identité pour chaque façade."
            Domain = "local"
            Target = "façades publiques locales"
            DangerLevel = 1
            Mode = "test"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkLocalPublicFacades"
            Tabs = @("Local", "Tests")
            Contract = "docs/13_SWITCHER_MULTI_FACADES.md"
            SortOrder = 248
        }

        New-UckkActionFromMap -Map @{
            Id = "local.test_pages"
            Label = "Tester les pages locales"
            Description = "Teste les pages locales importantes sans modifier les données."
            Domain = "local"
            Target = "Moodle local"
            DangerLevel = 1
            Mode = "test"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkLocalPages"
            Tabs = @("Local", "Tests")
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 250
        }

        New-UckkActionFromMap -Map @{
            Id = "local.open_source_folder"
            Label = "Ouvrir dossier source"
            Description = "Ouvre le dossier source local."
            Domain = "local"
            Target = "source locale"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkLocalSourceFolder"
            Tabs = @("Local", "Git")
            Contract = "docs/04_INTERFACE_ONGLETS_SPECIALISES.md"
            SortOrder = 260
        }

        New-UckkActionFromMap -Map @{
            Id = "local.open_runtime_folder"
            Label = "Ouvrir dossier Moodle local"
            Description = "Ouvre le dossier exécuté par Moodle local."
            Domain = "local"
            Target = "dossier exécuté par Moodle local"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkLocalMoodleRuntimeFolder"
            Tabs = @("Local")
            Contract = "docs/04_INTERFACE_ONGLETS_SPECIALISES.md"
            SortOrder = 270
        }

        # -------------------------------------------------------------------
        # Git
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "git.verify"
            Label = "Vérifier Git"
            Description = "Affiche l'état Git : branche, fichiers modifiés, ajoutés ou supprimés."
            Domain = "git"
            Target = "Git"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Get-UckkGitStatus"
            Tabs = @("Git")
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 300
        }

        New-UckkActionFromMap -Map @{
            Id = "git.diff"
            Label = "Afficher les différences Git"
            Description = "Affiche le détail des changements Git avant commit ou publication."
            Domain = "git"
            Target = "Git"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Get-UckkGitDiff"
            Tabs = @("Git")
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 310
        }

        New-UckkActionFromMap -Map @{
            Id = "git.sensitive_files"
            Label = "Vérifier les fichiers sensibles"
            Description = "Recherche des fichiers ou valeurs sensibles avant commit ou push."
            Domain = "git"
            Target = "Git"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkGitSensitiveFiles"
            Tabs = @("Git")
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 320
        }

        New-UckkActionFromMap -Map @{
            Id = "git.commit"
            Label = "Créer un commit Git"
            Description = "Enregistre les changements dans l'historique Git après vérification."
            Domain = "git"
            Target = "Git"
            DangerLevel = 3
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "New-UckkGitCommit"
            Tabs = @("Git")
            ConfirmationMessage = "Cette action enregistre des changements dans l'historique Git." + $nl + "Vérifie qu'aucun secret n'est inclus." + $nl + "Continuer ?"
            Contract = "docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md"
            SortOrder = 330
            RequiresBeforeRun = @("git.sensitive_files")
        }

        New-UckkActionFromMap -Map @{
            Id = "git.push"
            Label = "Envoyer les changements vers Git"
            Description = "Envoie les commits vers le dépôt distant."
            Domain = "git"
            Target = "Git distant"
            DangerLevel = 3
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Push-UckkGitChanges"
            Tabs = @("Git")
            ConfirmationMessage = "Cette action envoie des changements vers Git." + $nl + "Vérifie qu'aucun secret n'est inclus." + $nl + "Continuer ?"
            Contract = "docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md"
            SortOrder = 340
            RequiresBeforeRun = @("git.sensitive_files")
        }

        New-UckkActionFromMap -Map @{
            Id = "git.pull"
            Label = "Récupérer depuis Git"
            Description = "Récupère les changements depuis le dépôt distant vers la source locale."
            Domain = "git"
            Target = "source locale"
            DangerLevel = 3
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Pull-UckkGitChanges"
            Tabs = @("Git")
            ConfirmationMessage = "Cette action peut modifier les fichiers locaux en récupérant des changements depuis Git. Continuer ?"
            Contract = "docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md"
            SortOrder = 350
        }

        # -------------------------------------------------------------------
        # Server
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "server.test_connection"
            Label = "Tester connexion serveur"
            Description = "Teste la connexion SSH au serveur sans le modifier."
            Domain = "server"
            Target = "serveur"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkServerConnection"
            Tabs = @("Serveur")
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 400
        }

        New-UckkActionFromMap -Map @{
            Id = "server.status"
            Label = "Vérifier état serveur"
            Description = "Lit l'état serveur sans le modifier."
            Domain = "server"
            Target = "serveur"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkServerStatus"
            Tabs = @("Serveur")
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 410
        }

        New-UckkActionFromMap -Map @{
            Id = "server.pull_code"
            Label = "Récupérer dernier code sur serveur"
            Description = "Met à jour la source serveur depuis Git."
            Domain = "server"
            Target = "source serveur"
            DangerLevel = 5
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Update-UckkServerSourceFromGit"
            Tabs = @("Serveur")
            ConfirmationMessage = "Cette action modifie le code source sur le serveur. Continuer ?"
            Contract = "docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md"
            SortOrder = 420
        }

        New-UckkActionFromMap -Map @{
            Id = "server.sync_runtime"
            Label = "Synchroniser source serveur vers Moodle serveur"
            Description = "Copie la source serveur vers le dossier exécuté par Moodle serveur."
            Domain = "server"
            Target = "dossier exécuté par Moodle serveur"
            DangerLevel = 5
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Sync-UckkServerSourceToMoodleRuntime"
            Tabs = @("Serveur")
            ConfirmationMessage = "Cette action modifie le code exécuté par uckk.org. Continuer ?"
            Contract = "docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md"
            SortOrder = 430
        }

        New-UckkActionFromMap -Map @{
            Id = "server.moodle_upgrade"
            Label = "Mettre à jour Moodle serveur"
            Description = "Lance la mise à jour Moodle serveur si nécessaire."
            Domain = "server"
            Target = "base Moodle serveur"
            DangerLevel = 6
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkServerMoodleUpgrade"
            Tabs = @("Serveur")
            ConfirmationMessage = "Cette action peut modifier la base Moodle serveur. Continuer ?"
            Contract = "docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md"
            SortOrder = 440
        }

        New-UckkActionFromMap -Map @{
            Id = "server.purge_caches"
            Label = "Purger les caches serveur"
            Description = "Vide les caches Moodle serveur."
            Domain = "server"
            Target = "Moodle serveur"
            DangerLevel = 5
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkServerCachePurge"
            Tabs = @("Serveur")
            ConfirmationMessage = "Cette action modifie l'état temporaire de Moodle serveur. Continuer ?"
            Contract = "docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md"
            SortOrder = 450
        }

        New-UckkActionFromMap -Map @{
            Id = "server.reload_php_fpm"
            Label = "Recharger PHP-FPM"
            Description = "Recharge le service PHP-FPM du serveur sans redémarrer la machine."
            Domain = "server"
            Target = "service PHP-FPM serveur"
            DangerLevel = 5
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Restart-UckkServerPhpFpm"
            Tabs = @("Serveur")
            ConfirmationMessage = "Cette action recharge le service PHP du serveur. Continuer ?"
            Contract = "docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md"
            SortOrder = 460
        }

        New-UckkActionFromMap -Map @{
            Id = "server.verify_public_site"
            Label = "Vérifier uckk.org — UCKK / UCC / Math"
            Description = "Teste les pages publiques et confirme l identité des trois façades par thème URL sans modifier le serveur."
            Domain = "server"
            Target = "uckk.org"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkPublicSite"
            Tabs = @("Serveur", "Tests")
            Contract = "docs/13_SWITCHER_MULTI_FACADES.md"
            SortOrder = 470
        }

        New-UckkActionFromMap -Map @{
            Id = "server.open_public_site"
            Label = "Ouvrir uckk.org"
            Description = "Ouvre le site public dans le navigateur."
            Domain = "server"
            Target = "uckk.org"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkPublicSite"
            Tabs = @("Serveur")
            Contract = "docs/04_INTERFACE_ONGLETS_SPECIALISES.md"
            SortOrder = 480
        }

        New-UckkActionFromMap -Map @{
            Id = "server.publish_chain"
            Label = "Publier sur serveur"
            Description = "Met à jour uckk.org à partir du code Git validé, puis vérifie le site."
            Domain = "server"
            Target = "uckk.org"
            DangerLevel = 5
            Mode = "publication"
            RequiresConfirmation = $true
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Publish-UckkServer"
            Tabs = @("Serveur")
            ConfirmationMessage = "Cette action va mettre à jour uckk.org à partir du code Git validé." + $nl + "Elle peut modifier le code serveur, les caches Moodle et possiblement la base Moodle." + $nl + "Continuer ?"
            Contract = "docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md"
            SortOrder = 490
            RequiresBeforeRun = @("git.verify")
        }

        # -------------------------------------------------------------------
        # Médiathèque
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.open_manifest"
            Label = "Ouvrir manifeste Médiathèque"
            Description = "Ouvre le manifeste Médiathèque configuré."
            Domain = "mediatheque"
            Target = "manifeste Médiathèque"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkMediathequeManifest"
            Tabs = @("Médiathèque")
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 500
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.validate_manifest"
            Label = "Vérifier manifeste Médiathèque"
            Description = "Valide le manifeste Médiathèque avant simulation ou application."
            Domain = "mediatheque"
            Target = "manifeste Médiathèque"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkMediathequeManifest"
            Tabs = @("Médiathèque")
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 510
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.simulate.local"
            Label = "Simulation Médiathèque locale"
            Description = "Montre ce qui serait écrit dans la base Moodle locale, sans modifier les données."
            Domain = "mediatheque"
            Target = "base Moodle locale"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMediathequeLocalSimulation"
            Tabs = @("Médiathèque")
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 520
            RequiresBeforeRun = @("mediatheque.validate_manifest")
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.apply.local"
            Label = "Appliquer Médiathèque localement"
            Description = "Écrit réellement les références du manifeste dans la base Moodle locale."
            Domain = "mediatheque"
            Target = "base Moodle locale"
            DangerLevel = 4
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMediathequeLocalApply"
            Tabs = @("Médiathèque")
            ConfirmationMessage = "Cette action écrit dans la base Moodle locale. Continuer ?"
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 530
            RequiresBeforeRun = @("mediatheque.simulate.local")
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.verify.local"
            Label = "Vérifier Médiathèque locale"
            Description = "Vérifie la page, le service et les données Médiathèque locales."
            Domain = "mediatheque"
            Target = "Médiathèque locale"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkMediathequeLocal"
            Tabs = @("Médiathèque", "Tests")
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 540
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.simulate.server"
            Label = "Simulation Médiathèque serveur"
            Description = "Montre ce qui serait écrit dans la base Moodle serveur, sans modifier les données."
            Domain = "mediatheque"
            Target = "base Moodle serveur"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMediathequeServerSimulation"
            Tabs = @("Médiathèque")
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 550
            RequiresBeforeRun = @("mediatheque.validate_manifest")
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.apply.server"
            Label = "Appliquer Médiathèque serveur"
            Description = "Écrit réellement les références du manifeste dans la base Moodle serveur."
            Domain = "mediatheque"
            Target = "base Moodle serveur"
            DangerLevel = 6
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMediathequeServerApply"
            Tabs = @("Médiathèque")
            ConfirmationMessage = "Cette action écrit dans la base Moodle serveur. Continuer ?"
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 560
            RequiresBeforeRun = @("mediatheque.simulate.server")
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.verify.server"
            Label = "Vérifier Médiathèque serveur"
            Description = "Vérifie la page, le service et les données Médiathèque serveur."
            Domain = "mediatheque"
            Target = "Médiathèque serveur"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkMediathequeServer"
            Tabs = @("Médiathèque", "Tests")
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 570
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.open.local"
            Label = "Ouvrir Médiathèque locale"
            Description = "Ouvre la Médiathèque locale dans le navigateur."
            Domain = "mediatheque"
            Target = "Médiathèque locale"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkMediathequeLocal"
            Tabs = @("Médiathèque")
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 580
        }

        New-UckkActionFromMap -Map @{
            Id = "mediatheque.open.server"
            Label = "Ouvrir Médiathèque serveur"
            Description = "Ouvre la Médiathèque serveur dans le navigateur."
            Domain = "mediatheque"
            Target = "Médiathèque serveur"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkMediathequeServer"
            Tabs = @("Médiathèque", "Serveur")
            Contract = "docs/08_MEDIATHEQUE_CONTRAT.md"
            SortOrder = 590
        }

        # -------------------------------------------------------------------
        # Données Moodle
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.validate_json"
            Label = "Vérifier fichiers JSON Moodle"
            Description = "Valide les fichiers JSON qui décrivent les Données Moodle."
            Domain = "moodle-data"
            Target = "fichiers JSON Moodle"
            DangerLevel = 1
            Mode = "vérification"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkMoodleDataJson"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 600
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.categories.simulate.local"
            Label = "Simulation catégories locales"
            Description = "Montre ce qui serait écrit pour les catégories dans la base Moodle locale."
            Domain = "moodle-data"
            Target = "base Moodle locale"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataLocalCategoriesSimulation"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 610
            RequiresBeforeRun = @("moodle_data.validate_json")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.categories.apply.local"
            Label = "Appliquer catégories localement"
            Description = "Écrit réellement les catégories dans la base Moodle locale."
            Domain = "moodle-data"
            Target = "base Moodle locale"
            DangerLevel = 4
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataLocalCategoriesApply"
            Tabs = @("Données Moodle")
            ConfirmationMessage = "Cette action écrit dans la base Moodle locale. Continuer ?"
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 620
            RequiresBeforeRun = @("moodle_data.categories.simulate.local")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.categories.simulate.server"
            Label = "Simulation catégories serveur"
            Description = "Montre ce qui serait écrit pour les catégories dans la base Moodle serveur."
            Domain = "moodle-data"
            Target = "base Moodle serveur"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataServerCategoriesSimulation"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 630
            RequiresBeforeRun = @("moodle_data.validate_json")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.categories.apply.server"
            Label = "Appliquer catégories serveur"
            Description = "Écrit réellement les catégories dans la base Moodle serveur."
            Domain = "moodle-data"
            Target = "base Moodle serveur"
            DangerLevel = 6
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataServerCategoriesApply"
            Tabs = @("Données Moodle")
            ConfirmationMessage = "Cette action écrit dans la base Moodle serveur. Continuer ?"
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 640
            RequiresBeforeRun = @("moodle_data.categories.simulate.server")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.courses.simulate.local"
            Label = "Simulation cours locaux"
            Description = "Montre ce qui serait écrit pour les cours dans la base Moodle locale."
            Domain = "moodle-data"
            Target = "base Moodle locale"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataLocalCoursesSimulation"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 650
            RequiresBeforeRun = @("moodle_data.validate_json")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.courses.apply.local"
            Label = "Appliquer cours localement"
            Description = "Écrit réellement les cours dans la base Moodle locale."
            Domain = "moodle-data"
            Target = "base Moodle locale"
            DangerLevel = 4
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataLocalCoursesApply"
            Tabs = @("Données Moodle")
            ConfirmationMessage = "Cette action écrit dans la base Moodle locale. Continuer ?"
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 660
            RequiresBeforeRun = @("moodle_data.courses.simulate.local")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.courses.simulate.server"
            Label = "Simulation cours serveur"
            Description = "Montre ce qui serait écrit pour les cours dans la base Moodle serveur."
            Domain = "moodle-data"
            Target = "base Moodle serveur"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataServerCoursesSimulation"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 670
            RequiresBeforeRun = @("moodle_data.validate_json")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.courses.apply.server"
            Label = "Appliquer cours serveur"
            Description = "Écrit réellement les cours dans la base Moodle serveur."
            Domain = "moodle-data"
            Target = "base Moodle serveur"
            DangerLevel = 6
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataServerCoursesApply"
            Tabs = @("Données Moodle")
            ConfirmationMessage = "Cette action écrit dans la base Moodle serveur. Continuer ?"
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 680
            RequiresBeforeRun = @("moodle_data.courses.simulate.server")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.programs.simulate.local"
            Label = "Simulation programmes locaux"
            Description = "Montre ce qui serait écrit pour les programmes dans la base Moodle locale."
            Domain = "moodle-data"
            Target = "base Moodle locale"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataLocalProgramsSimulation"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 690
            RequiresBeforeRun = @("moodle_data.validate_json")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.programs.apply.local"
            Label = "Appliquer programmes localement"
            Description = "Écrit réellement les programmes dans la base Moodle locale."
            Domain = "moodle-data"
            Target = "base Moodle locale"
            DangerLevel = 4
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataLocalProgramsApply"
            Tabs = @("Données Moodle")
            ConfirmationMessage = "Cette action écrit dans la base Moodle locale. Continuer ?"
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 700
            RequiresBeforeRun = @("moodle_data.programs.simulate.local")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.programs.simulate.server"
            Label = "Simulation programmes serveur"
            Description = "Montre ce qui serait écrit pour les programmes dans la base Moodle serveur."
            Domain = "moodle-data"
            Target = "base Moodle serveur"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataServerProgramsSimulation"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 710
            RequiresBeforeRun = @("moodle_data.validate_json")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.programs.apply.server"
            Label = "Appliquer programmes serveur"
            Description = "Écrit réellement les programmes dans la base Moodle serveur."
            Domain = "moodle-data"
            Target = "base Moodle serveur"
            DangerLevel = 6
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataServerProgramsApply"
            Tabs = @("Données Moodle")
            ConfirmationMessage = "Cette action écrit dans la base Moodle serveur. Continuer ?"
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 720
            RequiresBeforeRun = @("moodle_data.programs.simulate.server")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.pathways.simulate.local"
            Label = "Simulation parcours locaux"
            Description = "Montre ce qui serait écrit pour les parcours dans la base Moodle locale."
            Domain = "moodle-data"
            Target = "base Moodle locale"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataLocalPathwaysSimulation"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 730
            RequiresBeforeRun = @("moodle_data.validate_json")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.pathways.apply.local"
            Label = "Appliquer parcours localement"
            Description = "Écrit réellement les parcours dans la base Moodle locale."
            Domain = "moodle-data"
            Target = "base Moodle locale"
            DangerLevel = 4
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataLocalPathwaysApply"
            Tabs = @("Données Moodle")
            ConfirmationMessage = "Cette action écrit dans la base Moodle locale. Continuer ?"
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 740
            RequiresBeforeRun = @("moodle_data.pathways.simulate.local")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.pathways.simulate.server"
            Label = "Simulation parcours serveur"
            Description = "Montre ce qui serait écrit pour les parcours dans la base Moodle serveur."
            Domain = "moodle-data"
            Target = "base Moodle serveur"
            DangerLevel = 1
            Mode = "simulation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataServerPathwaysSimulation"
            Tabs = @("Données Moodle")
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 750
            RequiresBeforeRun = @("moodle_data.validate_json")
        }

        New-UckkActionFromMap -Map @{
            Id = "moodle_data.pathways.apply.server"
            Label = "Appliquer parcours serveur"
            Description = "Écrit réellement les parcours dans la base Moodle serveur."
            Domain = "moodle-data"
            Target = "base Moodle serveur"
            DangerLevel = 6
            Mode = "application"
            RequiresConfirmation = $true
            RequiresSimulation = $true
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Invoke-UckkMoodleDataServerPathwaysApply"
            Tabs = @("Données Moodle")
            ConfirmationMessage = "Cette action écrit dans la base Moodle serveur. Continuer ?"
            Contract = "docs/09_DONNEES_MOODLE_CONTRAT.md"
            SortOrder = 760
            RequiresBeforeRun = @("moodle_data.pathways.simulate.server")
        }

        # -------------------------------------------------------------------
        # Tests
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "tests.local_pages"
            Label = "Tester pages locales"
            Description = "Teste les pages locales sans modifier les données."
            Domain = "tests"
            Target = "Moodle local"
            DangerLevel = 1
            Mode = "test"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkLocalPages"
            Tabs = @("Tests")
            Contract = "docs/04_INTERFACE_ONGLETS_SPECIALISES.md"
            SortOrder = 800
        }

        New-UckkActionFromMap -Map @{
            Id = "tests.server_pages"
            Label = "Tester pages serveur"
            Description = "Teste les pages serveur sans modifier uckk.org."
            Domain = "tests"
            Target = "uckk.org"
            DangerLevel = 1
            Mode = "test"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkServerPages"
            Tabs = @("Tests")
            Contract = "docs/04_INTERFACE_ONGLETS_SPECIALISES.md"
            SortOrder = 810
        }

        New-UckkActionFromMap -Map @{
            Id = "tests.course_index.local"
            Label = "Tester index des cours local"
            Description = "Teste l'index des cours local."
            Domain = "tests"
            Target = "index des cours local"
            DangerLevel = 1
            Mode = "test"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkLocalCourseIndex"
            Tabs = @("Tests")
            Contract = "docs/04_INTERFACE_ONGLETS_SPECIALISES.md"
            SortOrder = 820
        }

        New-UckkActionFromMap -Map @{
            Id = "tests.course_index.server"
            Label = "Tester index des cours serveur"
            Description = "Teste l'index des cours serveur."
            Domain = "tests"
            Target = "index des cours serveur"
            DangerLevel = 1
            Mode = "test"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $true
            ProducesLog = $true
            Handler = "Test-UckkServerCourseIndex"
            Tabs = @("Tests")
            Contract = "docs/04_INTERFACE_ONGLETS_SPECIALISES.md"
            SortOrder = 830
        }

        # -------------------------------------------------------------------
        # History
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "history.open_latest_report"
            Label = "Ouvrir le dernier rapport"
            Description = "Ouvre le rapport le plus récent produit par l'application."
            Domain = "history"
            Target = "rapports"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkLatestReport"
            Tabs = @("Historique")
            Contract = "docs/10_RAPPORTS_LOGS_ERREURS.md"
            SortOrder = 900
        }

        New-UckkActionFromMap -Map @{
            Id = "history.open_reports_folder"
            Label = "Ouvrir dossier rapports"
            Description = "Ouvre le dossier des rapports."
            Domain = "history"
            Target = "rapports"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkReportsFolder"
            Tabs = @("Historique")
            Contract = "docs/10_RAPPORTS_LOGS_ERREURS.md"
            SortOrder = 910
        }

        New-UckkActionFromMap -Map @{
            Id = "history.open_logs_folder"
            Label = "Ouvrir dossier logs"
            Description = "Ouvre le dossier des logs techniques."
            Domain = "history"
            Target = "logs"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkLogsFolder"
            Tabs = @("Historique")
            Contract = "docs/10_RAPPORTS_LOGS_ERREURS.md"
            SortOrder = 920
        }

        # -------------------------------------------------------------------
        # Recovery navigation only
        # -------------------------------------------------------------------

        New-UckkActionFromMap -Map @{
            Id = "recovery.open_legacy_folder"
            Label = "Ouvrir dossier legacy"
            Description = "Ouvre le dossier legacy sans lancer d'ancien outil."
            Domain = "recovery"
            Target = "legacy"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkLegacyFolder"
            Tabs = @("Récupération")
            Contract = "docs/11_LEGACY_ET_RECOVERY.md"
            SortOrder = 1000
        }

        New-UckkActionFromMap -Map @{
            Id = "recovery.open_recovery_folder"
            Label = "Ouvrir dossier recovery"
            Description = "Ouvre le dossier recovery sans lancer de récupération."
            Domain = "recovery"
            Target = "recovery"
            DangerLevel = 0
            Mode = "navigation"
            RequiresConfirmation = $false
            RequiresSimulation = $false
            RequiresBackup = $false
            ProducesReport = $false
            ProducesLog = $false
            Handler = "Open-UckkRecoveryFolder"
            Tabs = @("Récupération")
            Contract = "docs/11_LEGACY_ET_RECOVERY.md"
            SortOrder = 1010
        }
    )

    return @($actions | Sort-Object sortOrder, label)
}

# ---------------------------------------------------------------------------
# Compatibility aliases for older GUI code
# ---------------------------------------------------------------------------

function Get-UckkOpsActionRegistry {
    return @(Get-UckkActionRegistry)
}

# ---------------------------------------------------------------------------
# Registry lookup helpers
# ---------------------------------------------------------------------------

function Get-UckkActionById {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Id
    )

    return Get-UckkActionRegistry | Where-Object { $_.id -eq $Id } | Select-Object -First 1
}

function Get-UckkOpsRegisteredAction {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ActionId
    )

    return Get-UckkActionById -Id $ActionId
}

function Get-UckkActionsByDomain {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "configuration",
            "local",
            "git",
            "server",
            "mediatheque",
            "moodle-data",
            "tests",
            "history",
            "recovery"
        )]
        [string] $Domain,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeHidden
    )

    $actions = Get-UckkActionRegistry | Where-Object { $_.domain -eq $Domain }

    if (-not $IncludeHidden) {
        $actions = $actions | Where-Object { $_.visible -eq $true }
    }

    return @($actions | Sort-Object sortOrder, label)
}

function Get-UckkActionsByTab {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Tab,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeHidden
    )

    $actions = Get-UckkActionRegistry | Where-Object { $_.tabs -contains $Tab }

    if (-not $IncludeHidden) {
        $actions = $actions | Where-Object { $_.visible -eq $true }
    }

    return @($actions | Sort-Object sortOrder, label)
}

function Get-UckkHomeActions {
    return Get-UckkActionsByTab -Tab "Accueil"
}

function Get-UckkDangerousActions {
    return @(Get-UckkActionRegistry | Where-Object { $_.dangerLevel -ge 4 } | Sort-Object dangerLevel, sortOrder)
}

function Get-UckkActionsRequiringConfirmation {
    return @(Get-UckkActionRegistry | Where-Object { $_.requiresConfirmation -eq $true } | Sort-Object dangerLevel, sortOrder)
}

function Get-UckkActionsRequiringSimulation {
    return @(Get-UckkActionRegistry | Where-Object { $_.requiresSimulation -eq $true } | Sort-Object domain, sortOrder)
}

# ---------------------------------------------------------------------------
# Registry validation
# ---------------------------------------------------------------------------

function New-UckkActionRegistryIssue {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("error", "warning")]
        [string] $Level,

        [Parameter(Mandatory = $true)]
        [string] $ActionId,

        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    return [pscustomobject]@{
        level    = $Level
        actionId = $ActionId
        message  = $Message
    }
}

function Test-UckkActionRegistry {
    $issues = [System.Collections.Generic.List[object]]::new()
    $actions = @(Get-UckkActionRegistry)

    $ids = @{}

    foreach ($action in $actions) {
        if ($ids.ContainsKey($action.id)) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "error" `
                -ActionId $action.id `
                -Message "Duplicate action id."))
        }
        else {
            $ids[$action.id] = $true
        }

        if ([string]::IsNullOrWhiteSpace($action.label)) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "error" `
                -ActionId $action.id `
                -Message "Missing action label."))
        }

        if ([string]::IsNullOrWhiteSpace($action.handler)) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "error" `
                -ActionId $action.id `
                -Message "Missing action handler."))
        }

        if ([string]::IsNullOrWhiteSpace($action.contract)) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "warning" `
                -ActionId $action.id `
                -Message "Missing contract document reference."))
        }

        $vagueLabels = @(
            "Run",
            "Go",
            "Sync",
            "Apply",
            "Fix",
            "Repair",
            "Reset",
            "Import",
            "Export",
            "Deploy",
            "Clean"
        )

        if ($vagueLabels -contains $action.label) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "error" `
                -ActionId $action.id `
                -Message ("Vague forbidden label: " + [string] $action.label)))
        }

        if ($action.dangerLevel -ge 5 -and -not $action.requiresConfirmation) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "error" `
                -ActionId $action.id `
                -Message "Server or higher danger action must require confirmation."))
        }

        if ($action.dangerLevel -eq 6 -and -not $action.requiresConfirmation) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "error" `
                -ActionId $action.id `
                -Message "Base Moodle serveur action must require confirmation."))
        }

        if ($action.dangerLevel -eq 7) {
            if (-not $action.requiresConfirmation) {
                $issues.Add((New-UckkActionRegistryIssue `
                    -Level "error" `
                    -ActionId $action.id `
                    -Message "Recovery action must require confirmation."))
            }

            if (-not $action.requiresBackup) {
                $issues.Add((New-UckkActionRegistryIssue `
                    -Level "error" `
                    -ActionId $action.id `
                    -Message "Recovery action must require backup."))
            }

            if ($action.tabs -contains "Accueil") {
                $issues.Add((New-UckkActionRegistryIssue `
                    -Level "error" `
                    -ActionId $action.id `
                    -Message "Recovery action must not appear on Accueil."))
            }
        }

        if ($action.mode -eq "application" -and $action.target -match "base Moodle serveur" -and $action.dangerLevel -ne 6) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "error" `
                -ActionId $action.id `
                -Message "Application to base Moodle serveur must be danger level 6."))
        }

        if ($action.mode -eq "application" -and $action.target -match "base Moodle locale" -and $action.dangerLevel -ne 4) {
            $issues.Add((New-UckkActionRegistryIssue `
                -Level "error" `
                -ActionId $action.id `
                -Message "Application to base Moodle locale must be danger level 4."))
        }
    }

    $errors = @($issues | Where-Object { $_.level -eq "error" })
    $warnings = @($issues | Where-Object { $_.level -eq "warning" })

    return [pscustomobject]@{
        success      = ((Get-UckkActionRegistryListCount -Value $errors) -eq 0)
        status       = if ((Get-UckkActionRegistryListCount -Value $errors) -eq 0) { "Réussi" } else { "Échoué" }
        actionCount  = (Get-UckkActionRegistryListCount -Value $actions)
        issues       = @($issues)
        errors       = $errors
        warnings     = $warnings
    }
}

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

$exportedFunctions = @(
    "New-UckkActionDefinition",
    "Get-UckkActionRegistry",
    "Get-UckkOpsActionRegistry",
    "Get-UckkActionById",
    "Get-UckkOpsRegisteredAction",
    "Get-UckkActionsByDomain",
    "Get-UckkActionsByTab",
    "Get-UckkHomeActions",
    "Get-UckkDangerousActions",
    "Get-UckkActionsRequiringConfirmation",
    "Get-UckkActionsRequiringSimulation",
    "Test-UckkActionRegistry"
)

Export-ModuleMember -Function $exportedFunctions
