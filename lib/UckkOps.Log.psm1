#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Technical log module for UCKK Ops Console.

.DESCRIPTION
  Writes detailed technical logs.

  Contract:
    - Logs are technical.
    - Reports are user-facing.
    - This module must not execute business actions.
    - This module must stay domain-neutral.
    - Secrets must be masked before writing.
#>

$script:UckkCurrentLogContext = $null

function Get-UckkLogTimestamp {
    [CmdletBinding()]
    param()

    return (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

function Get-UckkLogFileTimestamp {
    [CmdletBinding()]
    param()

    return (Get-Date).ToString("yyyyMMdd_HHmmss")
}

function Get-UckkLogConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Default = $null
    )

    if ($null -eq $Config) {
        return $Default
    }

    $current = $Config

    foreach ($part in ($Path -split "\.")) {
        if ($null -eq $current) {
            return $Default
        }

        if ($current -is [System.Collections.IDictionary]) {
            if (-not $current.Contains($part)) {
                return $Default
            }

            $current = $current[$part]
            continue
        }

        $property = $current.PSObject.Properties[$part]

        if ($null -eq $property) {
            return $Default
        }

        $current = $property.Value
    }

    if ($null -eq $current) {
        return $Default
    }

    return $current
}

function ConvertTo-UckkSafeLogName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value
    )

    $safe = $Value.Trim().ToLowerInvariant()

    $safe = $safe -replace "[àáâäãå]", "a"
    $safe = $safe -replace "[èéêë]", "e"
    $safe = $safe -replace "[ìíîï]", "i"
    $safe = $safe -replace "[òóôöõ]", "o"
    $safe = $safe -replace "[ùúûü]", "u"
    $safe = $safe -replace "[ç]", "c"
    $safe = $safe -replace "[^a-z0-9]+", "_"
    $safe = $safe -replace "_+", "_"
    $safe = $safe.Trim("_")

    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "log"
    }

    return $safe
}

function Protect-UckkLogText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return ""
    }

    $text = [string] $Value

    $patterns = @(
        "(?i)(password\s*[:=]\s*)[^;\s,}`"]+",
        "(?i)(passwd\s*[:=]\s*)[^;\s,}`"]+",
        "(?i)(token\s*[:=]\s*)[^;\s,}`"]+",
        "(?i)(secret\s*[:=]\s*)[^;\s,}`"]+",
        "(?i)(api[_-]?key\s*[:=]\s*)[^;\s,}`"]+",
        "(?i)(private[_-]?key\s*[:=]\s*)[^;\s,}`"]+",
        "(?i)(cookie\s*[:=]\s*)[^;\s,}`"]+",
        "(?i)(session\s*[:=]\s*)[^;\s,}`"]+"
    )

    foreach ($pattern in $patterns) {
        $text = [regex]::Replace($text, $pattern, '$1[masqué]')
    }

    return $text
}

function ConvertTo-UckkLogText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return ""
    }

    if ($Value -is [string]) {
        return (Protect-UckkLogText -Value $Value)
    }

    try {
        $json = $Value | ConvertTo-Json -Depth 20
        return (Protect-UckkLogText -Value $json)
    }
    catch {
        return (Protect-UckkLogText -Value ([string] $Value))
    }
}

function Resolve-UckkLogDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $AppRoot = ""
    )

    $logDir = Get-UckkLogConfigValue -Config $Config -Path "logs.dir" -Default $null

    if ([string]::IsNullOrWhiteSpace([string] $logDir)) {
        $logDir = Get-UckkLogConfigValue -Config $Config -Path "paths.logsDir" -Default "./logs"
    }

    $logDirText = [string] $logDir

    if ([string]::IsNullOrWhiteSpace($logDirText)) {
        $logDirText = "./logs"
    }

    if ([System.IO.Path]::IsPathRooted($logDirText)) {
        return [System.IO.Path]::GetFullPath($logDirText)
    }

    if ([string]::IsNullOrWhiteSpace($AppRoot)) {
        if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            $AppRoot = Split-Path -Path $PSScriptRoot -Parent
        }
        else {
            $AppRoot = (Get-Location).Path
        }
    }

    return [System.IO.Path]::GetFullPath((Join-Path $AppRoot $logDirText))
}

