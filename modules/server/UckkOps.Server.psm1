#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Server module for UCKK Ops Console.

.DESCRIPTION
  Handles safe server operations for uckk.org:
  - test SSH connection;
  - inspect server state;
  - pull latest Git code on server;
  - sync server source to Moodle runtime;
  - run Moodle upgrade when explicitly requested;
  - purge Moodle caches;
  - reload PHP-FPM;
  - verify public pages;
  - run a controlled publish chain.

.NOTES
  This module must not run dangerous actions at import time.
  Every public action returns an ActionResult-shaped PSCustomObject.
#>

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

function Get-UckkServerConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $Path,

        [object] $Default = $null,

        [switch] $Required
    )

    $current = $Config

    foreach ($part in $Path.Split('.')) {
        if ($null -eq $current) {
            $current = $null
            break
        }

        if ($current -is [hashtable]) {
            if ($current.ContainsKey($part)) {
                $current = $current[$part]
                continue
            }

            $current = $null
            break
        }

        $prop = $current.PSObject.Properties[$part]
        if ($null -ne $prop) {
            $current = $prop.Value
            continue
        }

        $current = $null
        break
    }

    if ($null -eq $current -or ([string]$current).Trim() -eq '') {
        if ($Required) {
            throw "Configuration missing: $Path"
        }

        return $Default
    }

    return $current
}

function ConvertTo-UckkServerShellLiteral {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return "''"
    }

    $text = [string]$Value

    # Bash-safe single-quoted string.
    return "'" + ($text -replace "'", "'\''") + "'"
}

function ConvertTo-UckkServerSafeName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Value
    )

    $safe = $Value.ToLowerInvariant()
    $safe = $safe -replace '[^a-z0-9]+', '_'
    $safe = $safe.Trim('_')

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return 'server_action'
    }

    return $safe
}

function New-UckkServerStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Status,

        [string] $Summary = '',

        [string] $Detail = ''
    )

    [pscustomobject]@{
        name    = $Name
        status  = $Status
        summary = $Summary
        detail  = $Detail
    }
}

function New-UckkServerActionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [bool] $Success,

        [Parameter(Mandatory)]
        [string] $Status,

        [Parameter(Mandatory)]
        [string] $Action,

        [string] $Target = 'serveur',

        [int] $DangerLevel = 1,

        [string] $Mode = 'vérification',

        [Parameter(Mandatory)]
        [string] $Summary,

        [string[]] $Warnings = @(),

        [string[]] $Errors = @(),

        [string] $NextStep = 'Aucune action requise.',

        [string] $ReportPath = '',

        [string] $LogPath = '',

        [object] $Data = $null,

        [object[]] $Steps = @()
    )

    [pscustomobject]@{
        success     = $Success
        status      = $Status
        action      = $Action
        domain      = 'server'
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
        steps       = @($Steps)
    }
}

function Get-UckkServerReportsDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config
    )

    $dir = Get-UckkServerConfigValue -Config $Config -Path 'reports.dir' -Default './reports'
    return [string]$dir
}

function Get-UckkServerLogsDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config
    )

    $dir = Get-UckkServerConfigValue -Config $Config -Path 'logs.dir' -Default './logs'
    return [string]$dir
}

function New-UckkServerRunId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Action
    )

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $safe = ConvertTo-UckkServerSafeName -Value $Action
    return "${timestamp}_server_${safe}"
}

function ConvertTo-UckkServerMarkdownList {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]] $Items
    )

    if ($null -eq $Items -or $Items.Count -eq 0) {
        return 'Aucun.'
    }

    $lines = foreach ($item in $Items) {
        "- $item"
    }

    return ($lines -join [Environment]::NewLine)
}

function ConvertTo-UckkServerStepMarkdown {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object[]] $Steps
    )

    if ($null -eq $Steps -or $Steps.Count -eq 0) {
        return 'Aucune.'
    }

    $lines = foreach ($step in $Steps) {
        $line = "- $($step.status) — $($step.name)"
        if (-not [string]::IsNullOrWhiteSpace([string]$step.summary)) {
            $line += " — $($step.summary)"
        }
        $line
    }

    return ($lines -join [Environment]::NewLine)
}

function ConvertTo-UckkServerMaskedText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string] $Text
    )

    if ($null -eq $Text) {
        return ''
    }

    $masked = $Text

    $patterns = @(
        '(?i)(password\s*=\s*)[^;\s]+',
        '(?i)(passwd\s*=\s*)[^;\s]+',
        '(?i)(token\s*=\s*)[^;\s]+',
        '(?i)(secret\s*=\s*)[^;\s]+',
        '(?i)(api[_-]?key\s*=\s*)[^;\s]+',
        '(?i)(private[_-]?key\s*=\s*)[^;\s]+'
    )

    foreach ($pattern in $patterns) {
        $masked = $masked -replace $pattern, '$1[masqué]'
    }

    return $masked
}

function Write-UckkServerLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)][AllowEmptyString()][AllowEmptyCollection()]
        [string[]] $Lines
    )

    $logsDir = Get-UckkServerLogsDir -Config $Config
    New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

    $path = Join-Path $logsDir "$RunId.log"

    $content = @()
    $content += "UCKK Ops Console — Server log"
    $content += "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $content += ""
    $content += ($Lines | ForEach-Object { ConvertTo-UckkServerMaskedText -Text $_ })

    Set-Content -Path $path -Value ($content -join [Environment]::NewLine) -Encoding UTF8

    return $path
}

function Write-UckkServerReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [object] $Result
    )

    $reportsDir = Get-UckkServerReportsDir -Config $Config
    New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null

    $path = Join-Path $reportsDir "$RunId.md"

    $warnings = ConvertTo-UckkServerMarkdownList -Items $Result.warnings
    $errors = ConvertTo-UckkServerMarkdownList -Items $Result.errors
    $steps = ConvertTo-UckkServerStepMarkdown -Steps $Result.steps

    $dataText = 'Non applicable.'
    if ($null -ne $Result.data) {
        try {
$dataText = ($Result.data | ConvertTo-Json -Depth 8)
        } catch {
            $dataText = [string]$Result.data
        }
    }

    $report = @"
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

Serveur : $(Get-UckkServerConfigValue -Config $Config -Path 'server.sshTarget' -Default 'non configuré')

