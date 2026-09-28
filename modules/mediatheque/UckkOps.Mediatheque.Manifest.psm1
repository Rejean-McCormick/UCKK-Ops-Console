#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Manifest helpers for UCKK Ops Console Médiathèque.

.DESCRIPTION
  Loads, validates, normalizes, and inspects the Médiathèque manifest.

  This module does not write to Moodle.
  This module does not modify the manifest.
  This module does not call legacy or recovery scripts.

  Normal workflow:

    manifeste → simulation → appliquer → vérifier

  This file covers only the "manifeste" part.
#>

$script:UckkMediathequeAllowedTypes = @(
    'external_video',
    'external_audio',
    'external_article',
    'external_book',
    'external_website',
    'external_code',
    'external_document',
    'external_reference'
)

$script:UckkMediathequeExternalTypes = @(
    'external_video',
    'external_audio',
    'external_article',
    'external_book',
    'external_website',
    'external_code',
    'external_document',
    'external_reference'
)

function Get-UckkObjectProperty {
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

function ConvertTo-UckkStringArray {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return @()
        }

        return @($Value.Trim())
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $items = New-Object System.Collections.Generic.List[string]

        foreach ($item in $Value) {
            if ($null -eq $item) {
                continue
            }

            $text = [string]$item
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                $items.Add($text.Trim())
            }
        }

        return @($items)
    }

    $fallback = [string]$Value
    if ([string]::IsNullOrWhiteSpace($fallback)) {
        return @()
    }

    return @($fallback.Trim())
}

function Normalize-UckkMediathequeSlug {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string] $Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    $text = $Value.Trim().ToLowerInvariant()

    $text = $text.Normalize([Text.NormalizationForm]::FormD)
    $builder = [System.Text.StringBuilder]::new()

    foreach ($char in $text.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)
        if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($char)
        }
    }

    $text = $builder.ToString().Normalize([Text.NormalizationForm]::FormC)
    $text = [regex]::Replace($text, '[^a-z0-9]+', '-')
    $text = [regex]::Replace($text, '-+', '-')
    $text = $text.Trim('-')

    return $text
}

function Normalize-UckkMediathequeTag {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string] $Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    $text = $Value.Trim().ToLowerInvariant()
    $text = [regex]::Replace($text, '\s+', ' ')
    return $text
}

function Test-UckkMediathequeUrl {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string] $Url
    )

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return $false
    }

    $parsed = $null
    if (-not [System.Uri]::TryCreate($Url.Trim(), [System.UriKind]::Absolute, [ref]$parsed)) {
        return $false
    }

    return ($parsed.Scheme -in @('http', 'https'))
}

function Get-UckkMediathequeManifestHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Manifest introuvable : $Path"
    }

    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256

    return $hash.Hash.ToLowerInvariant()
}

function Get-UckkMediathequeManifestRaw {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Chemin du manifeste Médiathèque vide.'
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Manifeste Médiathèque introuvable : $Path"
    }

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop

    if ($item.PSIsContainer) {
        throw "Le chemin du manifeste pointe vers un dossier, pas un fichier : $Path"
    }

    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "Le manifeste Médiathèque est vide : $Path"
    }

    try {
        $json = $text | ConvertFrom-Json -Depth 100 -ErrorAction Stop
    } catch {
        throw "JSON invalide dans le manifeste Médiathèque : $Path. $($_.Exception.Message)"
    }

    return [pscustomobject]@{
        path       = $item.FullName
        fileName   = $item.Name
        directory  = $item.DirectoryName
        sizeBytes  = $item.Length
        modifiedAt = $item.LastWriteTime
        hashSha256 = Get-UckkMediathequeManifestHash -Path $item.FullName
        json       = $json
        text       = $text
    }
}

function Get-UckkMediathequeManifestEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $ManifestJson
    )

    if ($null -eq $ManifestJson) {
        return @()
    }

    if ($ManifestJson -is [System.Collections.IEnumerable] -and -not ($ManifestJson -is [string])) {
        return @($ManifestJson)
    }

    $candidateNames = @(
        'entries',
        'items',
        'references',
        'media',
        'resources',
        'records'
    )

    foreach ($name in $candidateNames) {
        $value = Get-UckkObjectProperty -Object $ManifestJson -Names @($name)

        if ($null -ne $value) {
            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                return @($value)
            }

            return @($value)
        }
    }

    return @($ManifestJson)
}

