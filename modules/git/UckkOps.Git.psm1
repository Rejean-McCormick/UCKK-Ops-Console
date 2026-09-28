#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Git operations for the UCKK Ops Console.

.DESCRIPTION
  This module handles Git checks and Git write actions.

  It must never publish to the server.
  It must never modify Moodle.
  It must never hide risky Git actions behind vague names.

  Public functions return ActionResult-compatible objects.
#>

function Get-UckkGitConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string[]] $Path,

        [Parameter(Mandatory = $false)]
        [object] $Default = $null
    )

    if ($null -eq $Config) {
        return $Default
    }

    $current = $Config

    foreach ($part in $Path) {
        if ($null -eq $current) {
            return $Default
        }

        if ($current -is [hashtable]) {
            if (-not $current.ContainsKey($part)) {
                return $Default
            }

            $current = $current[$part]
            continue
        }

        if ($current.PSObject.Properties.Name -notcontains $part) {
            return $Default
        }

        $current = $current.$part
    }

    if ($null -eq $current) {
        return $Default
    }

    return $current
}

function Resolve-UckkGitRepositoryRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        return [System.IO.Path]::GetFullPath($RepoRoot)
    }

    $configuredRepo = Get-UckkGitConfigValue -Config $Config -Path @('git', 'repoRoot') -Default ''
    if (-not [string]::IsNullOrWhiteSpace([string]$configuredRepo)) {
        return [System.IO.Path]::GetFullPath([string]$configuredRepo)
    }

    $sourcePath = Get-UckkGitConfigValue -Config $Config -Path @('paths', 'uckkMoodleSource') -Default ''
    if (-not [string]::IsNullOrWhiteSpace([string]$sourcePath)) {
        return [System.IO.Path]::GetFullPath([string]$sourcePath)
    }

    return [System.IO.Path]::GetFullPath((Get-Location).Path)
}

function Get-UckkGitRemoteName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config
    )

    $remote = Get-UckkGitConfigValue -Config $Config -Path @('git', 'remoteName') -Default 'origin'

    if ([string]::IsNullOrWhiteSpace([string]$remote)) {
        return 'origin'
    }

    return [string]$remote
}

function Get-UckkGitMainBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config
    )

    $branch = Get-UckkGitConfigValue -Config $Config -Path @('git', 'mainBranch') -Default ''

    if ([string]::IsNullOrWhiteSpace([string]$branch)) {
        return ''
    }

    return [string]$branch
}

function New-UckkGitActionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Success,

        [Parameter(Mandatory = $true)]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [string] $Action,

        [Parameter(Mandatory = $false)]
        [string] $Target = 'Git',

        [Parameter(Mandatory = $false)]
        [int] $DangerLevel = 1,

        [Parameter(Mandatory = $false)]
        [string] $Mode = 'vérification',

        [Parameter(Mandatory = $false)]
        [string] $Summary = '',

        [Parameter(Mandatory = $false)]
        [string[]] $Warnings = @(),

        [Parameter(Mandatory = $false)]
        [string[]] $Errors = @(),

        [Parameter(Mandatory = $false)]
        [string] $NextStep = 'Aucune action requise.',

        [Parameter(Mandatory = $false)]
        [string] $ReportPath = '',

        [Parameter(Mandatory = $false)]
        [string] $LogPath = '',

        [Parameter(Mandatory = $false)]
        [object] $Data = $null
    )

    return [pscustomobject]@{
        success     = $Success
        status      = $Status
        action      = $Action
        domain      = 'git'
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
    }
}

