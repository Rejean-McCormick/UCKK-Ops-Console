#Requires -Version 7.0
<#
.SYNOPSIS
  JSON helpers for the UCKK Ops Console.

.DESCRIPTION
  This module centralizes JSON reading, writing, validation, and simple
  structural checks.

  It is used by:
    - configuration loading;
    - Médiathèque manifest validation;
    - Données Moodle JSON validation;
    - reports or structured action data when needed.

  This module must not:
    - modify Moodle;
    - modify Git;
    - modify the server;
    - write to the Moodle database;
    - run recovery actions;
    - decide business workflows.

  It only handles JSON files and JSON-shaped objects.
#>

Set-StrictMode -Off
# -----------------------------------------------------------------------------
# Internal helpers
# -----------------------------------------------------------------------------

function New-UckkJsonResult {
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

        [string] $Action = 'JSON',

        [string] $Target = '',

        [string] $Mode = 'vérification',

        [string] $Summary = '',

        [string[]] $Warnings = @(),

        [string[]] $Errors = @(),

        [string] $NextStep = '',

        [AllowNull()]
        [object] $Data = $null
    )

    return [pscustomobject]@{
        success     = $Success
        status      = $Status
        action      = $Action
        domain      = 'configuration'
        target      = $Target
        dangerLevel = 1
        mode        = $Mode
        summary     = $Summary
        warnings    = @($Warnings)
        errors      = @($Errors)
        nextStep    = $NextStep
        reportPath  = $null
        logPath     = $null
        data        = $Data
    }
}

function Test-UckkJsonIsDictionary {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $InputObject
    )

    return ($InputObject -is [System.Collections.IDictionary])
}

function Test-UckkJsonIsList {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $InputObject
    )

    if ($null -eq $InputObject) {
        return $false
    }

    if ($InputObject -is [string]) {
        return $false
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return $false
    }

    return ($InputObject -is [System.Collections.IEnumerable])
}

function Get-UckkJsonObjectValue {
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

function Test-UckkJsonObjectHasProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($null -eq $InputObject) {
        return $false
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject.Contains($Name)
    }

    return ($null -ne $InputObject.PSObject.Properties[$Name])
}

function ConvertTo-UckkJsonList {
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

function Resolve-UckkJsonFullPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [switch] $MustExist
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Le chemin JSON est vide.'
    }

    if ($MustExist) {
        if (-not (Test-Path -LiteralPath $Path)) {
            throw ("Le fichier JSON est introuvable : {0}" -f $Path)
        }

        return (Resolve-Path -LiteralPath $Path).Path
    }

    $parent = Split-Path -Parent $Path

    if ([string]::IsNullOrWhiteSpace($parent)) {
        $parent = Get-Location
    }

    if (Test-Path -LiteralPath $parent) {
        $resolvedParent = (Resolve-Path -LiteralPath $parent).Path
        $leaf = Split-Path -Leaf $Path
        return (Join-Path $resolvedParent $leaf)
    }

    return $Path
}

# -----------------------------------------------------------------------------
# Public: read JSON
# -----------------------------------------------------------------------------

function Read-UckkJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [int] $Depth = 100,

        [switch] $AsHashtable,

        [switch] $IncludeRaw,

        [switch] $AllowEmpty
    )

    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    try {
        $fullPath = Resolve-UckkJsonFullPath -Path $Path -MustExist

        $item = Get-Item -LiteralPath $fullPath -ErrorAction Stop

        if ($item.PSIsContainer) {
            throw ("Le chemin JSON pointe vers un dossier, pas un fichier : {0}" -f $fullPath)
        }

        $raw = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8 -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($raw)) {
            if ($AllowEmpty) {
                $warnings.Add('Le fichier JSON est vide.')

                return [pscustomobject]@{
                    success  = $true
                    path     = $fullPath
                    data     = $null
                    raw      = if ($IncludeRaw) { $raw } else { $null }
                    warnings = @($warnings)
                    errors   = @()
                }
            }

            throw ("Le fichier JSON est vide : {0}" -f $fullPath)
        }

        if ($AsHashtable) {
            $data = $raw | ConvertFrom-Json -Depth $Depth -AsHashtable -ErrorAction Stop
        }
        else {
            $data = $raw | ConvertFrom-Json -Depth $Depth -ErrorAction Stop
        }

        return [pscustomobject]@{
            success  = $true
            path     = $fullPath
            data     = $data
            raw      = if ($IncludeRaw) { $raw } else { $null }
            warnings = @($warnings)
            errors   = @()
        }
    }
    catch {
        $errors.Add($_.Exception.Message)

        return [pscustomobject]@{
            success  = $false
            path     = $Path
            data     = $null
            raw      = $null
            warnings = @($warnings)
            errors   = @($errors)
        }
    }
}