function ConvertTo-UckkMediathequeManifestEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Entry,

        [Parameter(Mandatory)]
        [int] $Index
    )

    $slugRaw = Get-UckkObjectProperty -Object $Entry -Names @('slug', 'key', 'id', 'idnumber')
    $titleRaw = Get-UckkObjectProperty -Object $Entry -Names @('title', 'name', 'label')
    $typeRaw = Get-UckkObjectProperty -Object $Entry -Names @('type', 'resourceType', 'kind')
    $urlRaw = Get-UckkObjectProperty -Object $Entry -Names @('url', 'href', 'externalUrl', 'link')
    $publisherRaw = Get-UckkObjectProperty -Object $Entry -Names @('publisher', 'platform', 'source', 'provider')
    $languageRaw = Get-UckkObjectProperty -Object $Entry -Names @('language', 'lang', 'locale')
    $summaryRaw = Get-UckkObjectProperty -Object $Entry -Names @('summary', 'description', 'abstract')
    $tagsRaw = Get-UckkObjectProperty -Object $Entry -Names @('tags', 'keywords')
    $collectionsRaw = Get-UckkObjectProperty -Object $Entry -Names @('collections', 'collection', 'groups')
    $externalIdRaw = Get-UckkObjectProperty -Object $Entry -Names @('externalId', 'external_id', 'sourceId', 'source_item_id')

    $title = ''
    if ($null -ne $titleRaw) {
        $title = ([string]$titleRaw).Trim()
    }

    $slug = ''
    if ($null -ne $slugRaw) {
        $slug = Normalize-UckkMediathequeSlug -Value ([string]$slugRaw)
    }

    if ([string]::IsNullOrWhiteSpace($slug) -and -not [string]::IsNullOrWhiteSpace($title)) {
        $slug = Normalize-UckkMediathequeSlug -Value $title
    }

    $type = ''
    if ($null -ne $typeRaw) {
        $type = ([string]$typeRaw).Trim()
    }

    if ([string]::IsNullOrWhiteSpace($type)) {
        $type = 'external_reference'
    }

    $url = ''
    if ($null -ne $urlRaw) {
        $url = ([string]$urlRaw).Trim()
    }

    $publisher = ''
    if ($null -ne $publisherRaw) {
        $publisher = ([string]$publisherRaw).Trim()
    }

    $language = ''
    if ($null -ne $languageRaw) {
        $language = ([string]$languageRaw).Trim().ToLowerInvariant()
    }

    $summary = ''
    if ($null -ne $summaryRaw) {
        $summary = ([string]$summaryRaw).Trim()
    }

    $externalId = ''
    if ($null -ne $externalIdRaw) {
        $externalId = ([string]$externalIdRaw).Trim()
}

    $tags = ConvertTo-UckkStringArray -Value $tagsRaw |
        ForEach-Object { Normalize-UckkMediathequeTag -Value $_ } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique

    $collections = ConvertTo-UckkStringArray -Value $collectionsRaw |
        ForEach-Object { Normalize-UckkMediathequeSlug -Value $_ } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique

    return [pscustomobject]@{
        index       = $Index
        slug        = $slug
        title       = $title
        type        = $type
        url         = $url
        publisher   = $publisher
        language    = $language
        summary     = $summary
        tags        = @($tags)
        collections = @($collections)
        externalId  = $externalId
        raw         = $Entry
    }
}

function Find-UckkMediathequeManifestDuplicates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]] $Entries
    )

    $duplicates = New-Object System.Collections.Generic.List[object]

    $groups = @(
        @{
            name = 'slug'
            label = 'Slug dupliqué'
            get = {
                param($entry)
                return $entry.slug
            }
        },
        @{
            name = 'url'
            label = 'URL dupliquée'
            get = {
                param($entry)
                return $entry.url
            }
        },
        @{
            name = 'externalId'
            label = 'Identifiant externe dupliqué'
            get = {
                param($entry)
                return $entry.externalId
            }
        }
    )

    foreach ($group in $groups) {
        $buckets = @{}

        foreach ($entry in $Entries) {
            $value = & $group.get $entry

            if ([string]::IsNullOrWhiteSpace([string]$value)) {
                continue
            }

            $key = ([string]$value).Trim().ToLowerInvariant()

            if (-not $buckets.ContainsKey($key)) {
                $buckets[$key] = New-Object System.Collections.Generic.List[object]
            }

            $buckets[$key].Add($entry)
        }

        foreach ($key in $buckets.Keys) {
            if ($buckets[$key].Count -gt 1) {
                $duplicates.Add([pscustomobject]@{
                    type    = $group.name
                    message = "$($group.label) : $key"
                    value   = $key
                    indexes = @($buckets[$key] | ForEach-Object { $_.index })
                    slugs   = @($buckets[$key] | ForEach-Object { $_.slug })
                    titles  = @($buckets[$key] | ForEach-Object { $_.title })
                })
            }
        }
    }

    return @($duplicates)
}

