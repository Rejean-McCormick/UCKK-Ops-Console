#requires -Version 7.0
<#
.SYNOPSIS
    Diagnostic local Moodle / PHP pour UCKK Ops Console.

.DESCRIPTION
    Lecture seule : ne modifie ni Moodle ni la base de données.
    Vérifie :
      - racine Moodle et webroot public
      - PHP CLI
      - scripts CLI Moodle
      - config.php
      - version/release/branche/maturité Moodle
      - présence de l'option --allow-unstable
      - Git (si disponible)
    Affiche une recommandation claire pour l'upgrade.

.NOTES
    Conçu pour PowerShell 7+.
#>

[CmdletBinding()]
param(
    [string]$MoodleRoot = 'C:\mycode\UCKK\moodle\moodle',
    [string]$WebRoot    = 'C:\mycode\UCKK\moodle\moodle\public'
)

$ErrorActionPreference = 'Stop'

function Write-Section([string]$Title) {
    Write-Host ""
    Write-Host ("=" * 72) -ForegroundColor DarkGray
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 72) -ForegroundColor DarkGray
}

function Write-Check([string]$Label, [bool]$Ok, [string]$Detail = '') {
    $status = if ($Ok) { 'OK' } else { 'ECHEC' }
    $color  = if ($Ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1}" -f $status, $Label) -ForegroundColor $color
    if ($Detail) {
        Write-Host ("     {0}" -f $Detail) -ForegroundColor DarkGray
    }
}

function Read-MoodleVersionFile([string]$Path) {
    $raw = Get-Content -LiteralPath $Path -Raw

    $result = [ordered]@{
        version  = $null
        release  = $null
        branch   = $null
        maturity = $null
    }

    if ($raw -match '\$version\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*;') {
        $result.version = $Matches[1]
    }
    $releasePattern = @'
\$release\s*=\s*["']([^"']+)["']\s*;
'@
    if ($raw -match $releasePattern) {
        $result.release = $Matches[1]
    }

    $branchPattern = @'
\$branch\s*=\s*["']([^"']+)["']\s*;
'@
    if ($raw -match $branchPattern) {
        $result.branch = $Matches[1]
    }
    if ($raw -match '\$maturity\s*=\s*([A-Z0-9_]+)\s*;') {
        $result.maturity = $Matches[1]
    }

    [pscustomobject]$result
}

Write-Section 'UCKK / Moodle - Diagnostic PS7'

