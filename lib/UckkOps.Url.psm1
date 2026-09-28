#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  URL helpers for UCKK Ops Console.

.DESCRIPTION
  This module validates, normalizes, opens, and checks URLs.

  It must not:
    - modify local files;
    - modify Git;
    - modify Moodle;
    - modify the server;
    - write reports directly;
    - write logs directly;
    - contain workflow-specific business logic.

  Reports and logs are handled by the caller.
#>

function New-UckkUrlActionResult {
    [CmdletBinding()]
    param(
        [bool]$Success = $false,

        [string]$Status = "Échoué",

        [string]$Action = "URL",

        [string]$Target = "aucune cible modifiée",

        [string]$Mode = "vérification",

        [string]$Summary = "",

        [string[]]$Warnings = @(),

        [string[]]$Errors = @(),

        [string]$NextStep = "",

        [object]$Data = $null
    )

    if (Get-Command -Name New-UckkActionResult -ErrorAction SilentlyContinue) {
        return New-UckkActionResult `
            -Success $Success `
            -Status $Status `
            -Action $Action `
            -Domain "configuration" `
            -Target $Target `
            -DangerLevel 1 `
            -Mode $Mode `
            -Summary $Summary `
            -Warnings $Warnings `
            -Errors $Errors `
            -NextStep $NextStep `
            -ReportPath "" `
            -LogPath "" `
            -Data $Data
    }

    return [pscustomobject]@{
        success     = $Success
        status      = $Status
        action      = $Action
        domain      = "configuration"
        target      = $Target
        dangerLevel = 1
        mode        = $Mode
        summary     = $Summary
        warnings    = $Warnings
        errors      = $Errors
        nextStep    = $NextStep
        reportPath  = ""
        logPath     = ""
        data        = $Data
    }
}

function Test-UckkUrlString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Url,

        [string[]]$AllowedSchemes = @("http", "https")
    )

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return $false
    }

    $uri = $null
    $ok = [System.Uri]::TryCreate(
        $Url.Trim(),
        [System.UriKind]::Absolute,
        [ref]$uri
    )

    if (-not $ok) {
        return $false
    }

    if ($null -eq $uri.Scheme) {
        return $false
    }

    return $AllowedSchemes -contains $uri.Scheme.ToLowerInvariant()
}

function ConvertTo-UckkUri {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Url,

        [string[]]$AllowedSchemes = @("http", "https")
    )

    if (-not (Test-UckkUrlString -Url $Url -AllowedSchemes $AllowedSchemes)) {
        throw "URL invalide ou non autorisée : $Url"
    }

    return [System.Uri]::new($Url.Trim())
}

function Normalize-UckkUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Url,

        [string[]]$AllowedSchemes = @("http", "https"),

        [switch]$RemoveTrailingSlash
    )

    $uri = ConvertTo-UckkUri -Url $Url -AllowedSchemes $AllowedSchemes
    $normalized = $uri.AbsoluteUri

    if ($RemoveTrailingSlash -and $normalized.Length -gt 1) {
        $normalized = $normalized.TrimEnd("/")
    }

    return $normalized
}

function Join-UckkUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,

        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    $baseUri = ConvertTo-UckkUri -Url $BaseUrl

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $baseUri.AbsoluteUri
    }

    $cleanRelativePath = $RelativePath.Trim()

    while ($cleanRelativePath.StartsWith("/")) {
        $cleanRelativePath = $cleanRelativePath.Substring(1)
    }

    $combined = [System.Uri]::new($baseUri, $cleanRelativePath)

    return $combined.AbsoluteUri
}

function Get-UckkUrlHost {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $uri = ConvertTo-UckkUri -Url $Url
    return $uri.Host
}

function Test-UckkUrlIsLocal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $uri = ConvertTo-UckkUri -Url $Url
    $host = $uri.Host.ToLowerInvariant()

    return @(
        "localhost",
        "127.0.0.1",
        "::1"
    ) -contains $host
}

function Test-UckkUrlIsServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [string]$ExpectedHost = "uckk.org"
    )

    $uri = ConvertTo-UckkUri -Url $Url
    return $uri.Host.ToLowerInvariant() -eq $ExpectedHost.ToLowerInvariant()
}

