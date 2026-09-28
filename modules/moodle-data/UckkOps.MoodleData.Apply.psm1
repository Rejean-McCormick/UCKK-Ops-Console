#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Simulation and application helpers for UCKK Moodle Data.

.DESCRIPTION
  Handles the controlled workflow:

    fichier source → validation → simulation → appliquer → vérifier

  This module is responsible for computing Moodle data changes and, when
  explicitly requested, applying them through a Moodle CLI PHP helper.

  It must not:
    - use raw SQL as the normal workflow;
    - copy tables directly;
    - apply server data without confirmation;
    - apply server data without a clear source;
    - silently delete data;
    - handle personal user data.
#>

$script:UckkMoodleDataSupportedDomains = @(
    'categories',
    'courses',
    'programs',
    'pathways'
)

function Get-UckkMoodleDataDomainLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Domain
    )

    switch ($Domain) {
        'categories' { return 'Catégories Moodle' }
        'courses'    { return 'Cours Moodle' }
        'programs'   { return 'Programmes' }
        'pathways'   { return 'Parcours' }
        default      { return $Domain }
    }
}

function Test-UckkMoodleDataDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Domain
    )

    return ($Domain -in $script:UckkMoodleDataSupportedDomains)
}

function Test-UckkMoodleDataTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Target
    )

    return ($Target -in @('local', 'server'))
}

function Get-UckkMoodleDataTargetLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('local', 'server')]
        [string] $Target
    )

    if ($Target -eq 'local') {
        return 'base Moodle locale'
    }

    return 'base Moodle serveur'
}

function Get-UckkMoodleDataDangerLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('local', 'server')]
        [string] $Target,

        [switch] $Apply
    )

    if (-not $Apply) {
        return 1
    }

    if ($Target -eq 'local') {
        return 4
    }

    return 6
}

function Get-UckkMoodleDataModeLabel {
    [CmdletBinding()]
    param(
        [switch] $Apply
    )

    if ($Apply) {
        return 'application'
    }

    return 'simulation'
}

function New-UckkMoodleDataApplyErrorResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Action,

        [Parameter(Mandatory)]
        [string] $Domain,

        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [string[]] $Errors,

        [string[]] $Warnings = @(),

        [string] $NextStep = 'Corriger les erreurs, puis relancer la validation ou la simulation.'
    )

    return [pscustomobject]@{
        success     = $false
        status      = 'Échoué'
        action      = $Action
        domain      = 'moodle-data'
        target      = Get-UckkMoodleDataTargetLabel -Target $Target
        dangerLevel = Get-UckkMoodleDataDangerLevel -Target $Target
        mode        = 'vérification'
        summary     = "L action a échoué : $($Errors.Count) erreur(s)."
        warnings    = @($Warnings)
        errors      = @($Errors)
        nextStep    = $NextStep
        reportPath  = ''
        logPath     = ''
        data        = @{
            moodleDataDomain = $Domain
            target = $Target
        }
    }
}

function Get-UckkObjectPropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Object,

        [Parameter(Mandatory)]
        [string[]] $Names
    )

    if ($null -eq $Object) {
        return $null
    }

    foreach ($name in $Names) {
        if ($Object -is [hashtable]) {
            if ($Object.ContainsKey($name)) {
                return $Object[$name]
            }
        } else {
            $prop = $Object.PSObject.Properties[$name]
            if ($null -ne $prop) {
                return $prop.Value
            }
        }
    }

    return $null
}

function Get-UckkMoodleDataStableKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Item,

        [Parameter(Mandatory)]
        [string] $Domain
    )

    $candidateNames = switch ($Domain) {
        'categories' { @('idnumber', 'key', 'slug', 'code', 'shortname', 'name') }
        'courses'    { @('idnumber', 'shortname', 'key', 'slug', 'code') }
        'programs'   { @('idnumber', 'key', 'slug', 'code', 'shortname', 'name') }
        'pathways'   { @('idnumber', 'key', 'slug', 'code', 'shortname', 'name') }
        default      { @('idnumber', 'key', 'slug', 'code', 'shortname', 'name') }
    }

    $value = Get-UckkObjectPropertyValue -Object $Item -Names $candidateNames

    if ($null -eq $value) {
        return ''
    }

    return ([string]$value).Trim()
}