function Initialize-UckkLogDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $AppRoot = ""
    )

    $logDir = Resolve-UckkLogDirectory -Config $Config -AppRoot $AppRoot

    if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    return $logDir
}

function New-UckkLogPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $false)]
        [string] $Domain = "general",

        [Parameter(Mandatory = $false)]
        [string] $Target = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $AppRoot = ""
    )

    $logDir = Initialize-UckkLogDirectory -Config $Config -AppRoot $AppRoot

    $timestamp = Get-UckkLogFileTimestamp
    $safeDomain = ConvertTo-UckkSafeLogName -Value $Domain
    $safeAction = ConvertTo-UckkSafeLogName -Value $Action

    if (-not [string]::IsNullOrWhiteSpace($Target)) {
        $safeTarget = ConvertTo-UckkSafeLogName -Value $Target
        $fileName = "$timestamp`_$safeDomain`_$safeAction`_$safeTarget.log"
    }
    else {
        $fileName = "$timestamp`_$safeDomain`_$safeAction.log"
    }

    return (Join-Path $logDir $fileName)
}

function New-UckkLogContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [string] $Domain,

        [Parameter(Mandatory = $false)]
        [string] $Target = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $AppRoot = "",

        [Parameter(Mandatory = $false)]
        [string] $ReportPath = ""
    )

    $logPath = New-UckkLogPath -Action $Action -Domain $Domain -Target $Target -Config $Config -AppRoot $AppRoot
    $startedAt = Get-UckkLogTimestamp

    $context = [pscustomobject]@{
        action     = $Action
        domain     = $Domain
        target     = $Target
        startedAt  = $startedAt
        endedAt    = ""
        logPath    = $logPath
        reportPath = $ReportPath
    }

    $headerLines = [System.Collections.Generic.List[string]]::new()
    $headerLines.Add("UCKK Ops Console — log technique")
    $headerLines.Add("")
    $headerLines.Add("Début : $startedAt")
    $headerLines.Add("Action : $(Protect-UckkLogText -Value $Action)")
    $headerLines.Add("Domaine : $(Protect-UckkLogText -Value $Domain)")
    $headerLines.Add("Cible : $(Protect-UckkLogText -Value $Target)")

    if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
        $headerLines.Add("Rapport : $(Protect-UckkLogText -Value $ReportPath)")
    }

    $headerLines.Add("")
    $headerLines.Add("Entrées")
    $headerLines.Add("-------")
    $headerLines.Add("")

    [System.IO.File]::WriteAllText(
        $logPath,
        ($headerLines -join [Environment]::NewLine),
        [System.Text.UTF8Encoding]::new($false)
    )

    $script:UckkCurrentLogContext = $context

    return $context
}

function Add-UckkLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Context,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string] $Level = "INFO",

        [Parameter(Mandatory = $true)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null
    )

    if ($null -eq $Context) {
        return
    }
if ([string]::IsNullOrWhiteSpace([string] $Context.LogPath)) {
        return
    }

    $timestamp = Get-UckkLogTimestamp
    $safeMessage = Protect-UckkLogText -Value $Message

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("[$timestamp] [$Level] $safeMessage")

    if ($null -ne $Data) {
        $lines.Add("Données :")
        $lines.Add((ConvertTo-UckkLogText -Value $Data))
    }

    $lines.Add("")

    Add-Content -LiteralPath $Context.LogPath -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
}