function Test-UckkMediathequeManifestEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Entry
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($Entry.slug)) {
        $errors.Add("Entrée $($Entry.index) : slug absent ou impossible à générer.")
    }

    if ([string]::IsNullOrWhiteSpace($Entry.title)) {
        $errors.Add("Entrée $($Entry.index) : titre absent.")
    }

    if ([string]::IsNullOrWhiteSpace($Entry.type)) {
        $errors.Add("Entrée $($Entry.index) : type absent.")
    } elseif ($Entry.type -notin $script:UckkMediathequeAllowedTypes) {
        $warnings.Add("Entrée $($Entry.index) : type non reconnu '$($Entry.type)', à traiter comme external_reference si accepté.")
    }

    if ($Entry.type -in $script:UckkMediathequeExternalTypes) {
        if ([string]::IsNullOrWhiteSpace($Entry.url)) {
            $errors.Add("Entrée $($Entry.index) : URL obligatoire absente pour une référence externe.")
        } elseif (-not (Test-UckkMediathequeUrl -Url $Entry.url)) {
            $errors.Add("Entrée $($Entry.index) : URL invalide '$($Entry.url)'.")
        }
    }

    if ([string]::IsNullOrWhiteSpace($Entry.summary)) {
        $warnings.Add("Entrée $($Entry.index) : résumé absent.")
    }

    if ([string]::IsNullOrWhiteSpace($Entry.publisher)) {
        $warnings.Add("Entrée $($Entry.index) : éditeur / plateforme absent.")
    }

    if ([string]::IsNullOrWhiteSpace($Entry.language)) {
        $warnings.Add("Entrée $($Entry.index) : langue absente.")
    }

    if ($Entry.collections.Count -eq 0) {
        $warnings.Add("Entrée $($Entry.index) : aucune collection.")
    }

    if ($Entry.tags.Count -eq 0) {
        $warnings.Add("Entrée $($Entry.index) : aucun tag.")
    }

    return [pscustomobject]@{
        ok       = ($errors.Count -eq 0)
        errors   = @($errors)
        warnings = @($warnings)
    }
}

function Test-UckkMediathequeManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [int] $MinimumEntryCount = 1,

        [int] $KnownTargetCount = 0,

        [switch] $Strict
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    $raw = $null
    try {
        $raw = Get-UckkMediathequeManifestRaw -Path $Path
    } catch {
        $errors.Add($_.Exception.Message)

        return [pscustomobject]@{
            ok            = $false
            path          = $Path
            hashSha256    = ''
            entryCount    = 0
            entries       = @()
            duplicates    = @()
            errors        = @($errors)
            warnings      = @($warnings)
            sourceSummary = [pscustomobject]@{
                type = 'manifest'
                path = $Path
            }
        }
    }

    $rawEntries = @(Get-UckkMediathequeManifestEntries -ManifestJson $raw.json)
    $entries = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt $rawEntries.Count; $i++) {
        $entry = ConvertTo-UckkMediathequeManifestEntry -Entry $rawEntries[$i] -Index ($i + 1)
        $entries.Add($entry)

        $entryValidation = Test-UckkMediathequeManifestEntry -Entry $entry

        foreach ($errorItem in $entryValidation.errors) {
            $errors.Add($errorItem)
        }

        foreach ($warningItem in $entryValidation.warnings) {
            $warnings.Add($warningItem)
        }
    }

    if ($entries.Count -lt $MinimumEntryCount) {
        $errors.Add("Le manifeste contient $($entries.Count) entrée(s), minimum attendu : $MinimumEntryCount.")
    }

    if ($KnownTargetCount -gt 0 -and $entries.Count -lt $KnownTargetCount) {
        $difference = $KnownTargetCount - $entries.Count
        $ratio = 0
        if ($KnownTargetCount -gt 0) {
            $ratio = [math]::Round(($entries.Count / $KnownTargetCount) * 100, 2)
        }

        $message = "Avertissement fort — le manifeste contient $($entries.Count) référence(s), alors que la cible connue en contient $KnownTargetCount. Différence : $difference. Ratio : $ratio%."

        if ($entries.Count -le 5 -and $KnownTargetCount -ge 100) {
            $errors.Add("$message Action refusée sauf récupération explicitement confirmée.")
        } else {
            $warnings.Add($message)
        }
    }

    $duplicates = @(Find-UckkMediathequeManifestDuplicates -Entries @($entries))

    foreach ($duplicate in $duplicates) {
        $errors.Add($duplicate.message)
    }

    if ($Strict) {
        foreach ($warningItem in @($warnings)) {
            $errors.Add("Mode strict : $warningItem")
        }
    }

    $collectionCount = @(
        $entries |
            ForEach-Object { $_.collections } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique
    ).Count

    $tagCount = @(
        $entries |
            ForEach-Object { $_.tags } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique
    ).Count

    return [pscustomobject]@{
        ok            = ($errors.Count -eq 0)
        path          = $raw.path
        fileName      = $raw.fileName
        directory     = $raw.directory
        sizeBytes     = $raw.sizeBytes
        modifiedAt    = $raw.modifiedAt
        hashSha256    = $raw.hashSha256
        entryCount    = $entries.Count
        collectionCount = $collectionCount
        tagCount      = $tagCount
        entries       = @($entries)
        duplicates    = @($duplicates)
        errors        = @($errors)
        warnings      = @($warnings)
        sourceSummary = [pscustomobject]@{
            type       = 'manifest'
            path       = $raw.path
            hashSha256 = $raw.hashSha256
            entries    = $entries.Count
        }
    }
}