function ConvertTo-UckkMoodleDataItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Json,

        [Parameter(Mandatory)]
        [string] $Domain
    )

    if ($null -eq $Json) {
        return @()
    }

    if ($Json -is [System.Collections.IEnumerable] -and -not ($Json -is [string])) {
        return @($Json)
    }

    $domainSpecificNames = switch ($Domain) {
        'categories' { @('categories', 'items', 'records') }
        'courses'    { @('courses', 'items', 'records') }
        'programs'   { @('programs', 'items', 'records') }
        'pathways'   { @('pathways', 'parcours', 'items', 'records') }
        default      { @('items', 'records') }
    }

    foreach ($name in $domainSpecificNames) {
        $value = Get-UckkObjectPropertyValue -Object $Json -Names @($name)

        if ($null -ne $value) {
            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                return @($value)
            }

            return @($value)
        }
    }

    return @($Json)
}

function Read-UckkMoodleDataSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SourcePath,

        [Parameter(Mandatory)]
        [string] $Domain
    )

    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
        throw 'Chemin source Données Moodle vide.'
    }

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Fichier source introuvable : $SourcePath"
    }

    $item = Get-Item -LiteralPath $SourcePath -ErrorAction Stop

    if ($item.PSIsContainer) {
        throw "Le chemin source pointe vers un dossier, pas un fichier : $SourcePath"
    }

    $text = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8 -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "Fichier source vide : $SourcePath"
    }

    try {
        $json = $text | ConvertFrom-Json -Depth 100 -ErrorAction Stop
    } catch {
        throw "JSON invalide dans $SourcePath. $($_.Exception.Message)"
    }

    $items = @(ConvertTo-UckkMoodleDataItems -Json $json -Domain $Domain)

    return [pscustomobject]@{
        path       = $item.FullName
        fileName   = $item.Name
        directory  = $item.DirectoryName
        sizeBytes  = $item.Length
        modifiedAt = $item.LastWriteTime
        hashSha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        json       = $json
        text       = $text
        items      = @($items)
        itemCount  = $items.Count
    }
}

function Test-UckkMoodleDataItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Item,

        [Parameter(Mandatory)]
        [string] $Domain,

        [Parameter(Mandatory)]
        [int] $Index
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    $stableKey = Get-UckkMoodleDataStableKey -Item $Item -Domain $Domain

    if ([string]::IsNullOrWhiteSpace($stableKey)) {
        $errors.Add("Élément $Index : identifiant stable absent.")
    }

    switch ($Domain) {
        'categories' {
            $name = Get-UckkObjectPropertyValue -Object $Item -Names @('name', 'title', 'fullname')
            if ([string]::IsNullOrWhiteSpace([string]$name)) {
                $errors.Add("Catégorie $Index : nom absent.")
            }
        }

        'courses' {
            $fullname = Get-UckkObjectPropertyValue -Object $Item -Names @('fullname', 'fullName', 'title', 'name')
            $shortname = Get-UckkObjectPropertyValue -Object $Item -Names @('shortname', 'shortName', 'code')

            if ([string]::IsNullOrWhiteSpace([string]$fullname)) {
                $errors.Add("Cours $Index : nom complet absent.")
            }

            if ([string]::IsNullOrWhiteSpace([string]$shortname)) {
                $errors.Add("Cours $Index : nom court absent.")
            }
        }
'programs' {
            $name = Get-UckkObjectPropertyValue -Object $Item -Names @('name', 'title', 'fullname')
            if ([string]::IsNullOrWhiteSpace([string]$name)) {
                $errors.Add("Programme $Index : nom absent.")
            }
        }

        'pathways' {
            $name = Get-UckkObjectPropertyValue -Object $Item -Names @('name', 'title', 'fullname')
            $program = Get-UckkObjectPropertyValue -Object $Item -Names @('program', 'programId', 'programKey', 'program_id')

            if ([string]::IsNullOrWhiteSpace([string]$name)) {
                $errors.Add("Parcours $Index : nom absent.")
            }

            if ([string]::IsNullOrWhiteSpace([string]$program)) {
                $warnings.Add("Parcours $Index : programme lié absent ou non indiqué.")
            }
        }
    }

    return [pscustomobject]@{
        ok        = ($errors.Count -eq 0)
        stableKey = $stableKey
        errors    = @($errors)
        warnings  = @($warnings)
    }
}