function Invoke-UckkGitCommandInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,

        [Parameter(Mandatory = $false)]
        [int] $TimeoutSeconds = 120
    )

    if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
        return [pscustomobject]@{
            success    = $false
            exitCode   = -1
            stdout     = ''
            stderr     = "Repository path not found: $RepoRoot"
            command    = "git $($Arguments -join ' ')"
            workingDir = $RepoRoot
        }
    }

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'git'
    $psi.WorkingDirectory = $RepoRoot
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    foreach ($arg in $Arguments) {
        [void]$psi.ArgumentList.Add($arg)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi

    try {
        [void]$process.Start()

        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()

        $completed = $process.WaitForExit($TimeoutSeconds * 1000)

        if (-not $completed) {
            try {
                $process.Kill($true)
            } catch {
                # Ignore kill errors.
            }

            return [pscustomobject]@{
                success    = $false
                exitCode   = -2
                stdout     = ''
                stderr     = "Git command timed out after $TimeoutSeconds seconds."
                command    = "git $($Arguments -join ' ')"
                workingDir = $RepoRoot
            }
        }

        return [pscustomobject]@{
            success    = ($process.ExitCode -eq 0)
            exitCode   = $process.ExitCode
            stdout     = $stdoutTask.Result
            stderr     = $stderrTask.Result
            command    = "git $($Arguments -join ' ')"
            workingDir = $RepoRoot
        }
    } catch {
        return [pscustomobject]@{
            success    = $false
            exitCode   = -3
            stdout     = ''
            stderr     = $_.Exception.Message
            command    = "git $($Arguments -join ' ')"
            workingDir = $RepoRoot
        }
    } finally {
        if ($null -ne $process) {
            $process.Dispose()
        }
    }
}

function ConvertTo-UckkGitLines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string] $Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    return @(
        $Text -split "`r?`n" |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Get-UckkGitChangedPathFromPorcelainLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Line
    )

    if ($Line.Length -lt 4) {
        return ''
    }

    $path = $Line.Substring(3).Trim()

    if ($path -match '\s+->\s+') {
        $parts = $path -split '\s+->\s+'
        return $parts[-1].Trim()
    }

    return $path.Trim('"')
}

function Get-UckkGitCurrentBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    $result = Invoke-UckkGitCommandInternal -RepoRoot $RepoRoot -Arguments @('rev-parse', '--abbrev-ref', 'HEAD')

    if (-not $result.success) {
        return ''
    }

    return $result.stdout.Trim()
}

function Test-UckkGitAvailable {
    [CmdletBinding()]
    param()

    $result = Invoke-UckkGitCommandInternal -RepoRoot (Get-Location).Path -Arguments @('--version') -TimeoutSeconds 15

    if (-not $result.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Vérifier Git disponible' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'Git ne semble pas disponible.' `
            -Errors @('Git est introuvable ou ne répond pas.') `
            -NextStep 'Installer Git ou vérifier que git est disponible dans le PATH.' `
            -Data $result
    }

    return New-UckkGitActionResult `
        -Success $true `
        -Status 'Réussi' `
        -Action 'Vérifier Git disponible' `
-DangerLevel 1 `
        -Mode 'vérification' `
        -Summary $result.stdout.Trim() `
        -NextStep 'Aucune action requise.' `
        -Data $result
}