## Étapes exécutées

$steps

## Changements

Non applicable ou voir le détail de l action.

## Avertissements

$warnings

## Erreurs

$errors

## Résultat final

$($Result.status)

## Prochaine étape

$($Result.nextStep)

## Détail technique

Rapport : $path

Log technique : $($Result.logPath)

Données :

```json
$dataText
````

"@

Set-Content -Path $path -Value $report -Encoding UTF8

return $path

}

function Complete-UckkServerResult {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config,

    [Parameter(Mandatory)]
    [object] $Result,

    [string[]] $LogLines = @()
)

$runId = New-UckkServerRunId -Action $Result.action

try {
    $logPath = Write-UckkServerLog -Config $Config -RunId $runId -Lines $LogLines
    $Result.logPath = $logPath
} catch {
    $Result.warnings += "Le log technique n a pas pu être écrit : $($_.Exception.Message)"
}

try {
    $reportPath = Write-UckkServerReport -Config $Config -RunId $runId -Result $Result
    $Result.reportPath = $reportPath
} catch {
    $Result.warnings += "Le rapport n a pas pu être écrit : $($_.Exception.Message)"
}

return $Result

}

function Invoke-UckkServerSshCommand {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config,

    [Parameter(Mandatory)]
    [string] $RemoteCommand,

    [int] $TimeoutSeconds = 120
)

$sshTarget = Get-UckkServerConfigValue -Config $Config -Path 'server.sshTarget' -Required

$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = 'ssh'
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true
$psi.ArgumentList.Add($sshTarget)
$psi.ArgumentList.Add($RemoteCommand)

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $psi

try {
    [void]$process.Start(); $stdoutTask = $process.StandardOutput.ReadToEndAsync(); $stderrTask = $process.StandardError.ReadToEndAsync()
} catch {
    return [pscustomobject]@{
        exitCode = 127
        stdout   = ''
        stderr   = "Unable to start ssh: $($_.Exception.Message)"
        timedOut = $false
        command  = $RemoteCommand
    }
}

$completed = $process.WaitForExit($TimeoutSeconds * 1000)

if (-not $completed) {
    try {
        $process.Kill($true); [void]$process.WaitForExit(5000)
    } catch {
        # Ignore kill failure.
    }

    return [pscustomobject]@{
        exitCode = 124
        stdout   = $stdoutTask.Result
        stderr   = (($stderrTask.Result), "SSH command timed out after $TimeoutSeconds seconds." -join [Environment]::NewLine)
        timedOut = $true
        command  = $RemoteCommand
    }
}

$stdout = $stdoutTask.Result
$stderr = $stderrTask.Result

return [pscustomobject]@{
    exitCode = $process.ExitCode
    stdout   = $stdout
    stderr   = $stderr
    timedOut = $false
    command  = $RemoteCommand
}

}

function Test-UckkServerConfirmed {
[CmdletBinding()]
param(
[bool] $Confirmed,

    [Parameter(Mandatory)]
    [string] $Action,

    [Parameter(Mandatory)]
    [string] $Target,

    [int] $DangerLevel = 5
)

if ($Confirmed) {
    return $null
}

return New-UckkServerActionResult `
    -Success $false `
    -Status 'Annulé' `
    -Action $Action `
    -Target $Target `
    -DangerLevel $DangerLevel `
    -Mode 'annulation' `
    -Summary 'Annulé — aucune modification n a été faite.' `
    -NextStep 'Relancer l action seulement après confirmation explicite.'

}

function Get-UckkServerExcludeArgs {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config
)

$patterns = Get-UckkServerConfigValue -Config $Config -Path 'sync.excludePatterns' -Default @()

$args = @()

foreach ($pattern in @($patterns)) {
    if ([string]::IsNullOrWhiteSpace([string]$pattern)) {
        continue
    }

    $args += "--exclude=$(ConvertTo-UckkServerShellLiteral -Value $pattern)"
}

return ($args -join ' ')

}

# ---------------------------------------------------------------------------

# Public actions

# ---------------------------------------------------------------------------

function Test-UckkServerConnection {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config
)

$action = 'Tester connexion serveur'
$steps = @()
$logs = @()

try {
    $sshTarget = Get-UckkServerConfigValue -Config $Config -Path 'server.sshTarget' -Required
    $steps += New-UckkServerStep -Name 'Lire configuration serveur' -Status 'Réussi' -Summary $sshTarget

    $command = "printf 'UCKK_SERVER_OK\n'; hostname; whoami"
    $result = Invoke-UckkServerSshCommand -Config $Config -RemoteCommand $command -TimeoutSeconds 30

    $logs += "SSH target: $sshTarget"
    $logs += "Remote command:"
    $logs += $command
    $logs += "Exit code: $($result.exitCode)"
    $logs += "STDOUT:"
    $logs += $result.stdout
    $logs += "STDERR:"
    $logs += $result.stderr

    if ($result.exitCode -eq 0 -and $result.stdout -match 'UCKK_SERVER_OK') {
        $steps += New-UckkServerStep -Name 'Tester SSH' -Status 'Réussi' -Summary 'La connexion serveur fonctionne.'

        $final = New-UckkServerActionResult `
            -Success $true `
            -Status 'Réussi' `
            -Action $action `
            -Target 'serveur' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'Réussi — la connexion serveur fonctionne.' `
            -NextStep 'Aucune action requise.' `
            -Data @{
                sshTarget = $sshTarget
                stdout    = $result.stdout
            } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
    }

    $steps += New-UckkServerStep -Name 'Tester SSH' -Status 'Échoué' -Summary 'La connexion serveur ne fonctionne pas.'

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'serveur' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'L action a échoué. Cause probable : la connexion SSH au serveur ne fonctionne pas.' `
        -Errors @("SSH a retourné le code $($result.exitCode).") `
        -NextStep 'Vérifier la configuration serveur ou la connexion SSH.' `
        -Data @{
            sshTarget = $sshTarget
            exitCode  = $result.exitCode
            stderr    = $result.stderr
        } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
} catch {
    $steps += New-UckkServerStep -Name 'Tester connexion serveur' -Status 'Échoué' -Summary $_.Exception.Message

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'serveur' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'L action a échoué. Cause probable : la configuration serveur est absente ou invalide.' `
        -Errors @($_.Exception.Message) `
        -NextStep 'Vérifier config/uckk-ops-console.config.json.' `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines @($_.Exception.ToString())
}

}

function Test-UckkServerState {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config
)

$action = 'Vérifier état serveur'
$steps = @()
$logs = @()


try {
    $source = Get-UckkServerConfigValue -Config $Config -Path 'paths.serverMoodleSource' -Required
    $runtime = Get-UckkServerConfigValue -Config $Config -Path 'paths.serverMoodleRuntime' -Required
    $root = Get-UckkServerConfigValue -Config $Config -Path 'paths.serverMoodleRoot' -Required

    $sourceQ = ConvertTo-UckkServerShellLiteral -Value $source
    $runtimeQ = ConvertTo-UckkServerShellLiteral -Value $runtime
    $rootQ = ConvertTo-UckkServerShellLiteral -Value $root

    $command = @"
set -u
echo "server_state_start"
echo "hostname=`$(hostname)"
echo "user=`$(whoami)"
echo "source_exists=`$(test -d $sourceQ && echo yes || echo no)"
echo "runtime_exists=`$(test -d $runtimeQ && echo yes || echo no)"
echo "moodle_root_exists=`$(test -d $rootQ && echo yes || echo no)"
if test -d $sourceQ; then
cd $sourceQ
echo "git_branch=`$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
echo "git_commit=`$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "git_status_start"
git status --short 2>/dev/null || true
echo "git_status_end"
fi
echo "server_state_end"
"@

    $result = Invoke-UckkServerSshCommand -Config $Config -RemoteCommand $command -TimeoutSeconds 60

    $logs += "Remote command:"
    $logs += $command
    $logs += "Exit code: $($result.exitCode)"
    $logs += "STDOUT:"
    $logs += $result.stdout
    $logs += "STDERR:"
    $logs += $result.stderr

    if ($result.exitCode -eq 0) {
        $steps += New-UckkServerStep -Name 'Lire état serveur' -Status 'Réussi' -Summary 'L état serveur a été lu sans modification.'

        $warnings = @()
        if ($result.stdout -match 'source_exists=no') {
            $warnings += "La source serveur est introuvable : $source"
        }
        if ($result.stdout -match 'runtime_exists=no') {
            $warnings += "Le dossier exécuté par Moodle serveur est introuvable : $runtime"
        }
        if ($result.stdout -match 'moodle_root_exists=no') {
            $warnings += "La racine Moodle serveur est introuvable : $root"
        }

        $status = if ($warnings.Count -gt 0) { 'Réussi avec avertissements' } else { 'Réussi' }

        $final = New-UckkServerActionResult `
            -Success $true `
            -Status $status `
            -Action $action `
            -Target 'serveur' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'Réussi — l état serveur a été vérifié sans modification.' `
            -Warnings $warnings `
            -NextStep 'Lire les avertissements si présents avant toute publication.' `
            -Data @{
                source  = $source
                runtime = $runtime
                root    = $root
                stdout  = $result.stdout
            } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
    }

    $steps += New-UckkServerStep -Name 'Lire état serveur' -Status 'Échoué' -Summary 'La commande serveur a échoué.'

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'serveur' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'L action a échoué. Cause probable : impossible de lire l état serveur.' `
        -Errors @("Code de retour SSH : $($result.exitCode)") `
        -NextStep 'Tester la connexion serveur puis relancer la vérification.' `
        -Data @{
            exitCode = $result.exitCode
            stderr   = $result.stderr
        } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
} catch {
    $steps += New-UckkServerStep -Name 'Vérifier préconditions' -Status 'Échoué' -Summary $_.Exception.Message

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'serveur' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'L action a échoué. Cause probable : configuration serveur incomplète.' `
        -Errors @($_.Exception.Message) `
        -NextStep 'Vérifier les chemins serveur dans la configuration.' `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines @($_.Exception.ToString())
}

}

function Update-UckkServerSourceFromGit {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config,

    [switch] $Confirmed
)

$action = 'Récupérer dernier code sur serveur'
$notConfirmed = Test-UckkServerConfirmed -Confirmed:$Confirmed -Action $action -Target 'source serveur' -DangerLevel 5
if ($null -ne $notConfirmed) {
    return Complete-UckkServerResult -Config $Config -Result $notConfirmed -LogLines @('Action cancelled before SSH command.')
}

$steps = @()
$logs = @()

try {
    $source = Get-UckkServerConfigValue -Config $Config -Path 'paths.serverMoodleSource' -Required
    $branch = Get-UckkServerConfigValue -Config $Config -Path 'git.mainBranch' -Default 'main'
    $remote = Get-UckkServerConfigValue -Config $Config -Path 'git.remoteName' -Default 'origin'

    $sourceQ = ConvertTo-UckkServerShellLiteral -Value $source
    $branchQ = ConvertTo-UckkServerShellLiteral -Value $branch
    $remoteQ = ConvertTo-UckkServerShellLiteral -Value $remote

    $command = @"

set -e
cd $sourceQ
echo "before_branch=`$(git rev-parse --abbrev-ref HEAD)"
echo "before_commit=`$(git rev-parse --short HEAD)"
echo "status_before_start"
git status --short
echo "status_before_end"
git fetch $remoteQ
git pull --ff-only $remoteQ $branchQ
echo "after_branch=`$(git rev-parse --abbrev-ref HEAD)"
echo "after_commit=`$(git rev-parse --short HEAD)"
echo "status_after_start"
git status --short
echo "status_after_end"
"@

    $result = Invoke-UckkServerSshCommand -Config $Config -RemoteCommand $command -TimeoutSeconds 180

    $logs += "Remote command:"
    $logs += $command
    $logs += "Exit code: $($result.exitCode)"
    $logs += "STDOUT:"
    $logs += $result.stdout
    $logs += "STDERR:"
    $logs += $result.stderr

    if ($result.exitCode -eq 0) {
        $steps += New-UckkServerStep -Name 'Récupérer dernier code sur serveur' -Status 'Réussi' -Summary 'La source serveur a été mise à jour depuis Git.'

        $final = New-UckkServerActionResult `
            -Success $true `
            -Status 'Réussi' `
            -Action $action `
            -Target 'source serveur' `
            -DangerLevel 5 `
            -Mode 'publication' `
            -Summary 'Réussi — le dernier code a été récupéré sur le serveur.' `
            -NextStep 'Synchroniser source serveur vers Moodle serveur.' `
            -Data @{
                source = $source
                branch = $branch
                remote = $remote
                stdout = $result.stdout
            } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
    }

    $steps += New-UckkServerStep -Name 'Récupérer dernier code sur serveur' -Status 'Échoué' -Summary 'Git pull a échoué sur le serveur.'

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'source serveur' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : Git ne peut pas mettre à jour la source serveur.' `
        -Errors @("Code de retour SSH : $($result.exitCode)") `
        -NextStep 'Lire le rapport et vérifier l état Git serveur.' `
        -Data @{
            exitCode = $result.exitCode
            stderr = $result.stderr
        } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
} catch {
    $steps += New-UckkServerStep -Name 'Récupérer dernier code sur serveur' -Status 'Échoué' -Summary $_.Exception.Message

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'source serveur' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : configuration Git ou serveur incomplète.' `
        -Errors @($_.Exception.Message) `
        -NextStep 'Vérifier la configuration Git et serveur.' `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines @($_.Exception.ToString())
}

}

function Sync-UckkServerSourceToMoodleRuntime {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config,

    [switch] $Confirmed
)

$action = 'Synchroniser source serveur vers Moodle serveur'
$notConfirmed = Test-UckkServerConfirmed -Confirmed:$Confirmed -Action $action -Target 'dossier exécuté par Moodle serveur' -DangerLevel 5
if ($null -ne $notConfirmed) {
    return Complete-UckkServerResult -Config $Config -Result $notConfirmed -LogLines @('Action cancelled before SSH command.')
}

$steps = @()
$logs = @()

try {
    $source = Get-UckkServerConfigValue -Config $Config -Path 'paths.serverMoodleSource' -Required
    $runtime = Get-UckkServerConfigValue -Config $Config -Path 'paths.serverMoodleRuntime' -Required
    $excludeArgs = Get-UckkServerExcludeArgs -Config $Config

    $sourceSlash = $source.TrimEnd('/') + '/'
    $runtimeSlash = $runtime.TrimEnd('/') + '/'

    $sourceQ = ConvertTo-UckkServerShellLiteral -Value $sourceSlash
    $runtimeQ = ConvertTo-UckkServerShellLiteral -Value $runtimeSlash

    $command = @"

set -e
test -d $sourceQ
test -d $runtimeQ
sudo -n rsync -a --no-owner --no-group --omit-dir-times --stats --human-readable $excludeArgs $sourceQ $runtimeQ
echo "sync_complete=yes"
"@

    $result = Invoke-UckkServerSshCommand -Config $Config -RemoteCommand $command -TimeoutSeconds 300

    $logs += "Remote command:"
    $logs += $command
    $logs += "Exit code: $($result.exitCode)"
    $logs += "STDOUT:"
    $logs += $result.stdout
    $logs += "STDERR:"
    $logs += $result.stderr

    if ($result.exitCode -eq 0) {
        $steps += New-UckkServerStep -Name 'Synchroniser vers runtime Moodle serveur' -Status 'Réussi' -Summary 'Les fichiers ont été copiés vers le dossier exécuté par Moodle serveur.'

        $final = New-UckkServerActionResult `
            -Success $true `
            -Status 'Réussi' `
            -Action $action `
            -Target 'dossier exécuté par Moodle serveur' `
            -DangerLevel 5 `
            -Mode 'publication' `
            -Summary 'Réussi — la source serveur a été synchronisée vers Moodle serveur.' `
            -NextStep 'Purger les caches serveur, puis vérifier uckk.org.' `
            -Data @{
                source = $sourceSlash
                runtime = $runtimeSlash
                excludeArgs = $excludeArgs
            } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
    }

    $steps += New-UckkServerStep -Name 'Synchroniser vers runtime Moodle serveur' -Status 'Échoué' -Summary 'La synchronisation rsync a échoué.'

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'dossier exécuté par Moodle serveur' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : rsync n a pas pu copier la source vers Moodle serveur.' `
        -Errors @("Code de retour SSH : $($result.exitCode)") `
        -NextStep 'Lire le log technique et vérifier les chemins serveur.' `
        -Data @{
            exitCode = $result.exitCode
            stderr = $result.stderr
        } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
} catch {
    $steps += New-UckkServerStep -Name 'Synchroniser vers runtime Moodle serveur' -Status 'Échoué' -Summary $_.Exception.Message

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'dossier exécuté par Moodle serveur' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : configuration des chemins serveur incomplète.' `
        -Errors @($_.Exception.Message) `
        -NextStep 'Vérifier paths.serverMoodleSource et paths.serverMoodleRuntime.' `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines @($_.Exception.ToString())
}


}

function Invoke-UckkServerMoodleUpgrade {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config,

    [switch] $Confirmed
)

$action = 'Mettre à jour Moodle serveur'
$notConfirmed = Test-UckkServerConfirmed -Confirmed:$Confirmed -Action $action -Target 'base Moodle serveur' -DangerLevel 6
if ($null -ne $notConfirmed) {
    return Complete-UckkServerResult -Config $Config -Result $notConfirmed -LogLines @('Action cancelled before SSH command.')
}

$steps = @()
$logs = @()
try {
    $root = Get-UckkServerConfigValue -Config $Config -Path 'paths.serverMoodleRoot' -Required
    $php = Get-UckkServerConfigValue -Config $Config -Path 'moodle.serverPhpPath' -Default 'php'
    $upgradeScript = Get-UckkServerConfigValue -Config $Config -Path 'moodle.upgradeScript' -Default 'admin/cli/upgrade.php'

    $rootQ = ConvertTo-UckkServerShellLiteral -Value $root
    $scriptQ = ConvertTo-UckkServerShellLiteral -Value $upgradeScript

    $command = @"

set -e
cd $rootQ
$php $scriptQ --non-interactive
echo "moodle_upgrade_complete=yes"
"@

    $result = Invoke-UckkServerSshCommand -Config $Config -RemoteCommand $command -TimeoutSeconds 600

    $logs += "Remote command:"
    $logs += $command
    $logs += "Exit code: $($result.exitCode)"
    $logs += "STDOUT:"
    $logs += $result.stdout
    $logs += "STDERR:"
    $logs += $result.stderr

    if ($result.exitCode -eq 0) {
        $steps += New-UckkServerStep -Name 'Mettre à jour Moodle serveur' -Status 'Réussi' -Summary 'La mise à jour Moodle serveur est terminée.'

        $final = New-UckkServerActionResult `
            -Success $true `
            -Status 'Réussi' `
            -Action $action `
            -Target 'base Moodle serveur' `
            -DangerLevel 6 `
            -Mode 'application' `
            -Summary 'Réussi — Moodle serveur a été mis à jour.' `
            -NextStep 'Purger les caches serveur puis vérifier uckk.org.' `
            -Data @{
                moodleRoot = $root
                script = $upgradeScript
                stdout = $result.stdout
            } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
    }

    $steps += New-UckkServerStep -Name 'Mettre à jour Moodle serveur' -Status 'Échoué' -Summary 'La mise à jour Moodle a échoué.'

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'base Moodle serveur' `
        -DangerLevel 6 `
        -Mode 'application' `
        -Summary 'L action a échoué. Cause probable : Moodle n a pas pu appliquer la mise à jour serveur.' `
        -Errors @("Code de retour SSH : $($result.exitCode)") `
        -NextStep 'Lire le rapport et le log technique avant de relancer.' `
        -Data @{
            exitCode = $result.exitCode
            stderr = $result.stderr
        } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
} catch {
    $steps += New-UckkServerStep -Name 'Mettre à jour Moodle serveur' -Status 'Échoué' -Summary $_.Exception.Message

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'base Moodle serveur' `
        -DangerLevel 6 `
        -Mode 'application' `
        -Summary 'L action a échoué. Cause probable : configuration Moodle serveur incomplète.' `
        -Errors @($_.Exception.Message) `
        -NextStep 'Vérifier paths.serverMoodleRoot et moodle.upgradeScript.' `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines @($_.Exception.ToString())
}

}

function Clear-UckkServerMoodleCaches {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config,

    [switch] $Confirmed
)

$action = 'Purger les caches serveur'
$notConfirmed = Test-UckkServerConfirmed -Confirmed:$Confirmed -Action $action -Target 'caches Moodle serveur' -DangerLevel 5
if ($null -ne $notConfirmed) {
    return Complete-UckkServerResult -Config $Config -Result $notConfirmed -LogLines @('Action cancelled before SSH command.')
}

$steps = @()
$logs = @()

try {
    $root = Get-UckkServerConfigValue -Config $Config -Path 'paths.serverMoodleRoot' -Required
    $php = Get-UckkServerConfigValue -Config $Config -Path 'moodle.serverPhpPath' -Default 'php'
    $purgeScript = Get-UckkServerConfigValue -Config $Config -Path 'moodle.purgeCachesScript' -Default 'admin/cli/purge_caches.php'

    $rootQ = ConvertTo-UckkServerShellLiteral -Value $root
    $scriptQ = ConvertTo-UckkServerShellLiteral -Value $purgeScript

    $command = @"

set -e
cd $rootQ
$php $scriptQ
echo "purge_caches_complete=yes"
"@

    $result = Invoke-UckkServerSshCommand -Config $Config -RemoteCommand $command -TimeoutSeconds 180

    $logs += "Remote command:"
    $logs += $command
    $logs += "Exit code: $($result.exitCode)"
    $logs += "STDOUT:"
    $logs += $result.stdout
    $logs += "STDERR:"
    $logs += $result.stderr

    if ($result.exitCode -eq 0) {
        $steps += New-UckkServerStep -Name 'Purger les caches serveur' -Status 'Réussi' -Summary 'Les caches Moodle serveur ont été purgés.'

        $final = New-UckkServerActionResult `
            -Success $true `
            -Status 'Réussi' `
            -Action $action `
            -Target 'caches Moodle serveur' `
            -DangerLevel 5 `
            -Mode 'publication' `
            -Summary 'Réussi — les caches Moodle serveur ont été purgés.' `
            -NextStep 'Vérifier uckk.org.' `
            -Data @{
                moodleRoot = $root
                script = $purgeScript
                stdout = $result.stdout
            } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
    }

    $steps += New-UckkServerStep -Name 'Purger les caches serveur' -Status 'Échoué' -Summary 'La purge des caches a échoué.'

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'caches Moodle serveur' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : Moodle n a pas pu purger les caches serveur.' `
        -Errors @("Code de retour SSH : $($result.exitCode)") `
        -NextStep 'Lire le rapport et vérifier Moodle serveur.' `
        -Data @{
            exitCode = $result.exitCode
            stderr = $result.stderr
        } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
} catch {
    $steps += New-UckkServerStep -Name 'Purger les caches serveur' -Status 'Échoué' -Summary $_.Exception.Message

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'caches Moodle serveur' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : configuration Moodle serveur incomplète.' `
        -Errors @($_.Exception.Message) `
        -NextStep 'Vérifier paths.serverMoodleRoot et moodle.purgeCachesScript.' `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines @($_.Exception.ToString())
}

}