function Test-UckkMoodleDataSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SourcePath,

        [Parameter(Mandatory)]
        [string] $Domain
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    if (-not (Test-UckkMoodleDataDomain -Domain $Domain)) {
        $errors.Add("Domaine Données Moodle non supporté : $Domain")
    }

    if ($errors.Count -gt 0) {
        return [pscustomobject]@{
            ok         = $false
            source     = $null
            itemCount  = 0
            validCount = 0
            errors     = @($errors)
            warnings   = @($warnings)
            keys       = @()
        }
    }

    $source = $null

    try {
        $source = Read-UckkMoodleDataSource -SourcePath $SourcePath -Domain $Domain
    } catch {
        $errors.Add($_.Exception.Message)

        return [pscustomobject]@{
            ok         = $false
            source     = $null
            itemCount  = 0
            validCount = 0
            errors     = @($errors)
            warnings   = @($warnings)
            keys       = @()
        }
    }

    $keys = New-Object System.Collections.Generic.List[string]
    $seen = @{}

    for ($i = 0; $i -lt $source.items.Count; $i++) {
        $item = $source.items[$i]
        $validation = Test-UckkMoodleDataItem -Item $item -Domain $Domain -Index ($i + 1)

        foreach ($err in $validation.errors) {
            $errors.Add($err)
        }

        foreach ($warn in $validation.warnings) {
            $warnings.Add($warn)
        }

        if (-not [string]::IsNullOrWhiteSpace($validation.stableKey)) {
            $key = $validation.stableKey.Trim().ToLowerInvariant()

            if ($seen.ContainsKey($key)) {
                $errors.Add("Doublon détecté : identifiant stable '$($validation.stableKey)' aux éléments $($seen[$key]) et $($i + 1).")
            } else {
                $seen[$key] = ($i + 1)
                $keys.Add($validation.stableKey)
            }
        }
    }

    return [pscustomobject]@{
        ok         = ($errors.Count -eq 0)
        source     = $source
        itemCount  = $source.itemCount
        validCount = if ($errors.Count -eq 0) { $source.itemCount } else { 0 }
        errors     = @($errors)
        warnings   = @($warnings)
        keys       = @($keys)
    }
}

function Get-UckkMoodleRootFromConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config,

        [Parameter(Mandatory)]
        [ValidateSet('local', 'server')]
        [string] $Target
    )

    $paths = $Config.paths

    if ($null -eq $paths) {
        return ''
    }

    if ($Target -eq 'local') {
        foreach ($name in @('localMoodleRoot', 'localMoodleRuntime')) {
            if ($paths.PSObject.Properties[$name]) {
                $value = [string]$paths.$name
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    return $value
                }
            }

            if ($paths -is [hashtable] -and $paths.ContainsKey($name)) {
                $value = [string]$paths[$name]
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    return $value
                }
            }
        }
    }

    if ($Target -eq 'server') {
        foreach ($name in @('serverMoodleRoot', 'serverMoodleRuntime')) {
            if ($paths.PSObject.Properties[$name]) {
                $value = [string]$paths.$name
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    return $value
                }
            }

            if ($paths -is [hashtable] -and $paths.ContainsKey($name)) {
                $value = [string]$paths[$name]
                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    return $value
                }
            }
        }
    }

    return ''
}

function New-UckkMoodleDataCliHelper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $OutputPath
    )

    $php = @'
<?php
define('CLI_SCRIPT', true);

$options = getopt('', [
    'mode:',
    'domain:',
    'source:',
]);

$mode = $options['mode'] ?? 'simulate';
$domain = $options['domain'] ?? '';
$source = $options['source'] ?? '';

