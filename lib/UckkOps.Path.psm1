#Requires -Version 7.0
<#
.SYNOPSIS
  Path helpers for UCKK Ops Console.

.DESCRIPTION
  Centralizes path validation, normalization, joining, creation and opening.

  This module must not contain domain logic.
  It must not hardcode project paths.
  It must not assume that local Windows paths and server Linux paths are interchangeable.

.CONTRACT
  See:
    docs/05_CONFIGURATION_ET_CHEMINS.md
    docs/10_RAPPORTS_LOGS_ERREURS.md
    docs/12_CONTRAT_TECHNIQUE_DU_CODE.md
#>

Set-StrictMode -Off
# ---------------------------------------------------------------------------
# Public: path type checks
# ---------------------------------------------------------------------------

function Test-UckkOpsWindowsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return ($Path -match '^[A-Za-z]:[\\/]' -or $Path -match '^\\\\')
}

function Test-UckkOpsLinuxPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return ($Path.StartsWith('/') -and -not (Test-UckkOpsWindowsPath -Path $Path))
}

function Test-UckkOpsRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    if (Test-UckkOpsWindowsPath -Path $Path) {
        return $false
    }

    if (Test-UckkOpsLinuxPath -Path $Path) {
        return $false
    }

    if ($Path -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
        return $false
    }

    return $true
}

function Test-UckkOpsUrlLikePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return ($Path -match '^[a-zA-Z][a-zA-Z0-9+.-]*://')
}

# ---------------------------------------------------------------------------
# Public: normalization
# ---------------------------------------------------------------------------

function Normalize-UckkOpsLocalPath {
    <#
    .SYNOPSIS
      Normalizes a local Windows path.

    .DESCRIPTION
      Expands environment variables, resolves relative paths against a base path,
      and returns a clean local path string.

      This function is for local paths only.
      It refuses Linux server paths and URLs.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter()]
        [string] $BasePath = (Get-Location).Path,

        [Parameter()]
        [switch] $AllowMissing
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path is empty."
    }

    if (Test-UckkOpsUrlLikePath -Path $Path) {
        throw "Expected a local path, got a URL: $Path"
    }

    if (Test-UckkOpsLinuxPath -Path $Path) {
        throw "Expected a local Windows path, got a Linux/server path: $Path"
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim())

    if (Test-UckkOpsRelativePath -Path $expanded) {
        $expanded = Join-Path -Path $BasePath -ChildPath $expanded
    }

    try {
        if (Test-Path -LiteralPath $expanded) {
            return (Resolve-Path -LiteralPath $expanded).Path
        }

        if ($AllowMissing) {
            return [System.IO.Path]::GetFullPath($expanded)
        }

        throw "Path does not exist: $expanded"
    }
    catch {
        if ($AllowMissing) {
            return [System.IO.Path]::GetFullPath($expanded)
        }

        throw
    }
}

function Normalize-UckkOpsServerPath {
    <#
    .SYNOPSIS
      Normalizes a Linux server path.

    .DESCRIPTION
      This function is for server paths only.
      It refuses Windows paths and URLs.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Server path is empty."
    }

    $clean = $Path.Trim()

    if (Test-UckkOpsUrlLikePath -Path $clean) {
        throw "Expected a server path, got a URL: $clean"
    }

    if (Test-UckkOpsWindowsPath -Path $clean) {
        throw "Expected a Linux/server path, got a Windows path: $clean"
    }

    if (-not (Test-UckkOpsLinuxPath -Path $clean)) {
        throw "Server path must be absolute and start with '/': $clean"
    }

    while ($clean.Contains('//')) {
        $clean = $clean.Replace('//', '/')
    }

    if ($clean.Length -gt 1) {
        $clean = $clean.TrimEnd('/')
    }

    return $clean
}