function Invoke-UckkServerPhpFpmReload {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config,

    [switch] $Confirmed
)

$action = 'Recharger PHP-FPM'
$notConfirmed = Test-UckkServerConfirmed -Confirmed:$Confirmed -Action $action -Target 'service PHP-FPM serveur' -DangerLevel 5
if ($null -ne $notConfirmed) {
    return Complete-UckkServerResult -Config $Config -Result $notConfirmed -LogLines @('Action cancelled before SSH command.')
}

$steps = @()
$logs = @()

try {
    $service = Get-UckkServerConfigValue -Config $Config -Path 'server.phpFpmService' -Default 'php8.3-fpm'
    $serviceQ = ConvertTo-UckkServerShellLiteral -Value $service

    $command = @"

set -e
sudo systemctl reload $serviceQ
sudo systemctl is-active $serviceQ
echo "php_fpm_reload_complete=yes"
"@

    $result = Invoke-UckkServerSshCommand -Config $Config -RemoteCommand $command -TimeoutSeconds 120

    $logs += "Remote command:"
    $logs += $command
    $logs += "Exit code: $($result.exitCode)"
    $logs += "STDOUT:"
    $logs += $result.stdout
    $logs += "STDERR:"
    $logs += $result.stderr

    if ($result.exitCode -eq 0) {
        $steps += New-UckkServerStep -Name 'Recharger PHP-FPM' -Status 'Réussi' -Summary "Le service $service a été rechargé."

        $final = New-UckkServerActionResult `
            -Success $true `
            -Status 'Réussi' `
            -Action $action `
            -Target 'service PHP-FPM serveur' `
            -DangerLevel 5 `
            -Mode 'publication' `
            -Summary "Réussi — PHP-FPM a été rechargé : $service." `
            -NextStep 'Vérifier uckk.org.' `
            -Data @{
                service = $service
                stdout = $result.stdout
            } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
    }

    $steps += New-UckkServerStep -Name 'Recharger PHP-FPM' -Status 'Échoué' -Summary "Le service $service n a pas pu être rechargé."

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'service PHP-FPM serveur' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : PHP-FPM n a pas pu être rechargé.' `
        -Errors @("Code de retour SSH : $($result.exitCode)") `
        -NextStep 'Lire le log technique et vérifier le service PHP-FPM.' `
        -Data @{
            service = $service
            exitCode = $result.exitCode
            stderr = $result.stderr
        } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
} catch {
    $steps += New-UckkServerStep -Name 'Recharger PHP-FPM' -Status 'Échoué' -Summary $_.Exception.Message

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'service PHP-FPM serveur' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : configuration PHP-FPM incomplète.' `
        -Errors @($_.Exception.Message) `
        -NextStep 'Vérifier server.phpFpmService.' `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines @($_.Exception.ToString())
}

}