if (!in_array($mode, ['simulate', 'apply'], true)) {
    fwrite(STDERR, "Invalid mode\n");
    exit(2);
}

if ($domain === '') {
    fwrite(STDERR, "Missing domain\n");
    exit(2);
}

if ($source === '' || !is_file($source)) {
    fwrite(STDERR, "Missing source file\n");
    exit(2);
}

require_once(getcwd() . '/config.php');

global $DB, $CFG;

$text = file_get_contents($source);
$json = json_decode($text, true);

if ($json === null && json_last_error() !== JSON_ERROR_NONE) {
    fwrite(STDERR, "Invalid JSON: " . json_last_error_msg() . "\n");
    exit(2);
}

function uckk_items_from_json($json, string $domain): array {
    if (array_is_list($json)) {
        return $json;
    }

    $names = [
        $domain,
        'items',
        'records'
    ];

    if ($domain === 'pathways') {
        array_unshift($names, 'parcours');
    }

    foreach ($names as $name) {
        if (isset($json[$name]) && is_array($json[$name])) {
            return array_is_list($json[$name]) ? $json[$name] : array_values($json[$name]);
        }
    }

    return [$json];
}

function uckk_value(array $item, array $names): string {
    foreach ($names as $name) {
        if (array_key_exists($name, $item) && $item[$name] !== null) {
            return trim((string)$item[$name]);
        }
    }

    return '';
}

function uckk_key(array $item, string $domain): string {
    if ($domain === 'courses') {
        return uckk_value($item, ['idnumber', 'shortname', 'key', 'slug', 'code']);
    }

    return uckk_value($item, ['idnumber', 'key', 'slug', 'code', 'shortname', 'name']);
}

$items = uckk_items_from_json($json, $domain);

$result = [
    'mode' => $mode,
    'domain' => $domain,
    'source' => $source,
    'wwwroot' => $CFG->wwwroot ?? '',
    'summary' => [
        'read' => count($items),
        'create' => 0,
        'update' => 0,
        'unchanged' => 0,
        'ignored' => 0,
        'errors' => 0,
        'warnings' => 0,
    ],
    'changes' => [],
    'warnings' => [],
    'errors' => [],
];

foreach ($items as $index => $item) {
    if (!is_array($item)) {
        $result['summary']['ignored']++;
        $result['summary']['warnings']++;
        $result['warnings'][] = "Item " . ($index + 1) . " is not an object.";
        continue;
    }

    $key = uckk_key($item, $domain);

    if ($key === '') {
        $result['summary']['errors']++;
        $result['errors'][] = "Item " . ($index + 1) . " has no stable key.";
        continue;
    }

    /*
      This helper intentionally does not implement every Moodle data mutation yet.

      It is a safe adapter:
      - simulation computes planned operations;
      - application refuses unsupported destructive writes;
      - future domain-specific writes must be added explicitly.

      This avoids silent database changes.
    */

    $result['summary']['unchanged']++;
    $result['changes'][] = [
        'key' => $key,
        'operation' => 'unchanged',
        'message' => 'No write adapter implemented for this domain yet.',
    ];
}

if ($mode === 'apply') {
    $result['summary']['warnings']++;
    $result['warnings'][] = 'Apply mode reached safe adapter only. No Moodle data was modified because domain write adapters are not implemented in this helper yet.';
}

echo json_encode($result, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT) . PHP_EOL;
exit($result['summary']['errors'] > 0 ? 1 : 0);
'@

    Set-Content -LiteralPath $OutputPath -Value $php -Encoding UTF8
    return $OutputPath
}