function Test-UckkUrlReachable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [ValidateSet("Head", "Get")]
        [string]$Method = "Get",

        [int]$TimeoutSeconds = 15,

        [int[]]$AcceptStatusCodes = @(200)
    )

    $action = "Vérifier URL"

    try {
        $normalizedUrl = Normalize-UckkUrl -Url $Url

        $response = Invoke-WebRequest `
            -Uri $normalizedUrl `
            -Method $Method `
            -TimeoutSec $TimeoutSeconds `
            -MaximumRedirection 5 `
            -ErrorAction Stop

        $statusCode = [int]$response.StatusCode
        $ok = $AcceptStatusCodes -contains $statusCode

        $data = [pscustomobject]@{
            url          = $normalizedUrl
            method       = $Method
            statusCode   = $statusCode
            statusText   = $response.StatusDescription
            contentType  = $response.Headers["Content-Type"]
            finalUrl     = $response.BaseResponse.ResponseUri.AbsoluteUri
            expectedCode = $AcceptStatusCodes
        }

        if ($ok) {
            return New-UckkUrlActionResult `
                -Success $true `
                -Status "Réussi" `
                -Action $action `
                -Target $normalizedUrl `
                -Mode "vérification" `
                -Summary "Réussi — l’URL répond avec le code HTTP $statusCode." `
                -NextStep "Aucune action requise, sauf vérification navigateur si la page dépend de JavaScript ou AJAX." `
                -Data $data
        }

        return New-UckkUrlActionResult `
            -Success $false `
            -Status "Échoué" `
            -Action $action `
            -Target $normalizedUrl `
            -Mode "vérification" `
            -Summary "L’action a échoué." `
            -Errors @("Code HTTP inattendu : $statusCode.") `
            -NextStep "Vérifier l’URL dans le navigateur ou lire le log technique si cette action est appelée par un workflow." `
            -Data $data
    }
    catch {
        return New-UckkUrlActionResult `
            -Success $false `
            -Status "Échoué" `
            -Action $action `
            -Target $Url `
            -Mode "vérification" `
            -Summary "L’action a échoué." `
            -Errors @("Cause probable : l’URL ne répond pas, est invalide ou la connexion a expiré.") `
            -NextStep "Vérifier l’URL, la connexion réseau ou le serveur ciblé." `
            -Data ([pscustomobject]@{
                url     = $Url
                method  = $Method
                error   = $_.Exception.Message
                timeout = $TimeoutSeconds
            })
    }
}

function Open-UckkUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    $action = "Ouvrir URL"

    try {
        $normalizedUrl = Normalize-UckkUrl -Url $Url

        Start-Process $normalizedUrl

        return New-UckkUrlActionResult `
            -Success $true `
            -Status "Réussi" `
            -Action $action `
            -Target $normalizedUrl `
            -Mode "navigation" `
            -Summary "Réussi — l’URL a été ouverte dans le navigateur." `
            -NextStep "Vérifier visuellement la page dans le navigateur." `
            -Data ([pscustomobject]@{
                url = $normalizedUrl
            })
    }
    catch {
        return New-UckkUrlActionResult `
            -Success $false `
            -Status "Échoué" `
            -Action $action `
            -Target $Url `
            -Mode "navigation" `
            -Summary "L’action a échoué." `
            -Errors @("Cause probable : l’URL est invalide ou le navigateur n’a pas pu être ouvert.") `
            -NextStep "Vérifier l’URL, puis réessayer." `
            -Data ([pscustomobject]@{
                url   = $Url
                error = $_.Exception.Message
            })
    }
}

