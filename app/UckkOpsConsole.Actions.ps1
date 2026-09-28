#Requires -Version 7.0
<#
.SYNOPSIS
  Action wiring layer for UCKK Ops Console.

.DESCRIPTION
  This file connects GUI buttons to declared UCKK Ops actions.

  It must stay thin.

  It does not contain domain logic.
  It does not hardcode paths.
  It does not write directly to Moodle.
  It does not publish directly to the server.
  It does not run recovery actions without the declared safety metadata.

  Expected responsibilities:
    - read action definitions from the action registry;
    - connect buttons to action handlers;
    - ask confirmations when required;
    - block double execution while an action is running;
    - normalize returned results;
    - update the visible result area;
    - open reports and logs;
    - orchestrate declared action sequences for Accueil buttons.

.CONTRACT
  See:
    docs/03_INTERFACE_ACCUEIL.md
    docs/04_INTERFACE_ONGLETS_SPECIALISES.md
    docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md
    docs/10_RAPPORTS_LOGS_ERREURS.md
    docs/12_CONTRAT_TECHNIQUE_DU_CODE.md
#>

Set-StrictMode -Off

# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

function Initialize-UckkOpsConsoleActions {
    <#
    .SYNOPSIS
      Connects GUI buttons to action handlers.

    .PARAMETER State
      Mutable app state object created by app/UckkOpsConsole.State.ps1.

    .NOTES
      Expected State fields:
        Config
        ActionRegistry
        ActionButtons
        Controls
        IsBusy
        LastResult
        LastReportPath
        LastLogPath
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    Assert-UckkOpsActionState -State $State

    $registry = Get-UckkOpsActionRegistryObject -State $State

    if (-not $registry) {
        throw "Action registry is missing. Cannot initialize GUI actions."
    }

    $State.ActionRegistry = $registry

    Register-UckkOpsDeclaredButtons -State $State -Registry $registry
    Register-UckkOpsUtilityButtons -State $State

    Set-UckkOpsGuiBusyState -State $State -IsBusy:$false
    Set-UckkOpsStatusText -State $State -Text "Prêt"
}

# ---------------------------------------------------------------------------
# Button registration
# ---------------------------------------------------------------------------

function Register-UckkOpsDeclaredButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [object] $Registry
    )

    $buttons = Get-UckkOpsActionButtons -State $State

    if (-not $buttons) {
        return
    }

    foreach ($actionId in $buttons.Keys) {
        $currentActionId = [string] $actionId
        $button = $buttons[$currentActionId]

        if (-not $button) {
            continue
        }

        $definition = Get-UckkOpsActionDefinitionFromRegistry `
            -Registry $Registry `
            -ActionId $currentActionId `
            -ThrowIfMissing:$false

        if ($definition) {
            $label = Get-UckkOpsValue -Object $definition -Name "label" -Default $null
            $description = Get-UckkOpsValue -Object $definition -Name "description" -Default $null

            if ($label) {
                $button.Text = [string] $label
            }

            if ($description -and $State.PSObject.Properties.Name -contains "ToolTip" -and $State.ToolTip) {
                $State.ToolTip.SetToolTip($button, [string] $description)
            }

            $button.Enabled = $true
        }
        else {
            $button.Enabled = $false
            $button.Text = "$($button.Text) — non disponible"
        }

        $button.Add_Click({
            param($sender, $eventArgs)

            try {
                Invoke-UckkOpsGuiAction `
                    -State $State `
                    -ActionId $currentActionId
            }
            catch {
                $message = $_.Exception.Message

                try {
                    $definition = Get-UckkOpsActionDefinitionFromRegistry `
                        -Registry $Registry `
                        -ActionId $currentActionId `
                        -ThrowIfMissing:$false

                    $actionLabel = Get-UckkOpsValue -Object $definition -Name "label" -Default $currentActionId
                    $domain = Get-UckkOpsValue -Object $definition -Name "domain" -Default "configuration"
                    $target = Get-UckkOpsValue -Object $definition -Name "target" -Default "interface"
                    $dangerLevel = [int] (Get-UckkOpsValue -Object $definition -Name "dangerLevel" -Default 0)
                    $mode = Get-UckkOpsValue -Object $definition -Name "mode" -Default "vérification"

                    $result = New-UckkOpsFallbackResult `
                        -Success:$false `
                        -Status "Échoué" `
                        -Action $actionLabel `
                        -Domain $domain `
                        -Target $target `
                        -DangerLevel $dangerLevel `
                        -Mode $mode `
                        -Summary "L’action a échoué dans l’interface." `
                        -Errors @($message) `
                        -NextStep "Copier le résultat affiché et corriger le module indiqué."

                    Set-UckkOpsLastResult -State $State -Result $result
                    Update-UckkOpsVisibleResult -State $State -Result $result
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "L’action a échoué.`n`n$($_.Exception.Message)",
                        "UCKK Ops Console — erreur d’action",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    ) | Out-Null
                }
            }
        }.GetNewClosure())
    }
}

function Register-UckkOpsUtilityButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    $openReportButton = Get-UckkOpsControl -State $State -Name "OpenReportButton"
    if ($openReportButton) {
        $openReportButton.Add_Click({
            Invoke-UckkOpsOpenCurrentReport -State $State
        }.GetNewClosure())
    }

    $openLogButton = Get-UckkOpsControl -State $State -Name "OpenLogButton"
    if ($openLogButton) {
        $openLogButton.Add_Click({
            Invoke-UckkOpsOpenCurrentLog -State $State
        }.GetNewClosure())
    }

    $clearResultButton = Get-UckkOpsControl -State $State -Name "ClearResultButton"
    if ($clearResultButton) {
        $clearResultButton.Add_Click({
            Clear-UckkOpsVisibleResult -State $State
        }.GetNewClosure())
    }
}