function Normalize-UckkOpsPath {
    <#
    .SYNOPSIS
      Normalizes a path according to target environment.

    .PARAMETER Target
      local or server.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [ValidateSet("local", "server")]
        [string] $Target,

        [Parameter()]
        [string] $BasePath = (Get-Location).Path,

        [Parameter()]
        [switch] $AllowMissing
    )

    switch ($Target) {
        "local" {
            return Normalize-UckkOpsLocalPath `
                -Path $Path `
                -BasePath $BasePath `
                -AllowMissing:$AllowMissing
        }

        "server" {
            return Normalize-UckkOpsServerPath -Path $Path
        }
    }
}

# ---------------------------------------------------------------------------
# Public: joining
# ---------------------------------------------------------------------------

function Join-UckkOpsLocalPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $BasePath,

        [Parameter(Mandatory)]
        [string[]] $ChildPath
    )

    $current = Normalize-UckkOpsLocalPath -Path $BasePath -AllowMissing

    foreach ($part in $ChildPath) {
        if ([string]::IsNullOrWhiteSpace($part)) {
            continue
        }

        if (Test-UckkOpsLinuxPath -Path $part) {
            throw "Cannot join Linux/server path part to local path: $part"
        }

        if (Test-UckkOpsUrlLikePath -Path $part) {
            throw "Cannot join URL as local path part: $part"
        }

        $current = Join-Path -Path $current -ChildPath $part
    }

    return [System.IO.Path]::GetFullPath($current)
}

function Join-UckkOpsServerPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $BasePath,

        [Parameter(Mandatory)]
        [string[]] $ChildPath
    )

    $current = Normalize-UckkOpsServerPath -Path $BasePath

    foreach ($part in $ChildPath) {
        if ([string]::IsNullOrWhiteSpace($part)) {
            continue
        }

        if (Test-UckkOpsWindowsPath -Path $part) {
            throw "Cannot join Windows path part to server path: $part"
        }

        if (Test-UckkOpsUrlLikePath -Path $part) {
            throw "Cannot join URL as server path part: $part"
        }

        $cleanPart = $part.Trim().Trim('/').Trim('\')
        if ($cleanPart) {
            $current = "$current/$cleanPart"
        }
    }

    return Normalize-UckkOpsServerPath -Path $current
}

function Join-UckkOpsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("local", "server")]
        [string] $Target,

        [Parameter(Mandatory)]
        [string] $BasePath,

        [Parameter(Mandatory)]
        [string[]] $ChildPath
    )

    switch ($Target) {
        "local" {
            return Join-UckkOpsLocalPath -BasePath $BasePath -ChildPath $ChildPath
        }

        "server" {
            return Join-UckkOpsServerPath -BasePath $BasePath -ChildPath $ChildPath
        }
    }
}

# ---------------------------------------------------------------------------
# Public: existence checks
# ---------------------------------------------------------------------------

function Test-UckkOpsPath {
    <#
    .SYNOPSIS
      Tests a local path and returns a structured result.

    .DESCRIPTION
      This function only checks local paths.
      Server paths must be checked through SSH in UckkOps.Server.psm1.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter()]
        [ValidateSet("Any", "File", "Directory")]
        [string] $Type = "Any",

        [Parameter()]
[string] $Label = "Chemin"
    )

    $result = [ordered]@{
        label      = $Label
        path       = $Path
        exists     = $false
        type       = $Type
        isFile     = $false
        isDirectory= $false
        ok         = $false
        message    = ""
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $result.message = "$Label vide."
        return [pscustomobject]$result
    }

    if (Test-UckkOpsLinuxPath -Path $Path) {
        $result.message = "$Label est un chemin serveur. Utiliser une vérification serveur."
        return [pscustomobject]$result
    }

    if (Test-UckkOpsUrlLikePath -Path $Path) {
        $result.message = "$Label est une URL. Utiliser UckkOps.Url.psm1."
        return [pscustomobject]$result
    }

    $normalized = $null

    try {
        $normalized = Normalize-UckkOpsLocalPath -Path $Path -AllowMissing
        $result.path = $normalized
    }
    catch {
        $result.message = $_.Exception.Message
        return [pscustomobject]$result
    }

    $exists = Test-Path -LiteralPath $normalized

    $result.exists = $exists

    if (-not $exists) {
        $result.message = "$Label introuvable : $normalized"
        return [pscustomobject]$result
    }

    $item = Get-Item -LiteralPath $normalized -ErrorAction Stop

    $result.isDirectory = [bool] $item.PSIsContainer
    $result.isFile = -not $item.PSIsContainer

    switch ($Type) {
        "Any" {
            $result.ok = $true
        }

        "File" {
            $result.ok = $result.isFile
        }

        "Directory" {
            $result.ok = $result.isDirectory
        }
    }

    if ($result.ok) {
        $result.message = "$Label valide : $normalized"
    }
    else {
        $result.message = "$Label trouvé, mais le type attendu est $Type : $normalized"
    }

    return [pscustomobject]$result
}

function Assert-UckkOpsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter()]
        [ValidateSet("Any", "File", "Directory")]
        [string] $Type = "Any",

        [Parameter()]
        [string] $Label = "Chemin"
    )

    $check = Test-UckkOpsPath -Path $Path -Type $Type -Label $Label

    if (-not $check.ok) {
        throw $check.message
    }

    return $check.path
}

# ---------------------------------------------------------------------------
# Public: directory creation
# ---------------------------------------------------------------------------

function New-UckkOpsDirectoryIfMissing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter()]
        [string] $Label = "Dossier"
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "$Label vide."
    }

    if (Test-UckkOpsLinuxPath -Path $Path) {
        throw "$Label est un chemin serveur. Création locale refusée : $Path"
    }

    if (Test-UckkOpsUrlLikePath -Path $Path) {
        throw "$Label est une URL. Création de dossier refusée : $Path"
    }

    $normalized = Normalize-UckkOpsLocalPath -Path $Path -AllowMissing

    if (Test-Path -LiteralPath $normalized) {
        $item = Get-Item -LiteralPath $normalized -ErrorAction Stop

        if (-not $item.PSIsContainer) {
            throw "$Label existe mais n’est pas un dossier : $normalized"
        }

        return $normalized
    }

    New-Item -ItemType Directory -Path $normalized -Force | Out-Null

    return (Resolve-Path -LiteralPath $normalized).Path
}

# ---------------------------------------------------------------------------
# Public: configured paths
# ---------------------------------------------------------------------------

function Get-UckkOpsConfiguredPath {
    <#
    .SYNOPSIS
      Reads a nested path from config.

    .EXAMPLE
      Get-UckkOpsConfiguredPath -Config $config -Name "paths.localMoodleRoot"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config,

        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter()]
        [string] $Default = ""
    )

    $value = Get-UckkOpsNestedValue -Object $Config -Name $Name -Default $Default

    if ($null -eq $value) {
        return $Default
    }

    return [string] $value
}

function Get-UckkOpsProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config
    )

    $root = Get-UckkOpsConfiguredPath -Config $Config -Name "app.root" -Default ""

    if (-not $root) {
        $root = Get-UckkOpsConfiguredPath -Config $Config -Name "paths.appRoot" -Default ""
    }

    if (-not $root) {
        throw "Racine de l’application absente de la configuration."
    }

    return Normalize-UckkOpsLocalPath -Path $root -AllowMissing
}

function Get-UckkOpsConfigFilePath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $ProjectRoot = (Get-Location).Path
    )

    return Join-UckkOpsLocalPath `
        -BasePath $ProjectRoot `
        -ChildPath @("config", "uckk-ops-console.config.json")
}

function Get-UckkOpsReportsDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config
    )

    $configured = Get-UckkOpsConfiguredPath -Config $Config -Name "reports.dir" -Default "./reports"
    $root = Get-UckkOpsProjectRoot -Config $Config

    if (Test-UckkOpsRelativePath -Path $configured) {
        return Normalize-UckkOpsLocalPath -Path $configured -BasePath $root -AllowMissing
    }

    return Normalize-UckkOpsLocalPath -Path $configured -AllowMissing
}

function Get-UckkOpsLogsDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config
    )

    $configured = Get-UckkOpsConfiguredPath -Config $Config -Name "logs.dir" -Default "./logs"
    $root = Get-UckkOpsProjectRoot -Config $Config

    if (Test-UckkOpsRelativePath -Path $configured) {
        return Normalize-UckkOpsLocalPath -Path $configured -BasePath $root -AllowMissing
    }

    return Normalize-UckkOpsLocalPath -Path $configured -AllowMissing
}

function Initialize-UckkOpsOutputDirectories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Config
    )

    $reportsDir = Get-UckkOpsReportsDir -Config $Config
    $logsDir = Get-UckkOpsLogsDir -Config $Config

    $reportsDir = New-UckkOpsDirectoryIfMissing -Path $reportsDir -Label "Dossier des rapports"
    $logsDir = New-UckkOpsDirectoryIfMissing -Path $logsDir -Label "Dossier des logs"

    return [pscustomobject]@{
        reportsDir = $reportsDir
        logsDir    = $logsDir
    }
}

# ---------------------------------------------------------------------------
# Public: opening paths
# ---------------------------------------------------------------------------

function Open-UckkPath {
    <#
    .SYNOPSIS
      Opens a local file or directory.

    .DESCRIPTION
      This is a navigation action.
      It does not modify project data.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Chemin vide."
    }

    if (Test-UckkOpsLinuxPath -Path $Path) {
        throw "Impossible d’ouvrir directement un chemin serveur localement : $Path"
    }

    if (Test-UckkOpsUrlLikePath -Path $Path) {
        throw "Open-UckkPath attend un chemin local, pas une URL : $Path"
    }

    $normalized = Assert-UckkOpsPath -Path $Path -Type "Any" -Label "Chemin à ouvrir"

    Start-Process -FilePath $normalized | Out-Null

    return [pscustomobject]@{
        success     = $true
        status      = "Réussi"
        action      = "Ouvrir chemin"
        domain      = "history"
        target      = $normalized
        dangerLevel = 0
        mode        = "navigation"
        summary     = "Chemin ouvert : $normalized"
        warnings    = @()
        errors      = @()
        nextStep    = "Aucune action requise."
        reportPath  = ""
        logPath     = ""
        data        = @{
            path = $normalized
        }
    }
}

# ---------------------------------------------------------------------------
# Public: display helpers
# ---------------------------------------------------------------------------

function ConvertTo-UckkOpsDisplayPath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }

    return $Path.Trim()
}

function Get-UckkOpsPathKind {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (Test-UckkOpsUrlLikePath -Path $Path) {
        return "url"
    }

    if (Test-UckkOpsWindowsPath -Path $Path) {
        return "windows"
}

    if (Test-UckkOpsLinuxPath -Path $Path) {
        return "linux"
    }

    if (Test-UckkOpsRelativePath -Path $Path) {
        return "relative"
    }

    return "unknown"
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

function Get-UckkOpsNestedValue {
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

    $current = $Object

    foreach ($part in $Name.Split(".")) {
        if (-not $current) {
            return $Default
        }

        if ($current -is [hashtable]) {
            if ($current.ContainsKey($part)) {
                $current = $current[$part]
                continue
            }

            return $Default
        }

        if ($current -is [System.Collections.IDictionary]) {
            if ($current.Contains($part)) {
                $current = $current[$part]
                continue
            }

            return $Default
        }

        if ($current.PSObject.Properties.Name -contains $part) {
            $current = $current.$part
            continue
        }

        return $Default
    }

    return $current
}

Export-ModuleMember -Function @(
    "Test-UckkOpsWindowsPath",
    "Test-UckkOpsLinuxPath",
    "Test-UckkOpsRelativePath",
    "Test-UckkOpsUrlLikePath",
    "Normalize-UckkOpsLocalPath",
    "Normalize-UckkOpsServerPath",
    "Normalize-UckkOpsPath",
    "Join-UckkOpsLocalPath",
    "Join-UckkOpsServerPath",
    "Join-UckkOpsPath",
    "Test-UckkOpsPath",
    "Assert-UckkOpsPath",
    "New-UckkOpsDirectoryIfMissing",
    "Get-UckkOpsConfiguredPath",
    "Get-UckkOpsProjectRoot",
    "Get-UckkOpsConfigFilePath",
    "Get-UckkOpsReportsDir",
    "Get-UckkOpsLogsDir",
    "Initialize-UckkOpsOutputDirectories",
    "Open-UckkPath",
    "ConvertTo-UckkOpsDisplayPath",
    "Get-UckkOpsPathKind"
)