function Test-UckkGitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = ''
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot

    if (-not (Test-Path -LiteralPath $resolvedRepo -PathType Container)) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Vérifier dépôt Git' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'Le dossier Git est introuvable.' `
            -Errors @("Dossier introuvable : $resolvedRepo") `
            -NextStep 'Vérifier la configuration git.repoRoot ou paths.uckkMoodleSource.' `
            -Data @{ repoRoot = $resolvedRepo }
    }

    $result = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('rev-parse', '--show-toplevel')

    if (-not $result.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Vérifier dépôt Git' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'Le dossier existe, mais Git ne le reconnaît pas comme dépôt.' `
            -Errors @($result.stderr.Trim()) `
            -NextStep 'Vérifier que le dossier contient un dépôt Git valide.' `
            -Data @{
                repoRoot = $resolvedRepo
                command  = $result
            }
    }

    return New-UckkGitActionResult `
        -Success $true `
        -Status 'Réussi' `
        -Action 'Vérifier dépôt Git' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'Le dépôt Git est valide.' `
        -NextStep 'Lancer "Vérifier Git" ou "Afficher les différences Git".' `
        -Data @{
            configuredRepoRoot = $resolvedRepo
            gitTopLevel        = $result.stdout.Trim()
        }
}

function Get-UckkGitStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = ''
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot
    $repoCheck = Test-UckkGitRepository -Config $Config -RepoRoot $resolvedRepo

    if (-not $repoCheck.success) {
        return $repoCheck
    }

    $statusResult = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('status', '--porcelain=v1', '-b', '--untracked-files=all')
    $branch = Get-UckkGitCurrentBranch -RepoRoot $resolvedRepo

    if (-not $statusResult.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Vérifier Git' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'Git status a échoué.' `
            -Errors @($statusResult.stderr.Trim()) `
            -NextStep 'Lire le détail technique, puis vérifier le dépôt Git.' `
            -Data @{
                repoRoot = $resolvedRepo
                command  = $statusResult
            }
    }

    $lines = ConvertTo-UckkGitLines -Text $statusResult.stdout
    $changeLines = @($lines | Where-Object { -not $_.StartsWith('##') })

    $changedPaths = @(
        foreach ($line in $changeLines) {
            Get-UckkGitChangedPathFromPorcelainLine -Line $line
        }
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $summary = if ($changedPaths.Count -eq 0) {
        'Git ne signale aucun changement.'
    } else {
        "Git signale $($changedPaths.Count) changement(s)."
    }

    $status = if ($changedPaths.Count -eq 0) {
        'Réussi'
    } else {
        'Réussi avec avertissements'
    }

    $nextStep = if ($changedPaths.Count -eq 0) {
        'Aucune action requise.'
    } else {
        'Lire les différences Git avant de créer un commit.'
    }

    return New-UckkGitActionResult `
        -Success $true `
        -Status $status `
        -Action 'Vérifier Git' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary $summary `
        -Warnings $(if ($changedPaths.Count -gt 0) { @('Des fichiers sont modifiés, ajoutés ou supprimés.') } else { @() }) `
        -NextStep $nextStep `
        -Data @{
            repoRoot     = $resolvedRepo
            branch       = $branch
            rawStatus    = $statusResult.stdout
            changedPaths = @($changedPaths)
        }
}

function Get-UckkGitDiffSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = '',

        [Parameter(Mandatory = $false)]
        [switch] $Staged
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot
    $repoCheck = Test-UckkGitRepository -Config $Config -RepoRoot $resolvedRepo

    if (-not $repoCheck.success) {
        return $repoCheck
    }

    $args = if ($Staged) {
        @('diff', '--cached', '--stat')
    } else {
        @('diff', '--stat')
    }

    $diffResult = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments $args

    if (-not $diffResult.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Afficher résumé des différences Git' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'La lecture du résumé des différences Git a échoué.' `
            -Errors @($diffResult.stderr.Trim()) `
            -NextStep 'Vérifier le dépôt Git.' `
            -Data @{
                repoRoot = $resolvedRepo
                command  = $diffResult
            }
    }

    $summaryText = $diffResult.stdout.Trim()

    if ([string]::IsNullOrWhiteSpace($summaryText)) {
        $summaryText = 'Aucune différence à afficher.'
    }

    return New-UckkGitActionResult `
        -Success $true `
        -Status 'Réussi' `
        -Action 'Afficher résumé des différences Git' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary $summaryText `
        -NextStep 'Lire les différences Git complètes si nécessaire.' `
        -Data @{
            repoRoot = $resolvedRepo
            staged   = [bool]$Staged
            diffStat = $summaryText
        }
}

function Get-UckkGitDiff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = '',

        [Parameter(Mandatory = $false)]
        [switch] $Staged,

        [Parameter(Mandatory = $false)]
        [int] $MaxCharacters = 120000
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot
    $repoCheck = Test-UckkGitRepository -Config $Config -RepoRoot $resolvedRepo

    if (-not $repoCheck.success) {
        return $repoCheck
    }

    $args = if ($Staged) {
        @('diff', '--cached')
    } else {
        @('diff')
    }

    $diffResult = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments $args

    if (-not $diffResult.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Afficher les différences Git' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'La lecture des différences Git a échoué.' `
            -Errors @($diffResult.stderr.Trim()) `
            -NextStep 'Vérifier le dépôt Git.' `
            -Data @{
                repoRoot = $resolvedRepo
                command  = $diffResult
            }
    }

    $diffText = $diffResult.stdout

    $warnings = @()
    if ($diffText.Length -gt $MaxCharacters) {
        $warnings += "Le diff est très long. Il a été tronqué à $MaxCharacters caractères pour l interface."
        $diffText = $diffText.Substring(0, $MaxCharacters)
    }

    if ([string]::IsNullOrWhiteSpace($diffText)) {
        $diffText = 'Aucune différence à afficher.'
    }

    return New-UckkGitActionResult `
        -Success $true `
        -Status $(if ($warnings.Count -gt 0) { 'Réussi avec avertissements' } else { 'Réussi' }) `
        -Action 'Afficher les différences Git' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'Différences Git lues.' `
        -Warnings $warnings `
        -NextStep 'Vérifier qu aucun secret n est inclus avant commit ou push.' `
        -Data @{
            repoRoot = $resolvedRepo
            staged   = [bool]$Staged
            diff     = $diffText
        }
}