function Test-UckkServerPublicPages {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config
)

$action = 'Vérifier uckk.org — UCKK / UCC / Math'
$steps = @()
$logs = @()
$warnings = @()
$errors = @()

try {
    $urls = @(
        Get-UckkServerConfigValue -Config $Config -Path 'urls.serverBase' -Required
        Get-UckkServerConfigValue -Config $Config -Path 'urls.serverCourseIndex' -Default ''
        Get-UckkServerConfigValue -Config $Config -Path 'urls.serverMediatheque' -Default ''
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }

    $pageResults = @()

    foreach ($url in $urls) {

        try {
            $logs += "Testing URL: $url"

            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 5

            $statusCode = [int]$response.StatusCode
            $ok = $statusCode -ge 200 -and $statusCode -lt 400

            $pageResults += [pscustomobject]@{
                url        = $url
                statusCode = $statusCode
                ok         = $ok
                length     = $response.Content.Length
            }

            if ($ok) {
                $steps += New-UckkServerStep -Name "Tester $url" -Status 'Réussi' -Summary "HTTP $statusCode"
            } else {
                $warnings += "La page répond avec un statut inattendu : $url — HTTP $statusCode"
                $steps += New-UckkServerStep -Name "Tester $url" -Status 'Réussi avec avertissements' -Summary "HTTP $statusCode"
            }
        } catch {
            $errors += "La page ne répond pas correctement : $url — $($_.Exception.Message)"
            $steps += New-UckkServerStep -Name "Tester $url" -Status 'Échoué' -Summary $_.Exception.Message

            $pageResults += [pscustomobject]@{
                url        = $url
                statusCode = 0
                ok         = $false
                length     = 0
                error      = $_.Exception.Message
            }
        }
}

    $serverBase = [string](Get-UckkServerConfigValue -Config $Config -Path 'urls.serverBase' -Required)
    $publicFacades = @(Get-UckkServerConfigValue -Config $Config -Path 'publicFacades.sites' -Default @())

    if ($publicFacades.Count -eq 0) {
        $publicFacades = @(
            [pscustomobject]@{ id = 'uckk'; label = 'UCKK'; theme = 'uckk'; expectedMarker = 'Univers-Cité King Klown' },
            [pscustomobject]@{ id = 'ucc'; label = 'UCC — Univers-Cité Catho'; theme = 'ucc'; expectedMarker = 'Univers-Cité Catho' },
            [pscustomobject]@{ id = 'math'; label = 'Math — Univers-Cité des mathématiques'; theme = 'ucmath'; expectedMarker = 'Univers-Cité des mathématiques' }
        )
        $warnings += 'publicFacades.sites absent : vérification serveur avec les valeurs UCKK/UCC/Math par défaut.'
    }

    foreach ($facade in $publicFacades) {
        $facadeId = [string](Get-UckkServerConfigValue -Config $facade -Path 'id' -Default '')
        $facadeLabel = [string](Get-UckkServerConfigValue -Config $facade -Path 'label' -Default $facadeId)
        $facadeTheme = [string](Get-UckkServerConfigValue -Config $facade -Path 'theme' -Default '')
        $facadeMarker = [string](Get-UckkServerConfigValue -Config $facade -Path 'expectedMarker' -Default '')

        if ([string]::IsNullOrWhiteSpace($facadeId) -or [string]::IsNullOrWhiteSpace($facadeTheme)) {
            $errors += 'Définition de façade serveur incomplète : id/theme manquant.'
            continue
        }

        $facadeUrl = $serverBase.TrimEnd('/') + '/?theme=' + [System.Uri]::EscapeDataString($facadeTheme)

        try {
            $logs += "Testing public facade: $facadeLabel — $facadeUrl"
            $response = Invoke-WebRequest -Uri $facadeUrl -UseBasicParsing -TimeoutSec 30 -MaximumRedirection 5
            $statusCode = [int]$response.StatusCode
            $httpOk = ($statusCode -ge 200 -and $statusCode -lt 400)
            $markerOk = $true

            if (-not [string]::IsNullOrWhiteSpace($facadeMarker)) {
                $markerOk = ([string]$response.Content).Contains($facadeMarker)
            }

            $ok = ($httpOk -and $markerOk)

            $pageResults += [pscustomobject]@{
                kind       = 'facade'
                facade     = $facadeId
                label      = $facadeLabel
                theme      = $facadeTheme
                marker     = $facadeMarker
                markerOk   = $markerOk
                url        = $facadeUrl
                statusCode = $statusCode
                ok         = $ok
                length     = $response.Content.Length
            }

            if ($ok) {
                $steps += New-UckkServerStep -Name "Tester façade $facadeLabel" -Status 'Réussi' -Summary "HTTP $statusCode — identité attendue trouvée."
            }
            elseif (-not $markerOk) {
                $errors += "La façade $facadeLabel répond mais ne contient pas son marqueur d identité attendu : $facadeMarker"
                $steps += New-UckkServerStep -Name "Tester façade $facadeLabel" -Status 'Échoué' -Summary "Marqueur absent : $facadeMarker"
            }
            else {
                $errors += "La façade $facadeLabel répond avec un statut inattendu : HTTP $statusCode"
                $steps += New-UckkServerStep -Name "Tester façade $facadeLabel" -Status 'Échoué' -Summary "HTTP $statusCode"
            }
        }
        catch {
            $errors += "La façade $facadeLabel ne répond pas correctement : $facadeUrl — $($_.Exception.Message)"
            $steps += New-UckkServerStep -Name "Tester façade $facadeLabel" -Status 'Échoué' -Summary $_.Exception.Message

            $pageResults += [pscustomobject]@{
                kind       = 'facade'
                facade     = $facadeId
                label      = $facadeLabel
                theme      = $facadeTheme
                marker     = $facadeMarker
                markerOk   = $false
                url        = $facadeUrl
                statusCode = 0
                ok         = $false
                length     = 0
                error      = $_.Exception.Message
            }
        }
    }

    $mediathequeUrl = Get-UckkServerConfigValue -Config $Config -Path 'urls.serverMediatheque' -Default ''
    if (-not [string]::IsNullOrWhiteSpace($mediathequeUrl)) {
        $warnings += 'La Médiathèque peut charger les cartes par AJAX : une vérification navigateur reste nécessaire.'
    }

    if ($errors.Count -gt 0) {
        $final = New-UckkServerActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action $action `
            -Target 'uckk.org' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'L action a échoué. Cause probable : une ou plusieurs pages publiques ne répondent pas correctement.' `
            -Warnings $warnings `
            -Errors $errors `
            -NextStep 'Vérifier les thèmes installés, le changement de thème par URL et les pages publiques avant de republier.' `
            -Data @{ pages = $pageResults } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
    }

    $status = if ($warnings.Count -gt 0) { 'Réussi avec avertissements' } else { 'Réussi' }
    $summary = if ($warnings.Count -gt 0) {
        'Réussi avec avertissements — les pages publiques et les trois façades répondent, mais certaines vérifications navigateur restent nécessaires.'
    } else {
        'Réussi — les pages publiques et les trois façades UCKK/UCC/Math répondent.'
    }

    $final = New-UckkServerActionResult `
        -Success $true `
        -Status $status `
        -Action $action `
        -Target 'uckk.org' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary $summary `
        -Warnings $warnings `
        -NextStep 'Ouvrir les pages concernées dans le navigateur si l affichage doit être confirmé.' `
        -Data @{ pages = $pageResults } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs
} catch {
    $steps += New-UckkServerStep -Name 'Vérifier uckk.org' -Status 'Échoué' -Summary $_.Exception.Message

    $final = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'uckk.org' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'L action a échoué. Cause probable : configuration des URLs serveur incomplète.' `
        -Errors @($_.Exception.Message) `
        -NextStep 'Vérifier urls.serverBase, urls.serverCourseIndex et urls.serverMediatheque.' `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $final -LogLines @($_.Exception.ToString())
}

}

function Invoke-UckkServerPublish {
[CmdletBinding()]
param(
[Parameter(Mandatory)]
[object] $Config,

    [switch] $Confirmed,

    [switch] $RunMoodleUpgrade,

    [switch] $ReloadPhpFpm
)

$action = 'Publier sur serveur'
$notConfirmed = Test-UckkServerConfirmed -Confirmed:$Confirmed -Action $action -Target 'uckk.org' -DangerLevel 5
if ($null -ne $notConfirmed) {
    return Complete-UckkServerResult -Config $Config -Result $notConfirmed -LogLines @('Publish chain cancelled before any server change.')
}

$steps = @()
$logs = @()
$warnings = @()
$errors = @()
$subResults = @()

$steps += New-UckkServerStep -Name 'Publier sur serveur' -Status 'En cours' -Summary 'Chaîne de publication démarrée.'

$connection = Test-UckkServerConnection -Config $Config
$subResults += $connection
$logs += "Connection result: $($connection.status) — $($connection.summary)"

if (-not $connection.success) {
    $steps += New-UckkServerStep -Name 'Tester connexion serveur' -Status 'Échoué' -Summary $connection.summary
    $errors += 'Publication arrêtée : la connexion serveur a échoué.'

    $finalFail = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'uckk.org' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : la connexion serveur ne fonctionne pas.' `
        -Warnings $warnings `
        -Errors $errors `
        -NextStep 'Corriger la connexion serveur, puis relancer la publication.' `
        -Data @{ subResults = $subResults } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $finalFail -LogLines $logs
}

$steps += New-UckkServerStep -Name 'Tester connexion serveur' -Status 'Réussi' -Summary 'Connexion serveur fonctionnelle.'

$pull = Update-UckkServerSourceFromGit -Config $Config -Confirmed
$subResults += $pull
$logs += "Pull result: $($pull.status) — $($pull.summary)"

if (-not $pull.success) {
    $steps += New-UckkServerStep -Name 'Récupérer dernier code sur serveur' -Status 'Échoué' -Summary $pull.summary
    $errors += 'Publication arrêtée : récupération Git serveur échouée.'

    $finalFail = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'uckk.org' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : la source serveur n a pas pu être mise à jour depuis Git.' `
        -Warnings $warnings `
        -Errors $errors `
        -NextStep 'Lire le rapport Git serveur avant de relancer.' `
        -Data @{ subResults = $subResults } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $finalFail -LogLines $logs
}

$steps += New-UckkServerStep -Name 'Récupérer dernier code sur serveur' -Status 'Réussi' -Summary 'Source serveur mise à jour.'

$sync = Sync-UckkServerSourceToMoodleRuntime -Config $Config -Confirmed
$subResults += $sync
$logs += "Sync result: $($sync.status) — $($sync.summary)"

if (-not $sync.success) {
    $steps += New-UckkServerStep -Name 'Synchroniser source serveur vers Moodle serveur' -Status 'Échoué' -Summary $sync.summary
    $errors += 'Publication arrêtée : synchronisation vers Moodle serveur échouée.'

    $finalFail = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'uckk.org' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : les fichiers n ont pas pu être copiés vers Moodle serveur.' `
        -Warnings $warnings `
        -Errors $errors `
        -NextStep 'Lire le rapport de synchronisation serveur.' `
        -Data @{ subResults = $subResults } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $finalFail -LogLines $logs
}

$steps += New-UckkServerStep -Name 'Synchroniser source serveur vers Moodle serveur' -Status 'Réussi' -Summary 'Runtime Moodle serveur synchronisé.'

if ($RunMoodleUpgrade) {
    $upgrade = Invoke-UckkServerMoodleUpgrade -Config $Config -Confirmed
    $subResults += $upgrade
    $logs += "Moodle upgrade result: $($upgrade.status) — $($upgrade.summary)"

    if (-not $upgrade.success) {
        $steps += New-UckkServerStep -Name 'Mettre à jour Moodle serveur' -Status 'Échoué' -Summary $upgrade.summary
        $errors += 'Publication arrêtée : mise à jour Moodle serveur échouée.'

        $finalFail = New-UckkServerActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action $action `
            -Target 'uckk.org' `
            -DangerLevel 6 `
            -Mode 'publication' `
            -Summary 'L action a échoué. Cause probable : la mise à jour Moodle serveur a échoué.' `
            -Warnings $warnings `
            -Errors $errors `
            -NextStep 'Lire le rapport de mise à jour Moodle avant toute relance.' `
            -Data @{ subResults = $subResults } `
            -Steps $steps

        return Complete-UckkServerResult -Config $Config -Result $finalFail -LogLines $logs
    }

    $steps += New-UckkServerStep -Name 'Mettre à jour Moodle serveur' -Status 'Réussi' -Summary 'Moodle serveur mis à jour.'
} else {
    $steps += New-UckkServerStep -Name 'Mettre à jour Moodle serveur' -Status 'Ignoré' -Summary 'Option non demandée.'
}

