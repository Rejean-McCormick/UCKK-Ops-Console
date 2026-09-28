#Requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# UCKK Ops Console
# Entry point only.
# This file must not execute any dangerous action at startup.
# It only loads the application and opens the interface.
# The canonical .bat launcher starts PowerShell with process-local ExecutionPolicy Bypass.
# This script also removes Mark-of-the-Web from application scripts/modules when possible.

$AppRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
}
else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Unblock-UckkOpsApplicationFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Root
    )

    # Files extracted from a ZIP downloaded from the Internet can inherit the
    # Zone.Identifier (Mark-of-the-Web). Under RemoteSigned/AllSigned-like
    # policies, Import-Module can then reject otherwise local .psm1 files.
    #
    # Unblock-File only removes that per-file marker. It does NOT change the
    # machine/user PowerShell execution policy.
    if (-not $IsWindows) {
        return
    }

    try {
        Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction Stop |
            Where-Object {
                $_.Extension -in @(".ps1", ".psm1", ".psd1", ".bat", ".cmd")
            } |
            Unblock-File -ErrorAction Stop
    }
    catch {
        # The .bat launcher already uses process-local ExecutionPolicy Bypass,
        # so inability to remove Zone.Identifier must not prevent startup.
        Write-Host "Avertissement : certains fichiers n'ont pas pu être débloqués automatiquement." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Write-StartupError {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [string] $Detail = ""
    )

    Write-Host ""
    Write-Host "UCKK Ops Console — erreur de démarrage" -ForegroundColor Red
    Write-Host ""
    Write-Host $Message -ForegroundColor Yellow

    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        Write-Host ""
        Write-Host "Détail technique :" -ForegroundColor DarkGray
        Write-Host $Detail -ForegroundColor DarkGray
    }

    Write-Host ""
}

function Test-RequiredFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $FullPath = Join-Path $AppRoot $RelativePath

    if (-not (Test-Path -LiteralPath $FullPath -PathType Leaf)) {
        throw "Fichier requis introuvable : $RelativePath"
    }

    return $FullPath
}

function Ensure-RequiredDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $FullPath = Join-Path $AppRoot $RelativePath

    if (-not (Test-Path -LiteralPath $FullPath -PathType Container)) {
        New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
    }

    return $FullPath
}

function Import-RequiredModule {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $ModulePath = Test-RequiredFile -RelativePath $RelativePath

    try {
        Import-Module $ModulePath -Force -DisableNameChecking -ErrorAction Stop
    }
    catch {
        throw "Impossible de charger le module : $RelativePath`n$($_.Exception.Message)"
    }
}

function DotSource-RequiredScript {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    $ScriptPath = Test-RequiredFile -RelativePath $RelativePath

    try {
        . $ScriptPath
    }
    catch {
        throw "Impossible de charger le script : $RelativePath`n$($_.Exception.Message)"
    }
}

function Ensure-ConfigFile {
    param()

    $ConfigPath = Join-Path $AppRoot "config/uckk-ops-console.config.json"

    if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
        return $ConfigPath
    }

    $ExampleConfigPath = Join-Path $AppRoot "config/uckk-ops-console.config.example.json"

    if (Test-Path -LiteralPath $ExampleConfigPath -PathType Leaf) {
        Copy-Item -LiteralPath $ExampleConfigPath -Destination $ConfigPath -Force
        return $ConfigPath
    }

    throw "Configuration introuvable : config/uckk-ops-console.config.json"
}

function Start-LoadedUckkOpsConsole {
    param(
        [Parameter(Mandatory = $true)]
        [string] $AppRoot,

        [Parameter(Mandatory = $true)]
        [string] $ConfigPath
    )

    $PrimaryStart = Get-Command -Name Start-UckkOpsConsole -CommandType Function -ErrorAction SilentlyContinue

    if ($PrimaryStart) {
        $Arguments = @{}

        if ($PrimaryStart.Parameters.ContainsKey("AppRoot")) {
            $Arguments["AppRoot"] = $AppRoot
        }

        if ($PrimaryStart.Parameters.ContainsKey("ConfigPath")) {
            $Arguments["ConfigPath"] = $ConfigPath
        }

        & $PrimaryStart @Arguments
        return
    }

    $GuiStart = Get-Command -Name Start-UckkOpsConsoleGui -CommandType Function -ErrorAction SilentlyContinue

    if ($GuiStart) {
        $Arguments = @{}

        if ($GuiStart.Parameters.ContainsKey("AppRoot")) {
            $Arguments["AppRoot"] = $AppRoot
        }

        if ($GuiStart.Parameters.ContainsKey("ConfigPath")) {
            $Arguments["ConfigPath"] = $ConfigPath
        }

        & $GuiStart @Arguments
        return
    }

    throw "Fonction de démarrage introuvable : Start-UckkOpsConsole ou Start-UckkOpsConsoleGui"
}

try {
    Set-Location -LiteralPath $AppRoot
    Unblock-UckkOpsApplicationFiles -Root $AppRoot

    $RequiredDirectories = @(
        "config",
        "app",
        "lib",
        "modules",
        "reports",
        "logs",
        "legacy",
        "recovery"
    )

    foreach ($Directory in $RequiredDirectories) {
        Ensure-RequiredDirectory -RelativePath $Directory | Out-Null
    }

    $ConfigPath = Ensure-ConfigFile

    $RequiredModules = @(
        "lib/UckkOps.Config.psm1",
        "lib/UckkOps.Result.psm1",
        "lib/UckkOps.Report.psm1",
        "lib/UckkOps.Log.psm1",
        "lib/UckkOps.Security.psm1",
        "lib/UckkOps.Command.psm1",
        "lib/UckkOps.Path.psm1",
        "lib/UckkOps.Url.psm1",
        "lib/UckkOps.Json.psm1",
        "lib/UckkOps.ActionRegistry.psm1",

        "modules/local/UckkOps.Local.psm1",
        "modules/git/UckkOps.Git.psm1",
        "modules/server/UckkOps.Server.psm1",
        "modules/mediatheque/UckkOps.Mediatheque.Manifest.psm1",
        "modules/mediatheque/UckkOps.Mediatheque.Moodle.psm1",
        "modules/mediatheque/UckkOps.Mediatheque.psm1",
        "modules/moodle-data/UckkOps.MoodleData.Json.psm1",
        "modules/moodle-data/UckkOps.MoodleData.Apply.psm1",
        "modules/moodle-data/UckkOps.MoodleData.psm1",
        "modules/tests/UckkOps.Tests.psm1"
    )

    foreach ($Module in $RequiredModules) {
        Import-RequiredModule -RelativePath $Module
    }

    $RequiredAppScripts = @(
        "app/UckkOpsConsole.State.ps1",
        "app/UckkOpsConsole.Layout.ps1",
        "app/UckkOpsConsole.Actions.ps1",
        "app/UckkOpsConsole.Gui.ps1"
    )

    foreach ($Script in $RequiredAppScripts) {
        $ScriptPath = Test-RequiredFile -RelativePath $Script

        try {
            . $ScriptPath
        }
        catch {
            throw "Impossible de charger le script : $Script`n$($_.Exception.Message)"
        }
    }

    Start-LoadedUckkOpsConsole -AppRoot $AppRoot -ConfigPath $ConfigPath

    exit 0
}
catch {
    Write-StartupError `
        -Message "L’application n’a pas pu démarrer." `
        -Detail $_.Exception.Message

    exit 1
}