function Test-UckkGitSensitiveFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = ''
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot
    $statusResult = Get-UckkGitStatus -Config $Config -RepoRoot $resolvedRepo

    if (-not $statusResult.success) {
        return $statusResult
    }

    $changedPaths = @($statusResult.data.changedPaths)

    $sensitivePathPatterns = @(
        '(?i)(^|[\\/])config\.php$',
        '(?i)(^|[\\/])\.env$',
        '(?i)(^|[\\/])id_rsa$',
        '(?i)(^|[\\/])id_dsa$',
        '(?i)(^|[\\/])id_ed25519$',
        '(?i)\.pem$',
        '(?i)\.key$',
        '(?i)\.pfx$',
        '(?i)\.p12$',
        '(?i)\.sql$',
        '(?i)\.sqlite$',
        '(?i)\.db$',
        '(?i)dump',
        '(?i)backup',
        '(?i)secret',
        '(?i)password',
        '(?i)token'
    )

    $sensitivePaths = @()

    foreach ($path in $changedPaths) {
        foreach ($pattern in $sensitivePathPatterns) {
            if ($path -match $pattern) {
                $sensitivePaths += $path
                break
            }
        }
    }

    $unstagedDiff = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('diff') -TimeoutSeconds 120
    $stagedDiff = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('diff', '--cached') -TimeoutSeconds 120

    $combinedDiff = @(
        $unstagedDiff.stdout
        $stagedDiff.stdout
    ) -join "`n"

    $sensitiveContentPatterns = @(
        '(?i)password\s*[:=]',
        '(?i)passwd\s*[:=]',
        '(?i)token\s*[:=]',
        '(?i)api[_-]?key\s*[:=]',
        '(?i)secret\s*[:=]',
        '(?i)private[_-]?key',
        '-----BEGIN .*PRIVATE KEY-----'
)

    $sensitiveContentWarnings = @()

    foreach ($pattern in $sensitiveContentPatterns) {
        if ($combinedDiff -match $pattern) {
            $sensitiveContentWarnings += "Le diff contient une chaîne qui ressemble à un secret : $pattern"
        }
    }

    $errors = @()
    $warnings = @()

    if ($sensitivePaths.Count -gt 0) {
        $errors += 'Des fichiers sensibles semblent inclus dans les changements Git.'
    }

    if ($sensitiveContentWarnings.Count -gt 0) {
        $errors += 'Le contenu des différences Git semble contenir des secrets.'
        $warnings += $sensitiveContentWarnings
    }

    if ($errors.Count -gt 0) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Vérifier les fichiers sensibles' `
            -DangerLevel 1 `
            -Mode 'vérification' `
            -Summary 'Des fichiers ou contenus sensibles semblent présents.' `
            -Warnings $warnings `
            -Errors $errors `
            -NextStep 'Lire les différences Git et retirer les secrets avant commit ou push.' `
            -Data @{
                repoRoot                  = $resolvedRepo
                sensitivePaths            = @($sensitivePaths | Select-Object -Unique)
                sensitiveContentWarnings  = @($sensitiveContentWarnings | Select-Object -Unique)
                changedPaths              = @($changedPaths)
            }
    }

    return New-UckkGitActionResult `
        -Success $true `
        -Status 'Réussi' `
        -Action 'Vérifier les fichiers sensibles' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary 'Aucun fichier sensible évident détecté.' `
        -Warnings @('Cette vérification ne remplace pas une lecture humaine des différences Git.') `
        -NextStep 'Lire les différences Git avant de créer un commit.' `
        -Data @{
            repoRoot     = $resolvedRepo
            changedPaths = @($changedPaths)
        }
}