function Read-UckkMediathequeManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [int] $MinimumEntryCount = 1,

        [int] $KnownTargetCount = 0,

        [switch] $Strict
    )

    $validation = Test-UckkMediathequeManifest `
        -Path $Path `
        -MinimumEntryCount $MinimumEntryCount `
        -KnownTargetCount $KnownTargetCount `
        -Strict:$Strict

    return [pscustomobject]@{
        success     = $validation.ok
        status      = if ($validation.ok) { 'Réussi' } else { 'Échoué' }
        action      = 'Vérifier manifeste Médiathèque'
        domain      = 'mediatheque'
        target      = 'Manifeste Médiathèque'
        dangerLevel = 1
        mode        = 'vérification'
        summary     = if ($validation.ok) {
            "Manifeste Médiathèque valide : $($validation.entryCount) entrée(s)."
        } else {
            "Manifeste Médiathèque invalide : $($validation.errors.Count) erreur(s)."
        }
        warnings    = @($validation.warnings)
        errors      = @($validation.errors)
        nextStep    = if ($validation.ok) {
            'Lancer une simulation Médiathèque locale ou serveur.'
        } else {
            'Corriger le manifeste Médiathèque, puis relancer la vérification.'
        }
        reportPath  = ''
        logPath     = ''
        data        = $validation
    }
}

function New-UckkMediathequeManifestSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Validation
    )

    return [pscustomobject]@{
        path            = $Validation.path
        hashSha256      = $Validation.hashSha256
        valid           = $Validation.ok
        entries         = $Validation.entryCount
        collections     = $Validation.collectionCount
        tags            = $Validation.tagCount
        duplicates      = @($Validation.duplicates).Count
        warnings        = @($Validation.warnings).Count
        errors          = @($Validation.errors).Count
    }
}
function Format-UckkMediathequeManifestValidationText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Validation
    )

    $lines = New-Object System.Collections.Generic.List[string]

    $lines.Add('Vérification manifeste Médiathèque')
    $lines.Add('')
    $lines.Add("Statut : $(if ($Validation.ok) { 'Réussi' } else { 'Échoué' })")
    $lines.Add("Chemin : $($Validation.path)")
    $lines.Add("Empreinte SHA-256 : $($Validation.hashSha256)")
    $lines.Add("Entrées : $($Validation.entryCount)")
    $lines.Add("Collections : $($Validation.collectionCount)")
    $lines.Add("Tags : $($Validation.tagCount)")
    $lines.Add("Doublons : $(@($Validation.duplicates).Count)")
    $lines.Add("Avertissements : $(@($Validation.warnings).Count)")
    $lines.Add("Erreurs : $(@($Validation.errors).Count)")
    $lines.Add('')

    $lines.Add('Avertissements')
    if (@($Validation.warnings).Count -eq 0) {
        $lines.Add('- Aucun.')
    } else {
        foreach ($warningItem in $Validation.warnings) {
            $lines.Add("- $warningItem")
        }
    }

    $lines.Add('')
    $lines.Add('Erreurs')
    if (@($Validation.errors).Count -eq 0) {
        $lines.Add('- Aucune.')
    } else {
        foreach ($errorItem in $Validation.errors) {
            $lines.Add("- $errorItem")
        }
    }

    return ($lines -join [Environment]::NewLine)
}

Export-ModuleMember -Function @(
    'Get-UckkMediathequeManifestRaw',
    'Get-UckkMediathequeManifestHash',
    'Get-UckkMediathequeManifestEntries',
    'ConvertTo-UckkMediathequeManifestEntry',
    'Find-UckkMediathequeManifestDuplicates',
    'Test-UckkMediathequeManifestEntry',
    'Test-UckkMediathequeManifest',
    'Read-UckkMediathequeManifest',
    'New-UckkMediathequeManifestSummary',
    'Format-UckkMediathequeManifestValidationText',
    'Normalize-UckkMediathequeSlug',
    'Normalize-UckkMediathequeTag',
    'Test-UckkMediathequeUrl'
)