$purge = Clear-UckkServerMoodleCaches -Config $Config -Confirmed
$subResults += $purge
$logs += "Purge caches result: $($purge.status) — $($purge.summary)"

if (-not $purge.success) {
    $steps += New-UckkServerStep -Name 'Purger les caches serveur' -Status 'Échoué' -Summary $purge.summary
    $errors += 'Publication arrêtée : purge des caches serveur échouée.'

    $finalFail = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'uckk.org' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'L action a échoué. Cause probable : la purge des caches serveur a échoué.' `
        -Warnings $warnings `
        -Errors $errors `
        -NextStep 'Lire le rapport de purge des caches.' `
        -Data @{ subResults = $subResults } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $finalFail -LogLines $logs
}

$steps += New-UckkServerStep -Name 'Purger les caches serveur' -Status 'Réussi' -Summary 'Caches serveur purgés.'

if ($ReloadPhpFpm) {
    $reload = Invoke-UckkServerPhpFpmReload -Config $Config -Confirmed
    $subResults += $reload
    $logs += "PHP-FPM reload result: $($reload.status) — $($reload.summary)"

    if (-not $reload.success) {
        $warnings += 'PHP-FPM n a pas pu être rechargé. Vérifier uckk.org attentivement.'
        $steps += New-UckkServerStep -Name 'Recharger PHP-FPM' -Status 'Réussi avec avertissements' -Summary $reload.summary
    } else {
        $steps += New-UckkServerStep -Name 'Recharger PHP-FPM' -Status 'Réussi' -Summary 'PHP-FPM rechargé.'
    }
} else {
    $steps += New-UckkServerStep -Name 'Recharger PHP-FPM' -Status 'Ignoré' -Summary 'Option non demandée.'
}