function New-UckkGitCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = '',

        [Parameter(Mandatory = $false)]
        [switch] $AddAll
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Créer un commit Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'Le message de commit est vide.' `
            -Errors @('Un commit Git doit avoir un message clair.') `
            -NextStep 'Écrire un message de commit, puis relancer.'
    }

    $sensitiveCheck = Test-UckkGitSensitiveFiles -Config $Config -RepoRoot $resolvedRepo

    if (-not $sensitiveCheck.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Créer un commit Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'Commit refusé : des fichiers ou contenus sensibles semblent présents.' `
            -Warnings $sensitiveCheck.warnings `
            -Errors $sensitiveCheck.errors `
            -NextStep 'Retirer les fichiers ou contenus sensibles, puis relancer la vérification Git.' `
            -Data $sensitiveCheck.data
    }

    if ($AddAll) {
        $addResult = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('add', '-A')

        if (-not $addResult.success) {
            return New-UckkGitActionResult `
                -Success $false `
                -Status 'Échoué' `
                -Action 'Créer un commit Git' `
                -DangerLevel 3 `
                -Mode 'application' `
                -Summary 'Git add a échoué.' `
                -Errors @($addResult.stderr.Trim()) `
                -NextStep 'Lire le rapport, corriger l erreur Git, puis relancer.' `
                -Data @{
                    repoRoot = $resolvedRepo
                    command  = $addResult
                }
        }
    }

    $stagedCheck = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('diff', '--cached', '--name-only')

    if (-not $stagedCheck.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Créer un commit Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'Impossible de vérifier les fichiers préparés pour commit.' `
            -Errors @($stagedCheck.stderr.Trim()) `
            -NextStep 'Vérifier Git manuellement.'
    }

    $stagedFiles = ConvertTo-UckkGitLines -Text $stagedCheck.stdout

    if ($stagedFiles.Count -eq 0) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Créer un commit Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'Commit refusé : aucun fichier n est préparé pour commit.' `
            -Errors @('Aucun fichier staged.') `
            -NextStep 'Préparer des fichiers avec Git ou relancer avec l option AddAll si c est voulu.' `
            -Data @{
                repoRoot = $resolvedRepo
            }
    }

    $commitResult = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('commit', '-m', $Message)

    if (-not $commitResult.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Créer un commit Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'La création du commit Git a échoué.' `
            -Errors @($commitResult.stderr.Trim()) `
            -NextStep 'Lire le détail Git, corriger le problème, puis relancer.' `
            -Data @{
                repoRoot    = $resolvedRepo
                stagedFiles = @($stagedFiles)
                command     = $commitResult
            }
    }

    $branch = Get-UckkGitCurrentBranch -RepoRoot $resolvedRepo

    return New-UckkGitActionResult `
        -Success $true `
        -Status 'Réussi' `
        -Action 'Créer un commit Git' `
        -DangerLevel 3 `
        -Mode 'application' `
        -Summary 'Commit Git créé.' `
        -Warnings @('Vérifie le rapport avant d envoyer les changements vers Git.') `
        -NextStep 'Envoyer les changements vers Git si le commit est correct.' `
        -Data @{
            repoRoot    = $resolvedRepo
            branch      = $branch
            stagedFiles = @($stagedFiles)
            output      = $commitResult.stdout.Trim()
        }
}

function Push-UckkGitChanges {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = '',

        [Parameter(Mandatory = $false)]
        [string] $RemoteName = '',

        [Parameter(Mandatory = $false)]
        [string] $Branch = ''
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot

    if ([string]::IsNullOrWhiteSpace($RemoteName)) {
        $RemoteName = Get-UckkGitRemoteName -Config $Config
    }

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        $Branch = Get-UckkGitCurrentBranch -RepoRoot $resolvedRepo
    }

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Envoyer les changements vers Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'La branche Git actuelle est inconnue.' `
            -Errors @('Impossible de déterminer la branche actuelle.') `
            -NextStep 'Vérifier Git avant de pousser.'
    }

    $sensitiveCheck = Test-UckkGitSensitiveFiles -Config $Config -RepoRoot $resolvedRepo

    if (-not $sensitiveCheck.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Envoyer les changements vers Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'Push refusé : des fichiers ou contenus sensibles semblent présents.' `
            -Warnings $sensitiveCheck.warnings `
            -Errors $sensitiveCheck.errors `
            -NextStep 'Retirer les secrets, puis relancer "Vérifier les fichiers sensibles".' `
            -Data $sensitiveCheck.data
    }

    $pushResult = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('push', $RemoteName, $Branch) -TimeoutSeconds 300

    if (-not $pushResult.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Envoyer les changements vers Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'L envoi des changements vers Git a échoué.' `
            -Errors @($pushResult.stderr.Trim()) `
            -NextStep 'Lire le détail Git, corriger le problème, puis relancer.' `
            -Data @{
                repoRoot = $resolvedRepo
                remote   = $RemoteName
                branch   = $Branch
                command  = $pushResult
            }
    }

    return New-UckkGitActionResult `
        -Success $true `
        -Status 'Réussi' `
        -Action 'Envoyer les changements vers Git' `
        -DangerLevel 3 `
        -Mode 'application' `
        -Summary 'Les changements ont été envoyés vers Git.' `
        -NextStep 'Publier sur serveur si les changements doivent aller sur uckk.org.' `
        -Data @{
            repoRoot = $resolvedRepo
            remote   = $RemoteName
            branch   = $Branch
            output   = $pushResult.stdout.Trim()
        }
}

function Pull-UckkGitChanges {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = '',

        [Parameter(Mandatory = $false)]
        [string] $RemoteName = '',

        [Parameter(Mandatory = $false)]
        [string] $Branch = ''
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot

    if ([string]::IsNullOrWhiteSpace($RemoteName)) {
        $RemoteName = Get-UckkGitRemoteName -Config $Config
    }

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        $Branch = Get-UckkGitCurrentBranch -RepoRoot $resolvedRepo
    }

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Récupérer les changements depuis Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'La branche Git actuelle est inconnue.' `
            -Errors @('Impossible de déterminer la branche actuelle.') `
            -NextStep 'Vérifier Git avant de récupérer les changements.'
    }

    $status = Get-UckkGitStatus -Config $Config -RepoRoot $resolvedRepo

    if (-not $status.success) {
        return $status
    }

    if ($status.data.changedPaths.Count -gt 0) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Récupérer les changements depuis Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'Pull refusé : le dépôt contient des changements locaux.' `
            -Errors @('Des changements locaux existent.') `
            -NextStep 'Committer, sauvegarder ou annuler les changements locaux avant pull.' `
            -Data $status.data
    }

    $pullResult = Invoke-UckkGitCommandInternal -RepoRoot $resolvedRepo -Arguments @('pull', '--ff-only', $RemoteName, $Branch) -TimeoutSeconds 300

    if (-not $pullResult.success) {
        return New-UckkGitActionResult `
            -Success $false `
            -Status 'Échoué' `
            -Action 'Récupérer les changements depuis Git' `
            -DangerLevel 3 `
            -Mode 'application' `
            -Summary 'La récupération depuis Git a échoué.' `
            -Errors @($pullResult.stderr.Trim()) `
            -NextStep 'Lire le détail Git, corriger le problème, puis relancer.' `
-Data @{
                repoRoot = $resolvedRepo
                remote   = $RemoteName
                branch   = $Branch
                command  = $pullResult
            }
    }

    return New-UckkGitActionResult `
        -Success $true `
        -Status 'Réussi' `
        -Action 'Récupérer les changements depuis Git' `
        -DangerLevel 3 `
        -Mode 'application' `
        -Summary 'Les changements ont été récupérés depuis Git.' `
        -NextStep 'Synchroniser source vers Moodle local si nécessaire.' `
        -Data @{
            repoRoot = $resolvedRepo
            remote   = $RemoteName
            branch   = $Branch
            output   = $pullResult.stdout.Trim()
        }
}

function Invoke-UckkGitCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [string] $RepoRoot = ''
    )

    $resolvedRepo = Resolve-UckkGitRepositoryRoot -Config $Config -RepoRoot $RepoRoot

    $availability = Test-UckkGitAvailable
    if (-not $availability.success) {
        return $availability
    }

    $repository = Test-UckkGitRepository -Config $Config -RepoRoot $resolvedRepo
    if (-not $repository.success) {
        return $repository
    }

    $status = Get-UckkGitStatus -Config $Config -RepoRoot $resolvedRepo
    if (-not $status.success) {
        return $status
    }

    $sensitive = Test-UckkGitSensitiveFiles -Config $Config -RepoRoot $resolvedRepo

    $warnings = @()
    $errors = @()

    if ($status.warnings.Count -gt 0) {
        $warnings += $status.warnings
    }

    if ($sensitive.warnings.Count -gt 0) {
        $warnings += $sensitive.warnings
    }

    if (-not $sensitive.success) {
        $errors += $sensitive.errors
    }

    $finalSuccess = ($errors.Count -eq 0)
    $finalStatus = if (-not $finalSuccess) {
        'Échoué'
    } elseif ($warnings.Count -gt 0) {
        'Réussi avec avertissements'
    } else {
        'Réussi'
    }

    $summary = if (-not $finalSuccess) {
        'La vérification Git a détecté un risque bloquant.'
    } elseif ($status.data.changedPaths.Count -gt 0) {
        "Git est disponible, mais $($status.data.changedPaths.Count) changement(s) sont présents."
    } else {
        'Git est disponible et ne signale aucun changement.'
    }

    $nextStep = if (-not $finalSuccess) {
        'Lire les différences Git et retirer les fichiers ou contenus sensibles.'
    } elseif ($status.data.changedPaths.Count -gt 0) {
        'Lire les différences Git avant de créer un commit.'
    } else {
        'Aucune action requise.'
    }

    return New-UckkGitActionResult `
        -Success $finalSuccess `
        -Status $finalStatus `
        -Action 'Vérifier Git' `
        -DangerLevel 1 `
        -Mode 'vérification' `
        -Summary $summary `
        -Warnings $warnings `
        -Errors $errors `
        -NextStep $nextStep `
        -Data @{
            repoRoot       = $resolvedRepo
            availability   = $availability.data
            repository     = $repository.data
            status         = $status.data
            sensitiveCheck = $sensitive.data
        }
}

Export-ModuleMember -Function @(
    'Resolve-UckkGitRepositoryRoot',
    'Test-UckkGitAvailable',
    'Test-UckkGitRepository',
    'Get-UckkGitStatus',
    'Get-UckkGitDiffSummary',
    'Get-UckkGitDiff',
    'Test-UckkGitSensitiveFiles',
    'New-UckkGitCommit',
    'Push-UckkGitChanges',
    'Pull-UckkGitChanges',
    'Invoke-UckkGitCheck'
)