function Test-UckkJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [int] $Depth = 100,

        [switch] $AsHashtable,

        [switch] $AllowEmpty
    )

    $read = Read-UckkJsonFile `
        -Path $Path `
        -Depth $Depth `
        -AsHashtable:$AsHashtable `
        -AllowEmpty:$AllowEmpty

    if ($read.success) {
        $status = 'Réussi'
        $summary = ("JSON valide : {0}" -f $read.path)

        if (@($read.warnings).Count -gt 0) {
            $status = 'Réussi avec avertissements'
            $summary = ("JSON valide avec avertissements : {0}" -f $read.path)
        }

        return New-UckkJsonResult `
            -Success $true `
            -Status $status `
-Action 'Vérifier fichier JSON' `
            -Target $read.path `
            -Summary $summary `
            -Warnings $read.warnings `
            -Errors @() `
            -NextStep 'Aucune action requise.' `
            -Data @{
                path = $read.path
            }
    }

    return New-UckkJsonResult `
        -Success $false `
        -Status 'Échoué' `
        -Action 'Vérifier fichier JSON' `
        -Target $Path `
        -Summary 'Le fichier JSON est invalide ou introuvable.' `
        -Warnings $read.warnings `
        -Errors $read.errors `
        -NextStep 'Corriger le fichier JSON, puis relancer la vérification.' `
        -Data @{
            path = $Path
        }
}

# -----------------------------------------------------------------------------
# Public: write JSON
# -----------------------------------------------------------------------------

function Write-UckkJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Data,

        [int] $Depth = 100,

        [switch] $CreateParent,

        [switch] $NoAtomicWrite
    )

    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    try {
        $fullPath = Resolve-UckkJsonFullPath -Path $Path
        $parent = Split-Path -Parent $fullPath

        if (-not (Test-Path -LiteralPath $parent)) {
            if ($CreateParent) {
                New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
                $warnings.Add(("Dossier parent créé : {0}" -f $parent))
            }
            else {
                throw ("Le dossier parent n’existe pas : {0}" -f $parent)
            }
        }

        $json = $Data | ConvertTo-Json -Depth $Depth

        if ($null -eq $json) {
            $json = 'null'
        }

        $json = $json.TrimEnd() + [Environment]::NewLine

        if ($NoAtomicWrite) {
            Set-Content -LiteralPath $fullPath -Value $json -Encoding UTF8 -NoNewline -ErrorAction Stop
        }
        else {
            $tempPath = "{0}.tmp" -f $fullPath
            Set-Content -LiteralPath $tempPath -Value $json -Encoding UTF8 -NoNewline -ErrorAction Stop
            Move-Item -LiteralPath $tempPath -Destination $fullPath -Force -ErrorAction Stop
        }

        return [pscustomobject]@{
            success  = $true
            path     = $fullPath
            warnings = @($warnings)
            errors   = @()
        }
    }
    catch {
        $errors.Add($_.Exception.Message)

        return [pscustomobject]@{
            success  = $false
            path     = $Path
            warnings = @($warnings)
            errors   = @($errors)
        }
    }
}

function ConvertTo-UckkJsonText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Data,

        [int] $Depth = 100
    )

    $json = $Data | ConvertTo-Json -Depth $Depth

    if ($null -eq $json) {
        return 'null'
    }

    return $json
}