function Resolve-UckkOpsActionHandlerName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $HandlerName
    )

    $handlerMap = @{
        # Accueil workflows
        "Invoke-UckkOpsHomeLocalReady"          = "Invoke-UckkOpsHomeLocalReady"
        "Invoke-UckkOpsHomePublishToUckk"      = "Invoke-UckkOpsHomePublishToUckk"

        # Local
        "Invoke-UckkLocalSourceToRuntimeSync"  = "Sync-UckkSourceToLocalMoodle"
        "Invoke-UckkLocalPurgeCaches"          = "Clear-UckkLocalMoodleCaches"
        "Invoke-UckkLocalCachePurge"           = "Clear-UckkLocalMoodleCaches"

        # Git
        "Test-UckkGitStatus"                   = "Get-UckkGitStatus"
        "Show-UckkGitDiff"                     = "Get-UckkGitDiff"

        # Server
        "Test-UckkServerStatus"                = "Test-UckkServerState"
        "Test-UckkServerPages"                 = "Test-UckkServerPublicPages"
        "Test-UckkPublicSite"                  = "Test-UckkServerPublicPages"
        "Publish-UckkServer"                   = "Invoke-UckkServerPublish"
        "Invoke-UckkServerCachePurge"          = "Clear-UckkServerMoodleCaches"
        "Restart-UckkServerPhpFpm"             = "Invoke-UckkServerPhpFpmReload"

        # Médiathèque
        "Test-UckkMediathequeManifest"           = "Test-UckkMediathequeManifestAction"
        "Invoke-UckkMediathequeLocalSimulation"  = "Invoke-UckkMediathequeSimulationLocal"
        "Invoke-UckkMediathequeServerSimulation" = "Invoke-UckkMediathequeSimulationServer"
        "Invoke-UckkMediathequeLocalApply"       = "Invoke-UckkMediathequeApplyLocal"
        "Invoke-UckkMediathequeServerApply"      = "Invoke-UckkMediathequeApplyServer"

        # Données Moodle
        "Test-UckkMoodleDataJson" = "Test-UckkMoodleDataJsonFiles"

        "Invoke-UckkMoodleDataLocalCategoriesSimulation"  = "Invoke-UckkMoodleDataCategoriesSimulationLocal"
        "Invoke-UckkMoodleDataLocalCategoriesApply"       = "Invoke-UckkMoodleDataCategoriesApplyLocal"
        "Invoke-UckkMoodleDataServerCategoriesSimulation" = "Invoke-UckkMoodleDataCategoriesSimulationServer"
        "Invoke-UckkMoodleDataServerCategoriesApply"      = "Invoke-UckkMoodleDataCategoriesApplyServer"

        "Invoke-UckkMoodleDataLocalCoursesSimulation"  = "Invoke-UckkMoodleDataCoursesSimulationLocal"
        "Invoke-UckkMoodleDataLocalCoursesApply"       = "Invoke-UckkMoodleDataCoursesApplyLocal"
        "Invoke-UckkMoodleDataServerCoursesSimulation" = "Invoke-UckkMoodleDataCoursesSimulationServer"
        "Invoke-UckkMoodleDataServerCoursesApply"      = "Invoke-UckkMoodleDataCoursesApplyServer"

        "Invoke-UckkMoodleDataLocalProgramsSimulation"  = "Invoke-UckkMoodleDataProgramsSimulationLocal"
        "Invoke-UckkMoodleDataLocalProgramsApply"       = "Invoke-UckkMoodleDataProgramsApplyLocal"
        "Invoke-UckkMoodleDataServerProgramsSimulation" = "Invoke-UckkMoodleDataProgramsSimulationServer"
        "Invoke-UckkMoodleDataServerProgramsApply"      = "Invoke-UckkMoodleDataProgramsApplyServer"

        "Invoke-UckkMoodleDataLocalPathwaysSimulation"  = "Invoke-UckkMoodleDataPathwaysSimulationLocal"
        "Invoke-UckkMoodleDataLocalPathwaysApply"       = "Invoke-UckkMoodleDataPathwaysApplyLocal"
        "Invoke-UckkMoodleDataServerPathwaysSimulation" = "Invoke-UckkMoodleDataPathwaysSimulationServer"
        "Invoke-UckkMoodleDataServerPathwaysApply"      = "Invoke-UckkMoodleDataPathwaysApplyServer"

        # GUI / utility actions
        "Open-UckkLatestReport"             = "Invoke-UckkOpsOpenCurrentReport"
        "Open-UckkReportsFolder"            = "Invoke-UckkOpsOpenReportsFolder"
        "Open-UckkLogsFolder"               = "Invoke-UckkOpsOpenLogsFolder"
        "Open-UckkLocalSourceFolder"        = "Invoke-UckkOpsOpenLocalSourceFolder"
        "Open-UckkLocalMoodleRuntimeFolder" = "Invoke-UckkOpsOpenLocalMoodleRuntimeFolder"
        "Open-UckkPublicSite"               = "Invoke-UckkOpsOpenPublicSite"
        "Open-UckkRecoveryFolder"           = "Invoke-UckkOpsOpenRecoveryFolder"
        "Open-UckkLegacyFolder"             = "Invoke-UckkOpsOpenLegacyFolder"
    }

    if ($handlerMap.ContainsKey($HandlerName)) {
        return $handlerMap[$HandlerName]
    }

    return $HandlerName
}

# ---------------------------------------------------------------------------
# Action invocation
# ---------------------------------------------------------------------------