Write-Host ("Date       : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ("PowerShell : {0}" -f $PSVersionTable.PSVersion)
Write-Host ("MoodleRoot : {0}" -f $MoodleRoot)
Write-Host ("WebRoot    : {0}" -f $WebRoot)

Write-Section '1. Chemins Moodle'

$rootExists = Test-Path -LiteralPath $MoodleRoot -PathType Container
$webExists  = Test-Path -LiteralPath $WebRoot -PathType Container

Write-Check 'Racine Moodle' $rootExists $MoodleRoot
Write-Check 'Webroot public' $webExists $WebRoot

$upgradePhp = Join-Path $MoodleRoot 'admin\cli\upgrade.php'
$purgePhp   = Join-Path $MoodleRoot 'admin\cli\purge_caches.php'
$versionPhp = Join-Path $MoodleRoot 'version.php'

Write-Check 'admin\cli\upgrade.php' (Test-Path -LiteralPath $upgradePhp -PathType Leaf) $upgradePhp
Write-Check 'admin\cli\purge_caches.php' (Test-Path -LiteralPath $purgePhp -PathType Leaf) $purgePhp
Write-Check 'version.php' (Test-Path -LiteralPath $versionPhp -PathType Leaf) $versionPhp

$configCandidates = @(
    (Join-Path $MoodleRoot 'config.php'),
    (Join-Path $WebRoot 'config.php'),
    (Join-Path (Split-Path -Parent $MoodleRoot) 'config.php')
) | Select-Object -Unique

Write-Host ""
Write-Host 'config.php candidats :' -ForegroundColor Yellow
$foundConfig = $false
foreach ($candidate in $configCandidates) {
    $exists = Test-Path -LiteralPath $candidate -PathType Leaf
    if ($exists) { $foundConfig = $true }
    Write-Check $candidate $exists
}

Write-Section '2. PHP CLI'

$php = Get-Command php -ErrorAction SilentlyContinue
if (-not $php) {
    Write-Check 'Commande php disponible' $false 'php introuvable dans PATH'
}
else {
    Write-Check 'Commande php disponible' $true $php.Source
    try {
        $phpVersion = & php -r 'echo PHP_VERSION;' 2>&1
        Write-Check 'PHP exécutable' ($LASTEXITCODE -eq 0) ("PHP {0}" -f ($phpVersion -join ''))
    }
    catch {
        Write-Check 'PHP exécutable' $false $_.Exception.Message
    }
}

Write-Section '3. Version et maturité Moodle'

$moodleInfo = $null
if (Test-Path -LiteralPath $versionPhp -PathType Leaf) {
    try {
        $moodleInfo = Read-MoodleVersionFile $versionPhp
        Write-Host ("Version  : {0}" -f ($moodleInfo.version  ?? '(non détectée)'))
        Write-Host ("Release  : {0}" -f ($moodleInfo.release  ?? '(non détectée)'))
        Write-Host ("Branche  : {0}" -f ($moodleInfo.branch   ?? '(non détectée)'))
        Write-Host ("Maturité : {0}" -f ($moodleInfo.maturity ?? '(non détectée)'))
    }
    catch {
        Write-Host ("Lecture version.php impossible : {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

$unstableMaturities = @('MATURITY_ALPHA', 'MATURITY_BETA', 'MATURITY_RC')
$isUnstable = $false
if ($moodleInfo -and $moodleInfo.maturity) {
    $isUnstable = $unstableMaturities -contains $moodleInfo.maturity
}

if ($isUnstable) {
    Write-Host ""
    Write-Host 'ATTENTION : cette installation Moodle est marquée instable.' -ForegroundColor Yellow
    Write-Host ("Maturité détectée : {0}" -f $moodleInfo.maturity) -ForegroundColor Yellow
}
elseif ($moodleInfo -and $moodleInfo.maturity) {
    Write-Host ""
    Write-Host 'Maturité Moodle non détectée comme Alpha/Beta/RC.' -ForegroundColor Green
}

Write-Section '4. Capacités du CLI upgrade'

$allowUnstableSupported = $false
if ((Test-Path -LiteralPath $upgradePhp -PathType Leaf) -and $php) {
    try {
        $help = & php $upgradePhp --help 2>&1
        $helpText = ($help -join "`n")
        $allowUnstableSupported = $helpText -match '--allow-unstable'

        Write-Check '--help de upgrade.php' ($LASTEXITCODE -eq 0 -or $helpText.Length -gt 0)
        Write-Check 'Option --allow-unstable disponible' $allowUnstableSupported
    }
    catch {
        Write-Check '--help de upgrade.php' $false $_.Exception.Message
    }
}

Write-Section '5. Git Moodle (lecture seule)'

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git -and (Test-Path -LiteralPath (Join-Path $MoodleRoot '.git'))) {
    try {
        $branch = & git -C $MoodleRoot branch --show-current 2>&1
        $status = & git -C $MoodleRoot status --short 2>&1
        Write-Host ("Branche : {0}" -f ($branch -join ''))
        if ($status) {
            Write-Host 'Fichiers modifiés :' -ForegroundColor Yellow
            $status | ForEach-Object { Write-Host ("  {0}" -f $_) }
        }
        else {
            Write-Host 'Working tree propre.' -ForegroundColor Green
        }
    }
    catch {
        Write-Host ("Git non vérifiable : {0}" -f $_.Exception.Message) -ForegroundColor DarkYellow
    }
}
else {
    Write-Host 'Repo Git Moodle non détecté à cette racine (information seulement).' -ForegroundColor DarkGray
}

Write-Section '6. Conclusion'

if (-not $rootExists) {
    Write-Host 'ECHEC : MoodleRoot est invalide.' -ForegroundColor Red
    exit 2
}

if (-not (Test-Path -LiteralPath $upgradePhp -PathType Leaf)) {
    Write-Host 'ECHEC : admin\cli\upgrade.php introuvable sous MoodleRoot.' -ForegroundColor Red
    Write-Host 'Corriger localMoodleRoot dans la configuration Ops Console.' -ForegroundColor Yellow
    exit 3
}

if (-not $php) {
    Write-Host 'ECHEC : PHP CLI introuvable.' -ForegroundColor Red
    exit 4
}

if ($isUnstable -and $allowUnstableSupported) {
    Write-Host 'DIAGNOSTIC : Moodle est instable et exige probablement --allow-unstable.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Commande d upgrade correspondante (NE PAS lancer automatiquement sans confirmation) :' -ForegroundColor Yellow
    Write-Host ('php "{0}" --non-interactive --allow-unstable' -f $upgradePhp) -ForegroundColor White
}
else {
    Write-Host 'DIAGNOSTIC : aucune exigence --allow-unstable détectée.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Commande d upgrade standard :' -ForegroundColor DarkGray
    Write-Host ('php "{0}" --non-interactive' -f $upgradePhp) -ForegroundColor White
}

Write-Host ''
Write-Host 'Ce diagnostic est en lecture seule : aucune migration DB n a été lancée.' -ForegroundColor Cyan
