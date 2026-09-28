#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Writes readable Markdown reports for UCKK Ops Console actions.

.DESCRIPTION
  This module creates structured, user-readable reports.

  Contract:
    - The report explains.
    - The log diagnoses.
    - The interface summarizes.

  Reports must not contain secrets.
  Reports must have stable sections.
  Reports must be written as UTF-8 Markdown files.
#>

function Get-UckkReportDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config = $null
    )

    if ($null -ne $Config) {
        if ($Config.PSObject.Properties.Name -contains "reports") {
            if ($null -ne $Config.reports -and $Config.reports.PSObject.Properties.Name -contains "dir") {
                if (-not [string]::IsNullOrWhiteSpace([string] $Config.reports.dir)) {
                    return [string] $Config.reports.dir
                }
            }
        }

        if ($Config.PSObject.Properties.Name -contains "paths") {
            if ($null -ne $Config.paths -and $Config.paths.PSObject.Properties.Name -contains "reportsDir") {
                if (-not [string]::IsNullOrWhiteSpace([string] $Config.paths.reportsDir)) {
                    return [string] $Config.paths.reportsDir
                }
            }
        }
    }

    return "./reports"
}

function Resolve-UckkReportDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config = $null,

        [Parameter(Mandatory = $false)]
        [string] $BasePath = ""
    )

    $reportDir = Get-UckkReportDirectory -Config $Config

    if ([System.IO.Path]::IsPathRooted($reportDir)) {
        return [System.IO.Path]::GetFullPath($reportDir)
    }

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        if ($null -ne $Config -and $Config.PSObject.Properties.Name -contains "app") {
            if ($null -ne $Config.app -and $Config.app.PSObject.Properties.Name -contains "root") {
                if (-not [string]::IsNullOrWhiteSpace([string] $Config.app.root)) {
                    $BasePath = [string] $Config.app.root
                }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        $BasePath = (Get-Location).Path
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $reportDir))
}

function ConvertTo-UckkSafeReportText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value = $null
    )

    if ($null -eq $Value) {
        return ""
    }

    $text = ""

    if ($Value -is [string]) {
        $text = $Value
    }
    else {
        try {
            $text = $Value | ConvertTo-Json -Depth 20 -Compress
        }
        catch {
            $text = [string] $Value
        }
    }

    $patterns = @(
        "(?i)(password\s*[:=]\s*)[^;\s,}]+",
        "(?i)(passwd\s*[:=]\s*)[^;\s,}]+",
        "(?i)(token\s*[:=]\s*)[^;\s,}]+",
        "(?i)(secret\s*[:=]\s*)[^;\s,}]+",
        "(?i)(api[_-]?key\s*[:=]\s*)[^;\s,}]+",
        "(?i)(private[_-]?key\s*[:=]\s*)[^;\s,}]+",
        "(?i)(cookie\s*[:=]\s*)[^;\s,}]+",
        "(?i)(session\s*[:=]\s*)[^;\s,}]+"
    )

    foreach ($pattern in $patterns) {
        $text = [regex]::Replace($text, $pattern, '$1[masqué]')
    }

    return $text
}

function ConvertTo-UckkReportSlug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text
    )

    $slug = $Text.Trim().ToLowerInvariant()

    $replacements = @{
        "é" = "e"
        "è" = "e"
        "ê" = "e"
        "ë" = "e"
        "à" = "a"
        "â" = "a"
        "ä" = "a"
        "ù" = "u"
        "û" = "u"
        "ü" = "u"
        "î" = "i"
        "ï" = "i"
        "ô" = "o"
        "ö" = "o"
        "ç" = "c"
        "œ" = "oe"
        "æ" = "ae"
    }

    foreach ($key in $replacements.Keys) {
        $slug = $slug.Replace($key, $replacements[$key])
    }

    $slug = [regex]::Replace($slug, "[^a-z0-9]+", "_")
    $slug = [regex]::Replace($slug, "_+", "_")
    $slug = $slug.Trim("_")

    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "rapport"
    }

    return $slug
}