function Invoke-UckkOpsGuiAction {
    <#
    .SYNOPSIS
      Runs a declared action from the GUI.

    .PARAMETER State
      App state object.

    .PARAMETER ActionId
      ID from lib/UckkOps.ActionRegistry.psm1.

    .OUTPUTS
      ActionResult-like object.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string] $ActionId
    )

    if (Get-UckkOpsIsBusy -State $State) {
        $result = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Annulé" `
            -Action $ActionId `
            -Domain "configuration" `
            -Target "interface" `
            -DangerLevel 0 `
            -Mode "annulation" `
            -Summary "Annulé — une autre action est déjà en cours." `
            -NextStep "Attendre la fin de l’action en cours."

        Set-UckkOpsLastResult -State $State -Result $result
        Update-UckkOpsVisibleResult -State $State -Result $result
        return $result
    }

    $registry = Get-UckkOpsActionRegistryObject -State $State

    $definition = Get-UckkOpsActionDefinitionFromRegistry `
        -Registry $registry `
        -ActionId $ActionId `
        -ThrowIfMissing:$true

    $actionLabel = Get-UckkOpsValue -Object $definition -Name "label" -Default $ActionId
    $domain = Get-UckkOpsValue -Object $definition -Name "domain" -Default "configuration"
    $target = Get-UckkOpsValue -Object $definition -Name "target" -Default "aucune cible modifiée"
    $dangerLevel = [int] (Get-UckkOpsValue -Object $definition -Name "dangerLevel" -Default 0)
    $mode = Get-UckkOpsValue -Object $definition -Name "mode" -Default "vérification"
    $handlerName = Get-UckkOpsValue -Object $definition -Name "handler" -Default $null

    if (-not $handlerName) {
        $result = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action $actionLabel `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary "L’action a échoué. Aucun handler n’est déclaré pour cette action." `
            -NextStep "Corriger la déclaration dans lib/UckkOps.ActionRegistry.psm1."

        Set-UckkOpsLastResult -State $State -Result $result
        Update-UckkOpsVisibleResult -State $State -Result $result
        return $result
    }

    $resolvedHandlerName = Resolve-UckkOpsActionHandlerName -HandlerName $handlerName
    $handlerCommand = Get-Command -Name $resolvedHandlerName -ErrorAction SilentlyContinue

    if (-not $handlerCommand) {
        $result = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action $actionLabel `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary "L’action a échoué. Le handler '$handlerName' est introuvable. Nom résolu : '$resolvedHandlerName'." `
            -NextStep "Vérifier que le module correspondant est chargé ou corriger lib/UckkOps.ActionRegistry.psm1."

        Set-UckkOpsLastResult -State $State -Result $result
        Update-UckkOpsVisibleResult -State $State -Result $result
        return $result
    }

    $confirmationResult = Confirm-UckkOpsGuiActionIfRequired `
        -State $State `
        -ActionDefinition $definition

    if (-not $confirmationResult.Confirmed) {
        $result = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Annulé" `
            -Action $actionLabel `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode "annulation" `
            -Summary "Annulé — aucune modification n’a été faite." `
            -NextStep "Aucune action requise."

        Set-UckkOpsLastResult -State $State -Result $result
        Update-UckkOpsVisibleResult -State $State -Result $result
        return $result
    }

    try {
        Set-UckkOpsGuiBusyState -State $State -IsBusy:$true
        Set-UckkOpsStatusText -State $State -Text "En cours — $actionLabel"

        $runningResult = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "En cours" `
            -Action $actionLabel `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary "En cours — $actionLabel" `
            -NextStep "Attendre la fin de l’action."

        Update-UckkOpsVisibleResult -State $State -Result $runningResult

        $rawResult = Invoke-UckkOpsActionHandler `
            -Command $handlerCommand `
            -State $State `
            -ActionDefinition $definition `
            -ConfirmationResult $confirmationResult

        $result = ConvertTo-UckkOpsActionResult `
            -RawResult $rawResult `
            -ActionDefinition $definition

        Set-UckkOpsLastResult -State $State -Result $result
        Update-UckkOpsVisibleResult -State $State -Result $result

        return $result
    }
    catch {
        $message = $_.Exception.Message

        $result = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action $actionLabel `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary "L’action a échoué. Cause probable : une erreur interne est survenue." `
            -Errors @($message) `
            -NextStep "Ouvrir le rapport ou le log technique si disponible."

        Set-UckkOpsLastResult -State $State -Result $result
        Update-UckkOpsVisibleResult -State $State -Result $result

        return $result
    }
    finally {
        Set-UckkOpsGuiBusyState -State $State -IsBusy:$false
    }
}

function Invoke-UckkOpsActionHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.CommandInfo] $Command,

        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [object] $ActionDefinition,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $ConfirmationResult = $null
    )

    $splat = @{}

    if (
        $Command.Parameters.ContainsKey("Confirmed") -and
        $null -ne $ConfirmationResult -and
        [bool] (Get-UckkOpsValue -Object $ConfirmationResult -Name "Confirmed" -Default $false)
    ) {
        $splat.Confirmed = $true
    }

    if ($Command.Parameters.ContainsKey("Config")) {
        $splat.Config = $State.Config
    }

    if ($Command.Parameters.ContainsKey("State")) {
        $splat.State = $State
    }

    if ($Command.Parameters.ContainsKey("AppState")) {
        $splat.AppState = $State
    }

    if ($Command.Parameters.ContainsKey("Action")) {
        $splat.Action = $ActionDefinition
    }

    if ($Command.Parameters.ContainsKey("ActionDefinition")) {
        $splat.ActionDefinition = $ActionDefinition
    }

    if ($Command.Parameters.ContainsKey("ActionId")) {
        $splat.ActionId = Get-UckkOpsValue -Object $ActionDefinition -Name "id" -Default ""
    }

    if ((Get-UckkOpsListCount -Value $splat.Keys) -gt 0) {
        return & $Command.Name @splat
    }

    return & $Command.Name
}

# ---------------------------------------------------------------------------
# Accueil workflows
# ---------------------------------------------------------------------------

function Invoke-UckkOpsHomeLocalReady {
    <#
    .SYNOPSIS
      Runs the Accueil local chain and opens local Moodle.

    .DESCRIPTION
      Stops immediately on first failed step.
      This function only orchestrates declared actions.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory = $false)]
        [object] $ActionDefinition = $null
    )

    return Invoke-UckkOpsDeclaredActionSequence `
        -State $State `
        -ActionIds @(
            "configuration.verify",
            "local.verify.paths",
            "local.moodle_diagnostic",
            "local.sync.source_to_runtime",
            "local.moodle_upgrade",
            "local.purge_caches",
            "local.start_moodle",
            "local.open_uckk"
        ) `
        -ActionName "Préparer local et ouvrir Moodle" `
        -Domain "local" `
        -Target "Moodle local + base locale" `
        -DangerLevel 3 `
        -Mode "application" `
        -SuccessSummary "La chaîne locale est terminée. Moodle local est à jour et UCKK a été ouvert." `
        -SuccessNextStep "Tester ensuite UCC et Math, ou lancer le diagnostic du switcher."
}