function Invoke-UckkMoodleDataPhpHelper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('simulate', 'apply')]
        [string] $Mode,

        [Parameter(Mandatory)]
        [string] $Domain,

        [Parameter(Mandatory)]
        [string] $SourcePath,

        [Parameter(Mandatory)]
        [string] $MoodleRoot,

        [string] $PhpPath = 'php'
    )

    if ([string]::IsNullOrWhiteSpace($MoodleRoot)) {
        throw 'Racine Moodle absente.'
}

    if (-not (Test-Path -LiteralPath $MoodleRoot)) {
        throw "Racine Moodle introuvable : $MoodleRoot"
    }

    $configPhp = Join-Path $MoodleRoot 'config.php'
    if (-not (Test-Path -LiteralPath $configPhp)) {
        throw "config.php Moodle introuvable : $configPhp"
    }

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) 'uckk-ops-console'
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    $helperPath = Join-Path $tempDir 'uckk_moodle_data_apply_helper.php'
    New-UckkMoodleDataCliHelper -OutputPath $helperPath | Out-Null

    $arguments = @(
        $helperPath,
        "--mode=$Mode",
        "--domain=$Domain",
        "--source=$SourcePath"
    )

    $output = & $PhpPath @arguments 2>&1
    $exitCode = $LASTEXITCODE
    $outputText = ($output | Out-String).Trim()

    $parsed = $null
    try {
        $parsed = $outputText | ConvertFrom-Json -Depth 100 -ErrorAction Stop
    } catch {
        $parsed = $null
    }

    return [pscustomobject]@{
        exitCode = $exitCode
        output   = $outputText
        json     = $parsed
        helper   = $helperPath
    }
}

function New-UckkMoodleDataPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Domain,

        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [string] $SourcePath,

        [Parameter(Mandatory)]
        [object] $Validation,

        [object] $HelperResult = $null,

        [switch] $Apply
    )

    $mode = if ($Apply) { 'application' } else { 'simulation' }

    $summary = [ordered]@{
        read      = $Validation.itemCount
        valid     = $Validation.validCount
        create    = 0
        update    = 0
        unchanged = 0
        ignored   = 0
        errors    = @($Validation.errors).Count
        warnings  = @($Validation.warnings).Count
    }

    $changes = @()

    if ($null -ne $HelperResult -and $null -ne $HelperResult.json) {
        if ($HelperResult.json.summary) {
            foreach ($name in @('read', 'create', 'update', 'unchanged', 'ignored', 'errors', 'warnings')) {
                if ($HelperResult.json.summary.PSObject.Properties[$name]) {
                    $summary[$name] = $HelperResult.json.summary.$name
                }
            }
        }

        if ($HelperResult.json.changes) {
            $changes = @($HelperResult.json.changes)
        }
    }

    return [pscustomobject]@{
        domain       = $Domain
        domainLabel  = Get-UckkMoodleDataDomainLabel -Domain $Domain
        target       = $Target
        targetLabel  = Get-UckkMoodleDataTargetLabel -Target $Target
        mode         = $mode
        sourcePath   = $SourcePath
        sourceHash   = if ($Validation.source) { $Validation.source.hashSha256 } else { '' }
        sourceItems  = $Validation.itemCount
        summary      = [pscustomobject]$summary
        changes      = @($changes)
        helper       = $HelperResult
    }
}