function Test-UckkConfiguredUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config,
[Parameter(Mandatory)]
        [string]$PropertyPath
    )

    $parts = $PropertyPath.Split(".")
    $current = $Config

    foreach ($part in $parts) {
        if ($null -eq $current) {
            return New-UckkUrlActionResult `
                -Success $false `
                -Status "Échoué" `
                -Action "Vérifier URL configurée" `
                -Target $PropertyPath `
                -Mode "vérification" `
                -Summary "L’action a échoué." `
                -Errors @("La configuration ne contient pas la propriété attendue : $PropertyPath.") `
                -NextStep "Corriger la configuration."
        }

        if ($current.PSObject.Properties.Name -notcontains $part) {
            return New-UckkUrlActionResult `
                -Success $false `
                -Status "Échoué" `
                -Action "Vérifier URL configurée" `
                -Target $PropertyPath `
                -Mode "vérification" `
                -Summary "L’action a échoué." `
                -Errors @("La configuration ne contient pas la propriété attendue : $PropertyPath.") `
                -NextStep "Corriger la configuration."
        }

        $current = $current.$part
    }

    $url = [string]$current

    if (Test-UckkUrlString -Url $url) {
        return New-UckkUrlActionResult `
            -Success $true `
            -Status "Réussi" `
            -Action "Vérifier URL configurée" `
            -Target $PropertyPath `
            -Mode "vérification" `
            -Summary "Réussi — l’URL configurée est valide." `
            -NextStep "Aucune action requise." `
            -Data ([pscustomobject]@{
                propertyPath = $PropertyPath
                url          = $url
            })
    }

    return New-UckkUrlActionResult `
        -Success $false `
        -Status "Échoué" `
        -Action "Vérifier URL configurée" `
        -Target $PropertyPath `
        -Mode "vérification" `
        -Summary "L’action a échoué." `
        -Errors @("L’URL configurée est vide, invalide ou non autorisée.") `
        -NextStep "Corriger la valeur dans la configuration." `
        -Data ([pscustomobject]@{
            propertyPath = $PropertyPath
            url          = $url
        })
}

function Get-UckkStandardUrlsFromConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $urls = [ordered]@{}

    if ($Config.PSObject.Properties.Name -contains "urls") {
        $urlConfig = $Config.urls

        foreach ($prop in $urlConfig.PSObject.Properties) {
            $urls[$prop.Name] = [string]$prop.Value
        }
    }

    return $urls
}

function Test-UckkStandardUrlsFromConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $urls = Get-UckkStandardUrlsFromConfig -Config $Config
    $items = @()
    $errors = @()

    foreach ($key in $urls.Keys) {
        $url = [string]$urls[$key]
        $valid = Test-UckkUrlString -Url $url

        $items += [pscustomobject]@{
            name  = $key
            url   = $url
            valid = $valid
        }

        if (-not $valid) {
            $errors += "URL invalide : urls.$key = $url"
        }
    }

    if ($errors.Count -gt 0) {
        return New-UckkUrlActionResult `
            -Success $false `
            -Status "Échoué" `
            -Action "Vérifier URLs configurées" `
            -Target "configuration" `
            -Mode "vérification" `
            -Summary "L’action a échoué." `
            -Errors $errors `
            -NextStep "Corriger les URLs dans la configuration." `
            -Data $items
    }

    return New-UckkUrlActionResult `
        -Success $true `
        -Status "Réussi" `
        -Action "Vérifier URLs configurées" `
        -Target "configuration" `
        -Mode "vérification" `
        -Summary "Réussi — les URLs configurées sont valides." `
        -NextStep "Aucune action requise." `
        -Data $items
}

function Get-UckkUrlBrowserWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [switch]$AjaxPage
    )

    $normalizedUrl = Normalize-UckkUrl -Url $Url

    if ($AjaxPage) {
        return "À vérifier dans le navigateur : $normalizedUrl — HTTP 200 ne suffit pas si la page charge des données par JavaScript ou AJAX."
    }

    return "À vérifier dans le navigateur : $normalizedUrl"
}

Export-ModuleMember `
    -Function New-UckkUrlActionResult, `
              Test-UckkUrlString, `
              ConvertTo-UckkUri, `
              Normalize-UckkUrl, `
              Join-UckkUrl, `
              Get-UckkUrlHost, `
              Test-UckkUrlIsLocal, `
              Test-UckkUrlIsServer, `
              Test-UckkUrlReachable, `
              Open-UckkUrl, `
              Test-UckkConfiguredUrl, `
              Get-UckkStandardUrlsFromConfig, `
              Test-UckkStandardUrlsFromConfig, `
              Get-UckkUrlBrowserWarning