function Invoke-UckkOpsHomePublishToUckk {
    <#
    .SYNOPSIS
      Runs the Accueil publication chain up to uckk.org.

    .DESCRIPTION
      Stops immediately on first failed step.
      This function only orchestrates declared actions.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory = $false)]
        [object] $ActionDefinition = $null,

        [Parameter(Mandatory = $false)]
        [switch] $Confirmed
    )

    return Invoke-UckkOpsDeclaredActionSequence `
        -State $State `
        -ActionIds @(
            "configuration.verify",
            "local.verify.paths",
            "local.moodle_diagnostic",
            "local.sync.source_to_runtime",
            "local.moodle_upgrade",
            "local.purge_caches",
            "local.start_moodle",
            "git.verify",
            "git.sensitive_files",
            "git.push",
            "server.publish_chain",
            "server.verify_public_site",
            "server.open_public_site"
        ) `
        -ActionName "Publier jusqu'à uckk.org" `
        -Domain "server" `
        -Target "uckk.org" `
        -DangerLevel 5 `
        -Mode "publication" `
        -SuccessSummary "La chaîne de publication est terminée. uckk.org a été vérifié et ouvert." `
        -SuccessNextStep "Vérifier le site public dans le navigateur."
}

function Invoke-UckkOpsDeclaredActionSequence {
    <#
    .SYNOPSIS
      Runs a list of declared registry actions in order.

    .DESCRIPTION
      Each step is resolved through the registry and executed through the same
      handler adapter as normal GUI actions.

      The sequence stops at the first failed, missing, cancelled or unresolved
      step.

      This helper intentionally does not call Invoke-UckkOpsGuiAction to avoid:
      - nested busy-state conflicts;
      - repeated global confirmations;
      - recursive UI state transitions.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string[]] $ActionIds,

        [Parameter(Mandatory)]
        [string] $ActionName,

        [Parameter(Mandatory)]
        [string] $Domain,

        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [int] $DangerLevel,

        [Parameter(Mandatory)]
        [string] $Mode,

        [Parameter(Mandatory)]
        [string] $SuccessSummary,

        [Parameter(Mandatory)]
        [string] $SuccessNextStep
    )

    $completed = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    $lastReportPath = ""
    $lastLogPath = ""

    $total = Get-UckkOpsListCount -Value $ActionIds
    $index = 0

    foreach ($stepActionId in $ActionIds) {
        $index++

        $progressResult = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "En cours" `
            -Action $ActionName `
            -Domain $Domain `
            -Target $Target `
            -DangerLevel $DangerLevel `
            -Mode $Mode `
            -Summary ("Étape " + $index + "/" + $total + " — " + $stepActionId) `
            -NextStep "Attendre la fin de cette étape."

        Update-UckkOpsVisibleResult -State $State -Result $progressResult

        $stepResult = Invoke-UckkOpsDeclaredActionStep `
            -State $State `
            -ActionId $stepActionId

        $stepLabel = Get-UckkOpsValue -Object $stepResult -Name "action" -Default $stepActionId
        $stepStatus = Get-UckkOpsValue -Object $stepResult -Name "status" -Default "Échoué"
        $stepSummary = Get-UckkOpsValue -Object $stepResult -Name "summary" -Default ""

        $completed.Add([pscustomobject]@{
            id      = $stepActionId
            label   = $stepLabel
            status  = $stepStatus
            summary = $stepSummary
            result  = $stepResult
        }) | Out-Null

        $stepWarnings = @(Get-UckkOpsValue -Object $stepResult -Name "warnings" -Default @())
        foreach ($warning in $stepWarnings) {
            if ($warning) {
                $warnings.Add([string] $warning) | Out-Null
            }
        }

        $stepErrors = @(Get-UckkOpsValue -Object $stepResult -Name "errors" -Default @())
        foreach ($errorItem in $stepErrors) {
            if ($errorItem) {
                $errors.Add([string] $errorItem) | Out-Null
            }
        }

        $stepReportPath = Get-UckkOpsValue -Object $stepResult -Name "reportPath" -Default ""
        if ($stepReportPath) {
            $lastReportPath = [string] $stepReportPath
        }

        $stepLogPath = Get-UckkOpsValue -Object $stepResult -Name "logPath" -Default ""
        if ($stepLogPath) {
            $lastLogPath = [string] $stepLogPath
        }

        if (-not (Test-UckkOpsActionResultSuccess -Result $stepResult)) {
            $failureMessage = "Arrêt à l'étape $index/$total : $stepActionId — $stepStatus."

            if ($stepSummary) {
                $failureMessage = $failureMessage + " " + $stepSummary
            }

            $errors.Add($failureMessage) | Out-Null

            return New-UckkOpsFallbackResult `
                -Success:$false `
                -Status "Échoué" `
                -Action $ActionName `
                -Domain $Domain `
                -Target $Target `
                -DangerLevel $DangerLevel `
                -Mode $Mode `
                -Summary $failureMessage `
                -Warnings @($warnings) `
                -Errors @($errors) `
                -NextStep "Corriger l'étape échouée puis relancer le bouton depuis Accueil." `
                -ReportPath $lastReportPath `
                -LogPath $lastLogPath `
                -Data @{
                    completed = @($completed)
                    failedStep = $stepActionId
                    failedStepIndex = $index
                    failedResult = $stepResult
                    totalSteps = $total
                }
        }
    }

    return New-UckkOpsFallbackResult `
        -Success:$true `
        -Status "Réussi" `
        -Action $ActionName `
        -Domain $Domain `
        -Target $Target `
        -DangerLevel $DangerLevel `
        -Mode $Mode `
        -Summary $SuccessSummary `
        -Warnings @($warnings) `
        -Errors @() `
        -NextStep $SuccessNextStep `
        -ReportPath $lastReportPath `
        -LogPath $lastLogPath `
        -Data @{
            completed = @($completed)
            totalSteps = $total
        }
}

function Invoke-UckkOpsDeclaredActionStep {
    <#
    .SYNOPSIS
      Runs one declared registry action without GUI confirmation or busy-state mutation.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string] $ActionId
    )

    $registry = Get-UckkOpsActionRegistryObject -State $State

    $definition = Get-UckkOpsActionDefinitionFromRegistry `
        -Registry $registry `
        -ActionId $ActionId `
        -ThrowIfMissing:$false

    if (-not $definition) {
        return New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action $ActionId `
            -Domain "configuration" `
            -Target "registre d'actions" `
            -DangerLevel 0 `
            -Mode "vérification" `
            -Summary "L'action déclarée est introuvable dans le registre." `
            -NextStep "Corriger lib/UckkOps.ActionRegistry.psm1."
    }

    $actionLabel = Get-UckkOpsValue -Object $definition -Name "label" -Default $ActionId
    $domain = Get-UckkOpsValue -Object $definition -Name "domain" -Default "configuration"
    $target = Get-UckkOpsValue -Object $definition -Name "target" -Default "aucune cible modifiée"
    $dangerLevel = [int] (Get-UckkOpsValue -Object $definition -Name "dangerLevel" -Default 0)
    $mode = Get-UckkOpsValue -Object $definition -Name "mode" -Default "vérification"
    $handlerName = Get-UckkOpsValue -Object $definition -Name "handler" -Default ""

    if ([string]::IsNullOrWhiteSpace($handlerName)) {
        return New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action $actionLabel `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary "Aucun handler n'est déclaré pour cette étape." `
            -NextStep "Corriger lib/UckkOps.ActionRegistry.psm1."
    }

    $resolvedHandlerName = Resolve-UckkOpsActionHandlerName -HandlerName $handlerName
    $handlerCommand = Get-Command -Name $resolvedHandlerName -ErrorAction SilentlyContinue

    if (-not $handlerCommand) {
        return New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action $actionLabel `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary "Le handler '$handlerName' est introuvable. Nom résolu : '$resolvedHandlerName'." `
            -NextStep "Vérifier que le module correspondant est chargé ou corriger le registre."
    }

    try {
        $confirmationResult = [pscustomobject]@{
            Confirmed = $true
            Reason = "Accueil action sequence"
        }

        $rawResult = Invoke-UckkOpsActionHandler `
            -Command $handlerCommand `
            -State $State `
            -ActionDefinition $definition `
            -ConfirmationResult $confirmationResult

        return ConvertTo-UckkOpsActionResult `
            -RawResult $rawResult `
            -ActionDefinition $definition
    }
    catch {
        return New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action $actionLabel `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary "L'étape a échoué pendant son exécution." `
            -Errors @($_.Exception.Message) `
            -NextStep "Corriger le handler '$resolvedHandlerName'."
    }
}