function Invoke-UckkMoodleDataSimulation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Domain,

        [Parameter(Mandatory)]
        [ValidateSet('local', 'server')]
        [string] $Target,

        [Parameter(Mandatory)]
        [string] $SourcePath,

        [Parameter(Mandatory)]
        [hashtable] $Config,

        [string] $PhpPath = 'php'
    )

    $action = "Simulation $(Get-UckkMoodleDataDomainLabel -Domain $Domain) $Target"

    if (-not (Test-UckkMoodleDataDomain -Domain $Domain)) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @("Domaine Données Moodle non supporté : $Domain")
    }

    $validation = Test-UckkMoodleDataSource -SourcePath $SourcePath -Domain $Domain

    if (-not $validation.ok) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors $validation.errors `
            -Warnings $validation.warnings
    }

    $moodleRoot = Get-UckkMoodleRootFromConfig -Config $Config -Target $Target

    $helperResult = $null
    $warnings = New-Object System.Collections.Generic.List[string]

    foreach ($warning in $validation.warnings) {
        $warnings.Add($warning)
    }

    try {
        $helperResult = Invoke-UckkMoodleDataPhpHelper `
            -Mode 'simulate' `
            -Domain $Domain `
            -SourcePath $SourcePath `
            -MoodleRoot $moodleRoot `
            -PhpPath $PhpPath

        if ($helperResult.exitCode -ne 0) {
            return New-UckkMoodleDataApplyErrorResult `
                -Action $action `
                -Domain $Domain `
                -Target $Target `
                -Errors @("La simulation Moodle a échoué. Code de retour : $($helperResult.exitCode).", $helperResult.output) `
                -Warnings @($warnings)
        }

        if ($null -ne $helperResult.json -and $helperResult.json.warnings) {
            foreach ($warning in $helperResult.json.warnings) {
                $warnings.Add([string]$warning)
            }
        }
    } catch {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @($_.Exception.Message) `
            -Warnings @($warnings)
    }

    $plan = New-UckkMoodleDataPlan `
        -Domain $Domain `
        -Target $Target `
        -SourcePath $SourcePath `
        -Validation $validation `
        -HelperResult $helperResult

    return [pscustomobject]@{
        success     = $true
        status      = if ($warnings.Count -gt 0) { 'Réussi avec avertissements' } else { 'Réussi' }
        action      = $action
        domain      = 'moodle-data'
        target      = Get-UckkMoodleDataTargetLabel -Target $Target
        dangerLevel = 1
        mode        = 'simulation'
        summary     = "Simulation terminée. Aucune donnée Moodle n a été modifiée. Éléments lus : $($plan.summary.read)."
        warnings    = @($warnings)
        errors      = @()
        nextStep    = if ($Target -eq 'server') {
            'Lire le rapport de simulation, puis appliquer serveur seulement si tout est correct.'
        } else {
            'Lire le rapport de simulation, puis appliquer localement si tout est correct.'
        }
        reportPath  = ''
        logPath     = ''
        data        = $plan
    }
}

function Invoke-UckkMoodleDataApply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Domain,

        [Parameter(Mandatory)]
        [ValidateSet('local', 'server')]
        [string] $Target,

        [Parameter(Mandatory)]
        [string] $SourcePath,

        [Parameter(Mandatory)]
        [hashtable] $Config,

        [Parameter(Mandatory)]
        [object] $SimulationResult,

        [string] $PhpPath = 'php',

        [switch] $Confirmed
    )

    $action = "Appliquer $(Get-UckkMoodleDataDomainLabel -Domain $Domain) $(if ($Target -eq 'local') { 'localement' } else { 'serveur' })"

    if (-not $Confirmed) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @('Application refusée : confirmation utilisateur absente.') `
            -NextStep 'Demander la confirmation obligatoire avant de relancer.'
    }

    if ($null -eq $SimulationResult -or -not $SimulationResult.success) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @('Application refusée : aucune simulation réussie fournie.') `
            -NextStep 'Lancer une simulation avec la même source et la même cible.'
    }

    $simulationData = $SimulationResult.data

    if ($null -eq $simulationData) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @('Application refusée : données de simulation absentes.') `
            -NextStep 'Relancer la simulation.'
    }

    if ($simulationData.domain -ne $Domain) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @("Application refusée : domaine différent de la simulation. Simulation = $($simulationData.domain), application = $Domain.")
    }

    if ($simulationData.target -ne $Target) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @("Application refusée : cible différente de la simulation. Simulation = $($simulationData.target), application = $Target.")
    }

    $validation = Test-UckkMoodleDataSource -SourcePath $SourcePath -Domain $Domain

    if (-not $validation.ok) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors $validation.errors `
            -Warnings $validation.warnings
    }

    if ($simulationData.sourceHash -and $validation.source.hashSha256 -ne $simulationData.sourceHash) {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @('Application refusée : le fichier source a changé depuis la simulation.') `
            -NextStep 'Relancer la simulation avec le fichier actuel.'
    }

    $moodleRoot = Get-UckkMoodleRootFromConfig -Config $Config -Target $Target

    $warnings = New-Object System.Collections.Generic.List[string]

    foreach ($warning in $validation.warnings) {
        $warnings.Add($warning)
    }

    $helperResult = $null

    try {
        $helperResult = Invoke-UckkMoodleDataPhpHelper `
            -Mode 'apply' `
            -Domain $Domain `
            -SourcePath $SourcePath `
            -MoodleRoot $moodleRoot `
            -PhpPath $PhpPath

        if ($helperResult.exitCode -ne 0) {
            return New-UckkMoodleDataApplyErrorResult `
                -Action $action `
                -Domain $Domain `
                -Target $Target `
                -Errors @("L application Moodle a échoué. Code de retour : $($helperResult.exitCode).", $helperResult.output) `
                -Warnings @($warnings)
        }

        if ($null -ne $helperResult.json -and $helperResult.json.warnings) {
            foreach ($warning in $helperResult.json.warnings) {
                $warnings.Add([string]$warning)
            }
        }
    } catch {
        return New-UckkMoodleDataApplyErrorResult `
            -Action $action `
            -Domain $Domain `
            -Target $Target `
            -Errors @($_.Exception.Message) `
            -Warnings @($warnings)
    }

    $plan = New-UckkMoodleDataPlan `
        -Domain $Domain `
-Target $Target `
        -SourcePath $SourcePath `
        -Validation $validation `
        -HelperResult $helperResult `
        -Apply

    return [pscustomobject]@{
        success     = $true
        status      = if ($warnings.Count -gt 0) { 'Réussi avec avertissements' } else { 'Réussi' }
        action      = $action
        domain      = 'moodle-data'
        target      = Get-UckkMoodleDataTargetLabel -Target $Target
        dangerLevel = Get-UckkMoodleDataDangerLevel -Target $Target -Apply
        mode        = 'application'
        summary     = "Application terminée. Des données Moodle peuvent avoir été modifiées. Éléments lus : $($plan.summary.read)."
        warnings    = @($warnings)
        errors      = @()
        nextStep    = if ($Target -eq 'server') {
            'Vérifier Moodle serveur et les pages concernées dans le navigateur.'
        } else {
            'Vérifier Moodle local et les pages concernées dans le navigateur.'
        }
        reportPath  = ''
        logPath     = ''
        data        = $plan
    }
}

function Format-UckkMoodleDataPlanText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Plan
    )

    $lines = New-Object System.Collections.Generic.List[string]

    $lines.Add("Données Moodle — $($Plan.domainLabel)")
    $lines.Add('')
    $lines.Add("Mode : $($Plan.mode)")
    $lines.Add("Cible : $($Plan.targetLabel)")
    $lines.Add("Source : $($Plan.sourcePath)")
    $lines.Add("Empreinte source : $($Plan.sourceHash)")
    $lines.Add('')
    $lines.Add('Résumé')
    $lines.Add("- Éléments lus : $($Plan.summary.read)")
    $lines.Add("- Éléments valides : $($Plan.summary.valid)")
    $lines.Add("- À créer : $($Plan.summary.create)")
    $lines.Add("- À mettre à jour : $($Plan.summary.update)")
    $lines.Add("- Inchangés : $($Plan.summary.unchanged)")
    $lines.Add("- Ignorés : $($Plan.summary.ignored)")
    $lines.Add("- Avertissements : $($Plan.summary.warnings)")
    $lines.Add("- Erreurs : $($Plan.summary.errors)")
    $lines.Add('')

    if ($Plan.mode -eq 'simulation') {
        $lines.Add('Aucune donnée Moodle n a été modifiée.')
    } else {
        $lines.Add('Des données Moodle peuvent avoir été modifiées.')
    }

    return ($lines -join [Environment]::NewLine)
}

Export-ModuleMember -Function @(
    'Get-UckkMoodleDataDomainLabel',
    'Test-UckkMoodleDataDomain',
    'Test-UckkMoodleDataTarget',
    'Get-UckkMoodleDataTargetLabel',
    'Get-UckkMoodleDataDangerLevel',
    'Read-UckkMoodleDataSource',
    'Test-UckkMoodleDataSource',
    'New-UckkMoodleDataPlan',
    'Invoke-UckkMoodleDataSimulation',
    'Invoke-UckkMoodleDataApply',
    'Format-UckkMoodleDataPlanText'
)