# -----------------------------------------------------------------------------
# Public: shape validation
# -----------------------------------------------------------------------------

function Test-UckkJsonRequiredProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory)]
        [string[]] $RequiredProperties,

        [string] $ObjectName = 'objet'
    )

    $missing = [System.Collections.Generic.List[string]]::new()

    foreach ($propertyName in $RequiredProperties) {
        if (-not (Test-UckkJsonObjectHasProperty -InputObject $InputObject -Name $propertyName)) {
            $missing.Add($propertyName)
            continue
        }

        $value = Get-UckkJsonObjectValue -InputObject $InputObject -Name $propertyName

        if ($null -eq $value) {
            $missing.Add($propertyName)
            continue
        }

        if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            $missing.Add($propertyName)
        }
    }

    return [pscustomobject]@{
        success            = ($missing.Count -eq 0)
        objectName         = $ObjectName
        requiredProperties = @($RequiredProperties)
        missingProperties  = @($missing)
    }
}

function Test-UckkJsonRootType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Data,

        [Parameter(Mandatory)]
        [ValidateSet('object', 'array')]
        [string] $ExpectedType
    )

    if ($ExpectedType -eq 'array') {
        $isArray = Test-UckkJsonIsList -InputObject $Data

        return [pscustomobject]@{
            success      = $isArray
            expectedType = 'array'
            actualType   = if ($isArray) { 'array' } else { 'object-or-scalar' }
        }
    }

    $isObject = ($null -ne $Data -and -not (Test-UckkJsonIsList -InputObject $Data))

    return [pscustomobject]@{
        success      = $isObject
        expectedType = 'object'
        actualType   = if ($isObject) { 'object' } else { 'array-or-null' }
    }
}

function Get-UckkJsonArray {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Data,

        [string] $PropertyName = ''
    )

    if ([string]::IsNullOrWhiteSpace($PropertyName)) {
        return ConvertTo-UckkJsonList -InputObject $Data
    }

    $value = Get-UckkJsonObjectValue `
        -InputObject $Data `
        -Name $PropertyName `
        -Default @()

    return ConvertTo-UckkJsonList -InputObject $value
}

function Test-UckkJsonArrayItemsRequiredProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object[]] $Items,

        [Parameter(Mandatory)]
        [string[]] $RequiredProperties,

        [string] $ItemLabelProperty = ''
    )

    $invalid = [System.Collections.Generic.List[object]]::new()
    $index = 0

    foreach ($item in @($Items)) {
        $label = "item[$index]"

        if (-not [string]::IsNullOrWhiteSpace($ItemLabelProperty)) {
            $labelValue = Get-UckkJsonObjectValue `
                -InputObject $item `
                -Name $ItemLabelProperty `
                -Default $null

            if (-not [string]::IsNullOrWhiteSpace([string] $labelValue)) {
                $label = [string] $labelValue
            }
        }

        $check = Test-UckkJsonRequiredProperties `
            -InputObject $item `
            -RequiredProperties $RequiredProperties `
            -ObjectName $label

        if (-not $check.success) {
            $invalid.Add($check)
        }

        $index++
    }

    return [pscustomobject]@{
        success      = ($invalid.Count -eq 0)
        checkedCount = @($Items).Count
        invalidCount = $invalid.Count
        invalidItems = @($invalid)
    }
}

# -----------------------------------------------------------------------------
# Public: duplicate detection
# -----------------------------------------------------------------------------

function Get-UckkJsonDuplicateValues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object[]] $Items,

        [Parameter(Mandatory)]
        [string] $PropertyName,

        [switch] $IgnoreCase,

        [switch] $IgnoreEmpty
    )

    $seen = @{}
    $duplicates = @{}
    $index = 0

    foreach ($item in @($Items)) {
        $value = Get-UckkJsonObjectValue `
            -InputObject $item `
            -Name $PropertyName `
            -Default $null

        if ($null -eq $value) {
            if ($IgnoreEmpty) {
                $index++
                continue
            }

            $value = ''
        }

        $key = [string] $value

        if ($IgnoreEmpty -and [string]::IsNullOrWhiteSpace($key)) {
            $index++
            continue
        }

        if ($IgnoreCase) {
            $key = $key.ToLowerInvariant()
        }

        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = [System.Collections.Generic.List[int]]::new()
        }

        $seen[$key].Add($index)

        if ($seen[$key].Count -gt 1) {
            $duplicates[$key] = @($seen[$key])
        }

        $index++
    }

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($key in $duplicates.Keys | Sort-Object) {
        $results.Add([pscustomobject]@{
            property = $PropertyName
            value    = $key
            indexes  = @($duplicates[$key])
            count    = @($duplicates[$key]).Count
        })
    }

    return @($results)
}