function Test-UckkOpsActionResultSuccess {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object] $Result
    )

    if (-not $Result) {
        return $false
    }

    $successValue = Get-UckkOpsValue -Object $Result -Name "success" -Default $null

    if ($null -ne $successValue) {
        return [bool] $successValue
    }

    $status = [string] (Get-UckkOpsValue -Object $Result -Name "status" -Default "")

    if ($status -match "^(Réussi|Reussi|OK|Succès|Succes)$") {
        return $true
    }

    return $false
}


# ---------------------------------------------------------------------------
# Confirmations
# ---------------------------------------------------------------------------

function Confirm-UckkOpsGuiActionIfRequired {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [object] $ActionDefinition
    )

    $requiresConfirmation = [bool] (Get-UckkOpsValue -Object $ActionDefinition -Name "requiresConfirmation" -Default $false)

    if (-not $requiresConfirmation) {
        return [pscustomobject]@{
            Confirmed = $true
            Reason = "No confirmation required."
        }
    }

    $action = Get-UckkOpsValue -Object $ActionDefinition -Name "label" -Default "Action"
    $target = Get-UckkOpsValue -Object $ActionDefinition -Name "target" -Default "cible inconnue"
    $dangerLevel = [int] (Get-UckkOpsValue -Object $ActionDefinition -Name "dangerLevel" -Default 0)
    $message = Get-UckkOpsValue -Object $ActionDefinition -Name "confirmationMessage" -Default $null
    $requiresBackup = [bool] (Get-UckkOpsValue -Object $ActionDefinition -Name "requiresBackup" -Default $false)

    if (-not $message) {
        $message = New-UckkOpsDefaultConfirmationMessage `
            -Action $action `
            -Target $target `
            -DangerLevel $dangerLevel `
            -RequiresBackup:$requiresBackup
    }

    $confirmCommand = Get-Command -Name "Confirm-UckkAction" -ErrorAction SilentlyContinue

    if ($confirmCommand) {
        try {
            $confirmed = Confirm-UckkAction `
                -Action $action `
                -Target $target `
                -DangerLevel $dangerLevel `
                -Message $message `
                -RequiresBackup:$requiresBackup

            return [pscustomobject]@{
                Confirmed = [bool] $confirmed
                Reason = "Confirm-UckkAction"
            }
        }
        catch {
            # Fall back to GUI confirmation below.
        }
    }

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

    $caption = "Confirmation requise"

    $dialogResult = [System.Windows.Forms.MessageBox]::Show(
        $message,
        $caption,
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button2
    )

    return [pscustomobject]@{
        Confirmed = ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK)
        Reason = "MessageBox"
    }
}

function New-UckkOpsDefaultConfirmationMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Action,

        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [int] $DangerLevel,

        [switch] $RequiresBackup
    )

    switch ($DangerLevel) {
        3 {
            return "Cette action enregistre ou envoie des changements dans l’historique Git.`nVérifie qu’aucun secret n’est inclus.`nContinuer ?"
        }

        4 {
            return "Cette action écrit dans la base Moodle locale. Continuer ?"
        }

        5 {
            return "Cette action modifie uckk.org ou son code serveur. Continuer ?"
        }

        6 {
            return "Cette action écrit dans la base Moodle serveur. Continuer ?"
        }

        7 {
            if ($RequiresBackup) {
                return "Cette action est une récupération, pas une opération normale.`nElle peut modifier plusieurs données.`nUne sauvegarde doit exister avant de continuer.`nContinuer ?"
            }

            return "Cette action est une récupération, pas une opération normale.`nElle peut modifier plusieurs données.`nContinuer ?"
        }

        default {
            return "Action : $Action`nCible : $Target`nContinuer ?"
        }
    }
}

# ---------------------------------------------------------------------------
# Result normalization
# ---------------------------------------------------------------------------