function New-UckkReportFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Domain = "general",

        [Parameter(Mandatory = $false)]
        [string] $Action = "action",

        [Parameter(Mandatory = $false)]
        [string] $Target = ""
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $parts = @(
        $timestamp,
        (ConvertTo-UckkReportSlug -Text $Domain),
        (ConvertTo-UckkReportSlug -Text $Action)
    )

    if (-not [string]::IsNullOrWhiteSpace($Target)) {
        $parts += (ConvertTo-UckkReportSlug -Text $Target)
    }

    return (($parts -join "_") + ".md")
}

function ConvertTo-UckkMarkdownList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Items = $null,

        [Parameter(Mandatory = $false)]
        [string] $EmptyText = "Aucun."
    )

    if ($null -eq $Items) {
        return $EmptyText
    }

    $array = @()

    if ($Items -is [System.Collections.IEnumerable] -and $Items -isnot [string]) {
        foreach ($item in $Items) {
            $array += $item
        }
    }
    else {
        $array += $Items
    }

    if ($array.Count -eq 0) {
        return $EmptyText
    }

    $lines = @()

    foreach ($item in $array) {
        if ($null -eq $item) {
            continue
        }

        $lines += ("- " + (ConvertTo-UckkSafeReportText -Value $item))
    }

    if ($lines.Count -eq 0) {
        return $EmptyText
    }

    return ($lines -join [Environment]::NewLine)
}

function ConvertTo-UckkMarkdownCodeBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value = $null,

        [Parameter(Mandatory = $false)]
        [string] $EmptyText = "Non applicable."
    )

    if ($null -eq $Value) {
        return $EmptyText
    }

    $text = ConvertTo-UckkSafeReportText -Value $Value

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $EmptyText
    }

    return @"
~~~text
$text
~~~
"@
}

function Get-UckkResultProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Result = $null,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Default = $null
    )

    if ($null -eq $Result) {
        return $Default
    }

    if ($Result -is [hashtable]) {
        if ($Result.ContainsKey($Name)) {
            return $Result[$Name]
        }

        return $Default
    }

    if ($Result.PSObject.Properties.Name -contains $Name) {
        return $Result.$Name
    }

    return $Default
}

function Format-UckkReportMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Result,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Metadata = $null
    )

    $action = [string] (Get-UckkResultProperty -Result $Result -Name "action" -Default "Action inconnue")
    $domain = [string] (Get-UckkResultProperty -Result $Result -Name "domain" -Default "general")
    $target = [string] (Get-UckkResultProperty -Result $Result -Name "target" -Default "Non applicable.")
    $dangerLevel = Get-UckkResultProperty -Result $Result -Name "dangerLevel" -Default "Non applicable."
    $mode = [string] (Get-UckkResultProperty -Result $Result -Name "mode" -Default "Non applicable.")
    $status = [string] (Get-UckkResultProperty -Result $Result -Name "status" -Default "Non applicable.")
    $summary = [string] (Get-UckkResultProperty -Result $Result -Name "summary" -Default "")
    $warnings = Get-UckkResultProperty -Result $Result -Name "warnings" -Default @()
    $errors = Get-UckkResultProperty -Result $Result -Name "errors" -Default @()
    $nextStep = [string] (Get-UckkResultProperty -Result $Result -Name "nextStep" -Default "Aucune action requise.")
    $logPath = [string] (Get-UckkResultProperty -Result $Result -Name "logPath" -Default "")
    $data = Get-UckkResultProperty -Result $Result -Name "data" -Default $null

    $sourceUsed = Get-UckkResultProperty -Result $Result -Name "source" -Default $null

    if ($null -eq $sourceUsed) {
        $sourceUsed = Get-UckkResultProperty -Result $Result -Name "sourcePath" -Default $null
    }

    if ($null -eq $sourceUsed) {
        $sourceUsed = Get-UckkResultProperty -Result $Result -Name "sourceUsed" -Default "Non applicable."
    }

    $steps = Get-UckkResultProperty -Result $Result -Name "steps" -Default @()
    $changes = Get-UckkResultProperty -Result $Result -Name "changes" -Default $null
    $confirmation = Get-UckkResultProperty -Result $Result -Name "confirmation" -Default $null
    $simulation = Get-UckkResultProperty -Result $Result -Name "simulation" -Default $null

    $generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $timezone = [System.TimeZoneInfo]::Local.Id