$verify = Test-UckkServerPublicPages -Config $Config
$subResults += $verify
$logs += "Verify pages result: $($verify.status) — $($verify.summary)"

if (-not $verify.success) {
    $steps += New-UckkServerStep -Name 'Vérifier uckk.org' -Status 'Échoué' -Summary $verify.summary
    $errors += 'La publication est faite, mais la vérification publique a échoué.'

    $finalWarn = New-UckkServerActionResult `
        -Success $false `
        -Status 'Échoué' `
        -Action $action `
        -Target 'uckk.org' `
        -DangerLevel 5 `
        -Mode 'publication' `
        -Summary 'La publication a été exécutée, mais uckk.org ne vérifie pas correctement.' `
        -Warnings $warnings `
        -Errors $errors `
        -NextStep 'Ouvrir uckk.org, lire les rapports et corriger avant de relancer.' `
        -Data @{ subResults = $subResults } `
        -Steps $steps

    return Complete-UckkServerResult -Config $Config -Result $finalWarn -LogLines $logs
}

$steps += New-UckkServerStep -Name 'Vérifier uckk.org' -Status $verify.status -Summary $verify.summary

foreach ($warning in @($verify.warnings)) {
    $warnings += $warning
}

$finalStatus = if ($warnings.Count -gt 0) { 'Réussi avec avertissements' } else { 'Réussi' }

$final = New-UckkServerActionResult `
    -Success $true `
    -Status $finalStatus `
    -Action $action `
    -Target 'uckk.org' `
    -DangerLevel 5 `
    -Mode 'publication' `
    -Summary 'Réussi — la publication serveur est terminée.' `
    -Warnings $warnings `
    -Errors $errors `
    -NextStep 'Vérifier les pages concernées dans le navigateur, surtout les pages AJAX comme la Médiathèque.' `
    -Data @{ subResults = $subResults } `
    -Steps $steps

return Complete-UckkServerResult -Config $Config -Result $final -LogLines $logs

}

Export-ModuleMember -Function @(
    "Test-UckkServerConnection",
    "Test-UckkServerState",
    "Update-UckkServerSourceFromGit",
    "Sync-UckkServerSourceToMoodleRuntime",
    "Invoke-UckkServerMoodleUpgrade",
    "Clear-UckkServerMoodleCaches",
    "Invoke-UckkServerPhpFpmReload",
    "Test-UckkServerPublicPages",
    "Invoke-UckkServerPublish"
)