function ConvertTo-UckkOpsActionResult {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object] $RawResult,

        [Parameter(Mandatory)]
        [object] $ActionDefinition
    )

    $action = Get-UckkOpsValue -Object $ActionDefinition -Name "label" -Default "Action"
    $domain = Get-UckkOpsValue -Object $ActionDefinition -Name "domain" -Default "configuration"
    $target = Get-UckkOpsValue -Object $ActionDefinition -Name "target" -Default "aucune cible modifiée"
    $dangerLevel = [int] (Get-UckkOpsValue -Object $ActionDefinition -Name "dangerLevel" -Default 0)
    $mode = Get-UckkOpsValue -Object $ActionDefinition -Name "mode" -Default "vérification"

    if (-not $RawResult) {
        return New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action $action `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary "L’action n’a retourné aucun résultat." `
            -NextStep "Corriger le handler pour retourner un ActionResult."
    }

    $status = Get-UckkOpsValue -Object $RawResult -Name "status" -Default $null
    $summary = Get-UckkOpsValue -Object $RawResult -Name "summary" -Default $null

    if ($status -and $summary) {
        return $RawResult
    }

    if ($RawResult -is [string]) {
        return New-UckkOpsFallbackResult `
            -Success:$true `
            -Status "Réussi" `
            -Action $action `
            -Domain $domain `
            -Target $target `
            -DangerLevel $dangerLevel `
            -Mode $mode `
            -Summary $RawResult `
            -NextStep "Lire le rapport si disponible."
    }

    return New-UckkOpsFallbackResult `
        -Success:$true `
        -Status "Réussi" `
        -Action $action `
        -Domain $domain `
        -Target $target `
        -DangerLevel $dangerLevel `
        -Mode $mode `
        -Summary "Action terminée." `
        -NextStep "Lire le rapport si disponible." `
        -Data $RawResult
}

function New-UckkOpsFallbackResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool] $Success,

        [Parameter(Mandatory)]
        [string] $Status,

        [Parameter(Mandatory)]
        [string] $Action,

        [Parameter(Mandatory)]
        [string] $Domain,

        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [int] $DangerLevel,

        [Parameter(Mandatory)]
        [string] $Mode,

        [Parameter(Mandatory)]
        [string] $Summary,

        [Parameter()]
        [string[]] $Warnings = @(),

        [Parameter()]
        [string[]] $Errors = @(),

        [Parameter()]
        [string] $NextStep = "Aucune action requise.",

        [Parameter()]
        [string] $ReportPath = "",

        [Parameter()]
        [string] $LogPath = "",

        [Parameter()]
        [object] $Data = $null
    )

    $newResultCommand = Get-Command -Name "New-UckkActionResult" -ErrorAction SilentlyContinue

    if ($newResultCommand) {
        try {
            return New-UckkActionResult `
                -Success:$Success `
                -Status $Status `
                -Action $Action `
                -Domain $Domain `
                -Target $Target `
                -DangerLevel $DangerLevel `
                -Mode $Mode `
                -Summary $Summary `
                -Warnings $Warnings `
                -Errors $Errors `
                -NextStep $NextStep `
                -ReportPath $ReportPath `
                -LogPath $LogPath `
                -Data $Data
        }
        catch {
            # Use fallback object below.
        }
    }

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

# ---------------------------------------------------------------------------
# GUI updates
# ---------------------------------------------------------------------------

function Update-UckkOpsVisibleResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [object] $Result
    )

    $status = Get-UckkOpsValue -Object $Result -Name "status" -Default "Échoué"
    $action = Get-UckkOpsValue -Object $Result -Name "action" -Default ""
    $target = Get-UckkOpsValue -Object $Result -Name "target" -Default ""
    $summary = Get-UckkOpsValue -Object $Result -Name "summary" -Default ""
    $nextStep = Get-UckkOpsValue -Object $Result -Name "nextStep" -Default ""
    $reportPath = Get-UckkOpsValue -Object $Result -Name "reportPath" -Default ""
    $logPath = Get-UckkOpsValue -Object $Result -Name "logPath" -Default ""
    $warnings = @(Get-UckkOpsValue -Object $Result -Name "warnings" -Default @())
    $errors = @(Get-UckkOpsValue -Object $Result -Name "errors" -Default @())

    Set-UckkOpsStatusText -State $State -Text $status

    $summaryText = @()
    $summaryText += "Statut : $status"

    if ($action) {
        $summaryText += "Action : $action"
    }

    if ($target) {
        $summaryText += "Cible : $target"
    }

    if ($summary) {
        $summaryText += ""
        $summaryText += "Résumé :"
        $summaryText += $summary
    }

    if ((Get-UckkOpsListCount -Value $warnings) -gt 0) {
        $summaryText += ""
        $summaryText += "Avertissements :"
        foreach ($warning in $warnings) {
            $summaryText += "- $warning"
        }
    }

    if ((Get-UckkOpsListCount -Value $errors) -gt 0) {
        $summaryText += ""
        $summaryText += "Erreurs :"
        foreach ($errorItem in $errors) {
            $summaryText += "- $errorItem"
        }
    }

    if ($nextStep) {
        $summaryText += ""
        $summaryText += "Prochaine étape :"
        $summaryText += $nextStep
    }

    $resultBox = Get-UckkOpsControl -State $State -Name "LastResultTextBox"
    if ($resultBox) {
        $resultBox.Text = ($summaryText -join [Environment]::NewLine)
    }

    $summaryLabel = Get-UckkOpsControl -State $State -Name "LastSummaryLabel"
    if ($summaryLabel) {
        $summaryLabel.Text = $summary
    }

    $nextStepLabel = Get-UckkOpsControl -State $State -Name "LastNextStepLabel"
    if ($nextStepLabel) {
        $nextStepLabel.Text = $nextStep
    }

    $openReportButton = Get-UckkOpsControl -State $State -Name "OpenReportButton"
    if ($openReportButton) {
        $openReportButton.Enabled = [bool] $reportPath
    }

    $openLogButton = Get-UckkOpsControl -State $State -Name "OpenLogButton"
    if ($openLogButton) {
        $openLogButton.Enabled = [bool] $logPath
    }
}

function Clear-UckkOpsVisibleResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    $resultBox = Get-UckkOpsControl -State $State -Name "LastResultTextBox"
    if ($resultBox) {
        $resultBox.Text = ""
    }

    $summaryLabel = Get-UckkOpsControl -State $State -Name "LastSummaryLabel"
    if ($summaryLabel) {
        $summaryLabel.Text = ""
    }

    $nextStepLabel = Get-UckkOpsControl -State $State -Name "LastNextStepLabel"
    if ($nextStepLabel) {
        $nextStepLabel.Text = ""
    }

    Set-UckkOpsStatusText -State $State -Text "Prêt"
}

function Set-UckkOpsStatusText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string] $Text
    )

    $statusLabel = Get-UckkOpsControl -State $State -Name "StatusLabel"

    if ($statusLabel) {
        $statusLabel.Text = $Text
    }

    if ($State.PSObject.Properties.Name -contains "StatusText") {
        $State.StatusText = $Text
    }
}

function Set-UckkOpsGuiBusyState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [bool] $IsBusy
    )

    if ($State.PSObject.Properties.Name -contains "IsBusy") {
        $State.IsBusy = $IsBusy
    }

    $buttons = Get-UckkOpsActionButtons -State $State

    if ($buttons) {
        foreach ($button in $buttons.Values) {
            if ($button) {
                $button.Enabled = -not $IsBusy
            }
        }
    }

    $form = Get-UckkOpsControl -State $State -Name "MainForm"
    if (-not $form -and ($State.PSObject.Properties.Name -contains "Form")) {
        $form = $State.Form
    }

    if ($form) {
        if ($IsBusy) {
            $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        }
        else {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
        }
    }
}

# ---------------------------------------------------------------------------
# Report and log opening
# ---------------------------------------------------------------------------

function Invoke-UckkOpsOpenCurrentReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    $path = ""

    if ($State.PSObject.Properties.Name -contains "LastReportPath") {
        $path = [string] $State.LastReportPath
    }

    if (-not $path -and $State.PSObject.Properties.Name -contains "LastResult" -and $State.LastResult) {
        $path = [string] (Get-UckkOpsValue -Object $State.LastResult -Name "reportPath" -Default "")
    }

    Invoke-UckkOpsOpenPathFromGui -State $State -Path $path -Label "rapport"
}

function Invoke-UckkOpsOpenCurrentLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    $path = ""

    if ($State.PSObject.Properties.Name -contains "LastLogPath") {
        $path = [string] $State.LastLogPath
    }

    if (-not $path -and $State.PSObject.Properties.Name -contains "LastResult" -and $State.LastResult) {
        $path = [string] (Get-UckkOpsValue -Object $State.LastResult -Name "logPath" -Default "")
    }

    Invoke-UckkOpsOpenPathFromGui -State $State -Path $path -Label "log"
}

function Invoke-UckkOpsOpenPathFromGui {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter()]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Label
    )

    if (-not $Path) {
        $result = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action "Ouvrir $Label" `
            -Domain "history" `
            -Target "fichier" `
            -DangerLevel 0 `
            -Mode "navigation" `
            -Summary "Aucun $Label disponible pour le moment." `
            -NextStep "Lancer une action qui produit un $Label."

        Set-UckkOpsLastResult -State $State -Result $result
        Update-UckkOpsVisibleResult -State $State -Result $result
        return
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        $result = New-UckkOpsFallbackResult `
            -Success:$false `
            -Status "Échoué" `
            -Action "Ouvrir $Label" `
            -Domain "history" `
            -Target $Path `
            -DangerLevel 0 `
            -Mode "navigation" `
            -Summary "Le fichier demandé est introuvable." `
            -NextStep "Vérifier le chemin du $Label."

        Set-UckkOpsLastResult -State $State -Result $result
        Update-UckkOpsVisibleResult -State $State -Result $result
        return
    }

    $openPathCommand = Get-Command -Name "Open-UckkPath" -ErrorAction SilentlyContinue

    if ($openPathCommand) {
        Open-UckkPath -Path $Path | Out-Null
        return
    }

    Start-Process -FilePath $Path | Out-Null
}