$safeSummary = ConvertTo-UckkSafeReportText -Value $summary
    $safeNextStep = ConvertTo-UckkSafeReportText -Value $nextStep
    $safeLogPath = ConvertTo-UckkSafeReportText -Value $logPath

    $stepsText = ConvertTo-UckkMarkdownList -Items $steps -EmptyText "Aucune étape détaillée."
    $warningsText = ConvertTo-UckkMarkdownList -Items $warnings -EmptyText "Aucun."
    $errorsText = ConvertTo-UckkMarkdownList -Items $errors -EmptyText "Aucune."

    if ($null -eq $changes) {
        $changesText = "Non applicable."
    }
    else {
        $changesText = ConvertTo-UckkMarkdownCodeBlock -Value $changes -EmptyText "Non applicable."
    }

    if ($null -eq $data) {
        $dataText = "Non applicable."
    }
    else {
        $dataText = ConvertTo-UckkMarkdownCodeBlock -Value $data -EmptyText "Non applicable."
    }

    $technicalLines = @()
    $technicalLines += "Domaine : $domain"
    $technicalLines += "Statut : $status"
    $technicalLines += "Généré le : $generatedAt"
    $technicalLines += "Fuseau horaire : $timezone"

    if (-not [string]::IsNullOrWhiteSpace($safeLogPath)) {
        $technicalLines += "Log technique : $safeLogPath"
    }
    else {
        $technicalLines += "Log technique : Non applicable."
    }

    if ($null -ne $confirmation) {
        $technicalLines += "Confirmation : $(ConvertTo-UckkSafeReportText -Value $confirmation)"
    }

    if ($null -ne $simulation) {
        $technicalLines += "Simulation préalable : $(ConvertTo-UckkSafeReportText -Value $simulation)"
    }

    if ($null -ne $Metadata) {
        $technicalLines += "Métadonnées : $(ConvertTo-UckkSafeReportText -Value $Metadata)"
    }

    $technicalText = $technicalLines -join [Environment]::NewLine
    $safeSourceUsed = ConvertTo-UckkSafeReportText -Value $sourceUsed

    return @"
# Rapport — $action

## Résumé

Statut : $status

$safeSummary

## Action demandée

$action

## Cible

$target

## Niveau de danger

$dangerLevel

## Mode

$mode

## Source utilisée

$safeSourceUsed

## Étapes exécutées

$stepsText

## Changements

$changesText

## Avertissements

$warningsText

## Erreurs

$errorsText

## Résultat final

$status

## Prochaine étape

$safeNextStep

## Détail technique

~~~text
$technicalText
~~~

## Données structurées

$dataText
"@
}

function Write-UckkReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Result,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config = $null,

        [Parameter(Mandatory = $false)]
        [string] $BasePath = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Metadata = $null,

        [Parameter(Mandatory = $false)]
        [switch] $PassThru
    )

    $action = [string] (Get-UckkResultProperty -Result $Result -Name "action" -Default "action")
    $domain = [string] (Get-UckkResultProperty -Result $Result -Name "domain" -Default "general")
    $target = [string] (Get-UckkResultProperty -Result $Result -Name "target" -Default "")

    $reportDir = Resolve-UckkReportDirectory -Config $Config -BasePath $BasePath

    if (-not (Test-Path -LiteralPath $reportDir -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }
        catch {
            throw "Le dossier des rapports ne peut pas être créé : $reportDir. Détail technique : $($_.Exception.Message)"
        }
    }

    $fileName = New-UckkReportFileName -Domain $domain -Action $action -Target $target
    $finalPath = Join-Path $reportDir $fileName
    $tempPath = "$finalPath.tmp"

    $markdown = Format-UckkReportMarkdown -Result $Result -Metadata $Metadata

    try {
        [System.IO.File]::WriteAllText($tempPath, $markdown, [System.Text.UTF8Encoding]::new($false))

        if (Test-Path -LiteralPath $finalPath -PathType Leaf) {
            Remove-Item -LiteralPath $finalPath -Force
        }

        Rename-Item -LiteralPath $tempPath -NewName (Split-Path -Leaf $finalPath) -Force
    }
    catch {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }

        throw "Le rapport n’a pas pu être écrit. Détail technique : $($_.Exception.Message)"
    }

    if ($PassThru) {
        return [pscustomobject]@{
            success     = $true
            status      = "Réussi"
            action      = "Écrire rapport"
            domain      = "configuration"
            target      = $finalPath
            dangerLevel = 1
            mode        = "application"
            summary     = "Rapport écrit : $finalPath"
            warnings    = @()
            errors      = @()
            nextStep    = "Ouvrir le rapport si nécessaire."
            reportPath  = $finalPath
            logPath     = ""
            data        = @{
                reportPath = $finalPath
            }
        }
    }

    return $finalPath
}