function Test-UckkJsonNoDuplicateValues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object[]] $Items,

        [Parameter(Mandatory)]
[string] $PropertyName,

        [switch] $IgnoreCase,

        [switch] $IgnoreEmpty
    )

    $duplicates = Get-UckkJsonDuplicateValues `
        -Items $Items `
        -PropertyName $PropertyName `
        -IgnoreCase:$IgnoreCase `
        -IgnoreEmpty:$IgnoreEmpty

    return [pscustomobject]@{
        success        = (@($duplicates).Count -eq 0)
        property       = $PropertyName
        duplicateCount = @($duplicates).Count
        duplicates     = @($duplicates)
    }
}

# -----------------------------------------------------------------------------
# Public: file-level validation helper
# -----------------------------------------------------------------------------

function Test-UckkJsonFileShape {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [ValidateSet('object', 'array')]
        [string] $ExpectedRootType = 'object',

        [string[]] $RequiredRootProperties = @(),

        [string] $ArrayProperty = '',

        [string[]] $RequiredItemProperties = @(),

        [string[]] $UniqueItemProperties = @(),

        [string] $ItemLabelProperty = '',

        [int] $Depth = 100
    )

    $warnings = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    $read = Read-UckkJsonFile -Path $Path -Depth $Depth

    if (-not $read.success) {
        return New-UckkJsonResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Vérifier structure JSON' `
            -Target $Path `
            -Summary 'Le fichier JSON est invalide ou introuvable.' `
            -Warnings $read.warnings `
            -Errors $read.errors `
            -NextStep 'Corriger le fichier JSON, puis relancer la vérification.' `
            -Data @{
                path = $Path
            }
    }

    foreach ($warning in @($read.warnings)) {
        $warnings.Add($warning)
    }

    $rootType = Test-UckkJsonRootType `
        -Data $read.data `
        -ExpectedType $ExpectedRootType

    if (-not $rootType.success) {
        $errors.Add(("Type racine invalide. Attendu : {0}. Obtenu : {1}." -f $rootType.expectedType, $rootType.actualType))
    }

    if (@($RequiredRootProperties).Count -gt 0) {
        $rootRequired = Test-UckkJsonRequiredProperties `
            -InputObject $read.data `
            -RequiredProperties $RequiredRootProperties `
            -ObjectName 'racine'

        if (-not $rootRequired.success) {
            $errors.Add(("Champs racine manquants : {0}" -f ($rootRequired.missingProperties -join ', ')))
        }
    }

    $items = @()

    if (-not [string]::IsNullOrWhiteSpace($ArrayProperty)) {
        if (-not (Test-UckkJsonObjectHasProperty -InputObject $read.data -Name $ArrayProperty)) {
            $errors.Add(("Propriété tableau introuvable : {0}" -f $ArrayProperty))
        }
        else {
            $items = Get-UckkJsonArray -Data $read.data -PropertyName $ArrayProperty
        }
    }
    elseif ($ExpectedRootType -eq 'array') {
        $items = Get-UckkJsonArray -Data $read.data
    }

    if (@($RequiredItemProperties).Count -gt 0 -and @($items).Count -gt 0) {
        $itemCheck = Test-UckkJsonArrayItemsRequiredProperties `
            -Items $items `
            -RequiredProperties $RequiredItemProperties `
            -ItemLabelProperty $ItemLabelProperty

        if (-not $itemCheck.success) {
            foreach ($invalid in @($itemCheck.invalidItems)) {
                $errors.Add(("{0} : champs manquants : {1}" -f $invalid.objectName, ($invalid.missingProperties -join ', ')))
            }
        }
    }

    foreach ($uniqueProperty in @($UniqueItemProperties)) {
        if (@($items).Count -eq 0) {
            continue
        }

        $dupeCheck = Test-UckkJsonNoDuplicateValues `
            -Items $items `
            -PropertyName $uniqueProperty `
            -IgnoreCase `
            -IgnoreEmpty

        if (-not $dupeCheck.success) {
            foreach ($duplicate in @($dupeCheck.duplicates)) {
                $errors.Add(("Doublon détecté pour {0} = {1} aux index : {2}" -f $uniqueProperty, $duplicate.value, ($duplicate.indexes -join ', ')))
            }
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

    $summary = if ($success) {
        ("Structure JSON valide : {0}" -f $read.path)
    }
    else {
        ("Structure JSON invalide : {0}" -f $read.path)
    }

    $nextStep = if ($success) {
        'Aucune action requise.'
    }
    else {
        'Corriger le fichier JSON, puis relancer la vérification.'
    }

    return New-UckkJsonResult `
        -Success $success `
        -Status $status `
        -Action 'Vérifier structure JSON' `
        -Target $read.path `
        -Summary $summary `
        -Warnings @($warnings) `
        -Errors @($errors) `
        -NextStep $nextStep `
        -Data @{
            path = $read.path
            itemCount = @($items).Count
            expectedRootType = $ExpectedRootType
            requiredRootProperties = @($RequiredRootProperties)
            requiredItemProperties = @($RequiredItemProperties)
            uniqueItemProperties = @($UniqueItemProperties)
        }
}