function Get-UckkOpsConfigPathValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string[]] $Path,

        [Parameter()]
        [string] $Default = ""
    )

    if (-not $State -or -not ($State.PSObject.Properties.Name -contains "Config")) {
        return $Default
    }

    $current = $State.Config

    foreach ($part in $Path) {
        if ($null -eq $current) {
            return $Default
        }

        if ($current -is [hashtable]) {
            if (-not $current.ContainsKey($part)) {
                return $Default
            }

            $current = $current[$part]
            continue
        }

        if ($current.PSObject.Properties.Name -notcontains $part) {
            return $Default
        }

        $current = $current.$part
    }

    if ($null -eq $current) {
        return $Default
    }

    return [string] $current
}

function Resolve-UckkOpsGuiRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    $appRoot = Get-UckkOpsConfigPathValue `
        -State $State `
        -Path @("app", "root") `
        -Default (Get-Location).Path

    return [System.IO.Path]::GetFullPath((Join-Path $appRoot $Path))
}

function Invoke-UckkOpsOpenConfiguredPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string[]] $ConfigPath,

        [Parameter(Mandatory)]
        [string] $FallbackPath,

        [Parameter(Mandatory)]
        [string] $ActionName
    )

    $path = Get-UckkOpsConfigPathValue `
        -State $State `
        -Path $ConfigPath `
        -Default $FallbackPath

    $resolvedPath = Resolve-UckkOpsGuiRelativePath -State $State -Path $path

    Invoke-UckkOpsOpenPathFromGui -State $State -Path $resolvedPath -Label $ActionName

    return New-UckkOpsFallbackResult `
        -Success:$true `
        -Status "Réussi" `
        -Action $ActionName `
        -Domain "configuration" `
        -Target $resolvedPath `
        -DangerLevel 0 `
        -Mode "navigation" `
        -Summary "Ouverture demandée : $resolvedPath" `
        -NextStep "Aucune action requise." `
        -Data @{ path = $resolvedPath }
}

function Invoke-UckkOpsOpenConfiguredUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string[]] $ConfigPath,

        [Parameter(Mandatory)]
        [string] $FallbackUrl,

        [Parameter(Mandatory)]
        [string] $ActionName
    )

    $url = Get-UckkOpsConfigPathValue `
        -State $State `
        -Path $ConfigPath `
        -Default $FallbackUrl

    $openUrlCommand = Get-Command -Name "Open-UckkUrl" -ErrorAction SilentlyContinue

    if ($openUrlCommand) {
        return Open-UckkUrl -Url $url
    }

    Start-Process -FilePath $url | Out-Null

    return New-UckkOpsFallbackResult `
        -Success:$true `
        -Status "Réussi" `
        -Action $ActionName `
        -Domain "configuration" `
        -Target $url `
        -DangerLevel 0 `
        -Mode "navigation" `
        -Summary "Ouverture demandée : $url" `
        -NextStep "Aucune action requise." `
        -Data @{ url = $url }
}

function Invoke-UckkOpsOpenReportsFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    return Invoke-UckkOpsOpenConfiguredPath `
        -State $State `
        -ConfigPath @("paths", "reportsDir") `
        -FallbackPath "./reports" `
        -ActionName "Ouvrir dossier rapports"
}

function Invoke-UckkOpsOpenLogsFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    return Invoke-UckkOpsOpenConfiguredPath `
        -State $State `
        -ConfigPath @("paths", "logsDir") `
        -FallbackPath "./logs" `
        -ActionName "Ouvrir dossier logs"
}

function Invoke-UckkOpsOpenLocalSourceFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    return Invoke-UckkOpsOpenConfiguredPath `
        -State $State `
        -ConfigPath @("paths", "uckkMoodleSource") `
        -FallbackPath "" `
        -ActionName "Ouvrir dossier source"
}

function Invoke-UckkOpsOpenLocalMoodleRuntimeFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    return Invoke-UckkOpsOpenConfiguredPath `
        -State $State `
        -ConfigPath @("paths", "localMoodleRuntime") `
        -FallbackPath "" `
        -ActionName "Ouvrir dossier Moodle local"
}

function Invoke-UckkOpsOpenLocalMoodle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    return Invoke-UckkOpsOpenConfiguredUrl `
        -State $State `
        -ConfigPath @("urls", "localBase") `
        -FallbackUrl "http://127.0.0.1:8000" `
        -ActionName "Ouvrir Moodle local"
}

function Invoke-UckkOpsOpenPublicSite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    return Invoke-UckkOpsOpenConfiguredUrl `
        -State $State `
        -ConfigPath @("urls", "serverBase") `
        -FallbackUrl "https://uckk.org" `
        -ActionName "Ouvrir uckk.org"
}

function Invoke-UckkOpsOpenRecoveryFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    return Invoke-UckkOpsOpenConfiguredPath `
        -State $State `
        -ConfigPath @("paths", "recoveryDir") `
        -FallbackPath "./recovery" `
        -ActionName "Ouvrir dossier recovery"
}

function Invoke-UckkOpsOpenLegacyFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    return Invoke-UckkOpsOpenConfiguredPath `
        -State $State `
        -ConfigPath @("paths", "legacyDir") `
        -FallbackPath "./legacy" `
        -ActionName "Ouvrir dossier legacy"
}

# ---------------------------------------------------------------------------
# Registry helpers
# ---------------------------------------------------------------------------

function Get-UckkOpsActionRegistryObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    $registryCommands = @(
        "Get-UckkOpsActionRegistry",
        "Get-UckkActionRegistry"
    )

    foreach ($commandName in $registryCommands) {
        $command = Get-Command -Name $commandName -ErrorAction SilentlyContinue

        if ($command) {
            return & $command.Name
        }
    }

    if ($State.PSObject.Properties.Name -contains "ActionRegistry") {
        return $State.ActionRegistry
    }

    return $null
}

function Get-UckkOpsActionDefinitionFromRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Registry,

        [Parameter(Mandatory)]
        [string] $ActionId,

        [switch] $ThrowIfMissing
    )

    if (-not $Registry) {
        if ($ThrowIfMissing) {
            throw "Action registry is missing."
        }

        return $null
    }

    $registeredActionCommand = Get-Command -Name "Get-UckkOpsRegisteredAction" -ErrorAction SilentlyContinue

    if ($registeredActionCommand) {
        $found = Get-UckkOpsRegisteredAction -ActionId $ActionId -ErrorAction SilentlyContinue
        if ($found) {
            return $found
        }
    }

    $actionByIdCommand = Get-Command -Name "Get-UckkActionById" -ErrorAction SilentlyContinue

    if ($actionByIdCommand) {
        $found = Get-UckkActionById -Id $ActionId -ErrorAction SilentlyContinue
        if ($found) {
            return $found
        }
    }

    if ($Registry -is [hashtable]) {
        if ($Registry.ContainsKey($ActionId)) {
            return $Registry[$ActionId]
        }
    }

    if ($Registry -is [System.Collections.IDictionary]) {
        if ($Registry.Contains($ActionId)) {
            return $Registry[$ActionId]
        }
    }

    if ($Registry -is [array]) {
        foreach ($item in $Registry) {
            $id = Get-UckkOpsValue -Object $item -Name "id" -Default ""
            if ($id -eq $ActionId) {
                return $item
            }
        }
    }

    if ($Registry.PSObject.Properties.Name -contains $ActionId) {
        return $Registry.$ActionId
    }

    if ($ThrowIfMissing) {
        throw "Unknown action id: $ActionId"
    }

    return $null
}

# ---------------------------------------------------------------------------
# State helpers
# ---------------------------------------------------------------------------

function Assert-UckkOpsActionState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    if (-not $State) {
        throw "App state is required."
    }

    if (-not ($State.PSObject.Properties.Name -contains "Config")) {
        throw "App state must contain Config."
    }

    if (-not ($State.PSObject.Properties.Name -contains "ActionRegistry")) {
        Add-Member -InputObject $State -NotePropertyName "ActionRegistry" -NotePropertyValue $null -Force
    }

    if (-not ($State.PSObject.Properties.Name -contains "IsBusy")) {
        Add-Member -InputObject $State -NotePropertyName "IsBusy" -NotePropertyValue $false -Force
    }

    if (-not ($State.PSObject.Properties.Name -contains "LastResult")) {
        Add-Member -InputObject $State -NotePropertyName "LastResult" -NotePropertyValue $null -Force
    }

    if (-not ($State.PSObject.Properties.Name -contains "LastReportPath")) {
        Add-Member -InputObject $State -NotePropertyName "LastReportPath" -NotePropertyValue "" -Force
    }

    if (-not ($State.PSObject.Properties.Name -contains "LastLogPath")) {
        Add-Member -InputObject $State -NotePropertyName "LastLogPath" -NotePropertyValue "" -Force
    }
}

function Get-UckkOpsIsBusy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    if ($State.PSObject.Properties.Name -contains "IsBusy") {
        return [bool] $State.IsBusy
    }

    return $false
}

function Set-UckkOpsLastResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [object] $Result
    )

    if ($State.PSObject.Properties.Name -contains "LastResult") {
        $State.LastResult = $Result
    }

    $reportPath = Get-UckkOpsValue -Object $Result -Name "reportPath" -Default ""
    $logPath = Get-UckkOpsValue -Object $Result -Name "logPath" -Default ""

    if ($State.PSObject.Properties.Name -contains "LastReportPath") {
        $State.LastReportPath = [string] $reportPath
    }

    if ($State.PSObject.Properties.Name -contains "LastLogPath") {
        $State.LastLogPath = [string] $logPath
    }
}

function Get-UckkOpsActionButtons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State
    )

    if ($State.PSObject.Properties.Name -contains "ActionButtons") {
        return $State.ActionButtons
    }

    if ($State.PSObject.Properties.Name -contains "ControlsByActionId") {
        return $State.ControlsByActionId
    }

    return $null
}

function Get-UckkOpsControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $State,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($State.PSObject.Properties.Name -contains "Controls") {
        $controls = $State.Controls

        if ($controls -is [hashtable] -and $controls.ContainsKey($Name)) {
            return $controls[$Name]
        }

        if ($controls -is [System.Collections.IDictionary] -and $controls.Contains($Name)) {
            return $controls[$Name]
        }

        if ($controls.PSObject.Properties.Name -contains $Name) {
            return $controls.$Name
        }
    }

    if ($State.PSObject.Properties.Name -contains $Name) {
        return $State.$Name
    }

    return $null
}

# ---------------------------------------------------------------------------
# Safe list helper
# ---------------------------------------------------------------------------

function Get-UckkOpsListCount {
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
        return @($Value.Keys).Length
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
# Generic object helper
# ---------------------------------------------------------------------------

function Get-UckkOpsValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [object] $Object,

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter()]
        [object] $Default = $null
    )

    if (-not $Object) {
        return $Default
    }

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

    if ($Object.PSObject.Properties.Name -contains $Name) {
        return $Object.$Name
    }

    return $Default
}