function Get-UckkReports {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config = $null,

        [Parameter(Mandatory = $false)]
        [string] $BasePath = "",

        [Parameter(Mandatory = $false)]
        [int] $Limit = 50
    )

    $reportDir = Resolve-UckkReportDirectory -Config $Config -BasePath $BasePath

    if (-not (Test-Path -LiteralPath $reportDir -PathType Container)) {
        return @()
    }

    $items = Get-ChildItem -LiteralPath $reportDir -Filter "*.md" -File | Sort-Object LastWriteTime -Descending

    if ($Limit -gt 0) {
        $items = $items | Select-Object -First $Limit
    }

    return @($items)
}

function Get-UckkLatestReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config = $null,

        [Parameter(Mandatory = $false)]
        [string] $BasePath = ""
    )

    $reports = @(Get-UckkReports -Config $Config -BasePath $BasePath -Limit 1)

    if ($reports.Count -eq 0) {
        return $null
    }

    return $reports[0].FullName
}

function New-UckkReportPreview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Result
    )

    $status = [string] (Get-UckkResultProperty -Result $Result -Name "status" -Default "Non applicable.")
    $action = [string] (Get-UckkResultProperty -Result $Result -Name "action" -Default "Action inconnue")
    $target = [string] (Get-UckkResultProperty -Result $Result -Name "target" -Default "Non applicable.")
    $summary = [string] (Get-UckkResultProperty -Result $Result -Name "summary" -Default "")
    $nextStep = [string] (Get-UckkResultProperty -Result $Result -Name "nextStep" -Default "Aucune action requise.")
    $reportPath = [string] (Get-UckkResultProperty -Result $Result -Name "reportPath" -Default "")

    $lines = @()
    $lines += "Statut : $status"
    $lines += "Action : $action"
    $lines += "Cible : $target"

    if (-not [string]::IsNullOrWhiteSpace($summary)) {
        $lines += "Résumé : $(ConvertTo-UckkSafeReportText -Value $summary)"
    }

    if (-not [string]::IsNullOrWhiteSpace($nextStep)) {
        $lines += "Prochaine étape : $(ConvertTo-UckkSafeReportText -Value $nextStep)"
    }

    if (-not [string]::IsNullOrWhiteSpace($reportPath)) {
        $lines += "Rapport : $reportPath"
    }

    return ($lines -join [Environment]::NewLine)
}

Export-ModuleMember -Function @(
    "Get-UckkReportDirectory",
    "Resolve-UckkReportDirectory",
    "ConvertTo-UckkSafeReportText",
    "ConvertTo-UckkReportSlug",
    "New-UckkReportFileName",
    "ConvertTo-UckkMarkdownList",
    "ConvertTo-UckkMarkdownCodeBlock",
    "Get-UckkResultProperty",
    "Format-UckkReportMarkdown",
    "Write-UckkReport",
    "Get-UckkReports",
    "Get-UckkLatestReport",
    "New-UckkReportPreview"
)