# -----------------------------------------------------------------------------
# Public: convenience validators
# -----------------------------------------------------------------------------

function Test-UckkJsonConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return Test-UckkJsonFileShape `
        -Path $Path `
        -ExpectedRootType 'object' `
        -RequiredRootProperties @(
            'app',
            'paths',
            'urls',
            'server',
            'git',
            'moodle',
            'mediatheque',
            'reports',
            'logs',
            'safety'
        )
}

function Test-UckkJsonArrayFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [string[]] $RequiredItemProperties = @(),

        [string[]] $UniqueItemProperties = @(),

        [string] $ItemLabelProperty = ''
    )

    return Test-UckkJsonFileShape `
        -Path $Path `
        -ExpectedRootType 'array' `
        -RequiredItemProperties $RequiredItemProperties `
        -UniqueItemProperties $UniqueItemProperties `
        -ItemLabelProperty $ItemLabelProperty
}

function Test-UckkJsonObjectArrayPropertyFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $ArrayProperty,

        [string[]] $RequiredRootProperties = @(),

        [string[]] $RequiredItemProperties = @(),

        [string[]] $UniqueItemProperties = @(),

        [string] $ItemLabelProperty = ''
    )

    return Test-UckkJsonFileShape `
        -Path $Path `
        -ExpectedRootType 'object' `
        -RequiredRootProperties $RequiredRootProperties `
        -ArrayProperty $ArrayProperty `
        -RequiredItemProperties $RequiredItemProperties `
        -UniqueItemProperties $UniqueItemProperties `
        -ItemLabelProperty $ItemLabelProperty
}

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

Export-ModuleMember -Function @(
    'Read-UckkJsonFile',
    'Test-UckkJsonFile',
    'Write-UckkJsonFile',
    'ConvertTo-UckkJsonText',
    'Get-UckkJsonObjectValue',
    'Test-UckkJsonObjectHasProperty',
    'Get-UckkJsonArray',
    'Test-UckkJsonRequiredProperties',
    'Test-UckkJsonArrayItemsRequiredProperties',
    'Get-UckkJsonDuplicateValues',
    'Test-UckkJsonNoDuplicateValues',
    'Test-UckkJsonFileShape',
    'Test-UckkJsonConfigFile',
    'Test-UckkJsonArrayFile',
    'Test-UckkJsonObjectArrayPropertyFile'
)