function Add-UckkLogCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Context,

        [Parameter(Mandatory = $true)]
        [string] $Command,

        [Parameter(Mandatory = $false)]
        [string] $WorkingDirectory = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $ExitCode = $null,

        [Parameter(Mandatory = $false)]
        [string] $Stdout = "",

        [Parameter(Mandatory = $false)]
        [string] $Stderr = ""
    )

    $data = [ordered]@{
        command          = $Command
        workingDirectory = $WorkingDirectory
        exitCode         = $ExitCode
        stdout           = $Stdout
        stderr           = $Stderr
    }

    Add-UckkLogEntry -Context $Context -Level "DEBUG" -Message "Commande exécutée." -Data $data
}

function Add-UckkLogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Context,

        [Parameter(Mandatory = $false)]
        [string] $Message = "Erreur capturée.",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $ErrorRecord = $null
    )

    $data = $null

    if ($null -ne $ErrorRecord) {
        try {
            $data = [ordered]@{
                exceptionMessage = $ErrorRecord.Exception.Message
                exceptionType    = $ErrorRecord.Exception.GetType().FullName
                scriptStackTrace = $ErrorRecord.ScriptStackTrace
                positionMessage  = $ErrorRecord.InvocationInfo.PositionMessage
            }
        }
        catch {
            $data = [string] $ErrorRecord
        }
    }

    Add-UckkLogEntry -Context $Context -Level "ERROR" -Message $Message -Data $data
}

function Complete-UckkLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Context,

        [Parameter(Mandatory = $false)]
        [string] $Status = "Terminé",

        [Parameter(Mandatory = $false)]
        [string] $Summary = ""
    )

    if ($null -eq $Context) {
        return
    }

    if ([string]::IsNullOrWhiteSpace([string] $Context.LogPath)) {
        return
    }

    $endedAt = Get-UckkLogTimestamp
    $Context.EndedAt = $endedAt

    $footerLines = [System.Collections.Generic.List[string]]::new()
    $footerLines.Add("")
    $footerLines.Add("Fin")
    $footerLines.Add("---")
    $footerLines.Add("Fin : $endedAt")
    $footerLines.Add("Statut : $(Protect-UckkLogText -Value $Status)")

    if (-not [string]::IsNullOrWhiteSpace($Summary)) {
        $footerLines.Add("Résumé : $(Protect-UckkLogText -Value $Summary)")
    }

    $footerLines.Add("")

    Add-Content -LiteralPath $Context.LogPath -Value ($footerLines -join [Environment]::NewLine) -Encoding UTF8
}

function Write-UckkLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $true)]
        [string] $Domain,

        [Parameter(Mandatory = $false)]
        [string] $Target = "",

        [Parameter(Mandatory = $false)]
        [string] $Message = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $AppRoot = "",

        [Parameter(Mandatory = $false)]
        [string] $ReportPath = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string] $Level = "INFO"
    )

    $context = New-UckkLogContext `
        -Action $Action `
        -Domain $Domain `
        -Target $Target `
        -Config $Config `
        -AppRoot $AppRoot `
        -ReportPath $ReportPath

    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        Add-UckkLogEntry -Context $context -Level $Level -Message $Message -Data $Data
    }

    Complete-UckkLog -Context $context -Status "Terminé" -Summary $Message

    return $context.LogPath
}

function Get-UckkCurrentLogContext {
    [CmdletBinding()]
    param()

    return $script:UckkCurrentLogContext
}

Export-ModuleMember -Function @(
    "Get-UckkLogTimestamp",
    "Get-UckkLogFileTimestamp",
    "Initialize-UckkLogDirectory",
    "Resolve-UckkLogDirectory",
    "New-UckkLogPath",
    "New-UckkLogContext",
    "Add-UckkLogEntry",
    "Add-UckkLogCommand",
    "Add-UckkLogError",
    "Complete-UckkLog",
    "Write-UckkLog",
    "Get-UckkCurrentLogContext",
    "Protect-UckkLogText",
    "ConvertTo-UckkLogText",
    "ConvertTo-UckkSafeLogName"
)

