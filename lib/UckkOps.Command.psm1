#Requires -Version 7.0
<#
.SYNOPSIS
  Common command execution helpers for UCKK Ops Console.

.DESCRIPTION
  This module executes local commands and SSH commands safely.

  Rules:
  - commands must be executed through this module;
  - arguments must be passed as arrays, not unsafe string concatenation;
  - stdout/stderr are captured;
  - timeout is enforced;
  - secrets are masked before returning/logging;
  - every command returns a structured result.

.NOTES
  This module does not decide business logic.
  It only runs commands and reports what happened.
#>

Set-StrictMode -Off
function Get-UckkCommandTimestamp {
    return (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

function Get-UckkCommandFileTimestamp {
    return (Get-Date).ToString('yyyyMMdd_HHmmss')
}

function ConvertTo-UckkCommandSafeText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Text,

        [switch]$NoSecretMasking
    )

    if ($null -eq $Text) {
        return ''
    }

    if ($NoSecretMasking) {
        return $Text
    }

    $maskCommand = Get-Command -Name 'Mask-UckkSecrets' -ErrorAction SilentlyContinue

    if ($null -ne $maskCommand) {
        try {
            return (& $maskCommand -Text $Text)
        }
        catch {
            # Fall back to local masking below.
        }
    }

    $safe = $Text

    $patterns = @(
        '(?i)(password\s*[:=]\s*)([^\s;]+)',
        '(?i)(passwd\s*[:=]\s*)([^\s;]+)',
        '(?i)(token\s*[:=]\s*)([^\s;]+)',
        '(?i)(secret\s*[:=]\s*)([^\s;]+)',
        '(?i)(api[_-]?key\s*[:=]\s*)([^\s;]+)',
        '(?i)(private[_-]?key\s*[:=]\s*)([^\r\n]+)',
        '(?i)(cookie\s*[:=]\s*)([^\r\n]+)',
        '(?i)(session\s*[:=]\s*)([^\r\n]+)'
    )

    foreach ($pattern in $patterns) {
        $safe = [regex]::Replace($safe, $pattern, '$1[masqué]')
    }

    return $safe
}

function Join-UckkCommandForDisplay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string[]]$ArgumentList = @(),

        [switch]$NoSecretMasking
    )

    $parts = New-Object System.Collections.Generic.List[string]

    if ($FilePath -match '\s') {
        [void]$parts.Add(('"{0}"' -f $FilePath))
    }
    else {
        [void]$parts.Add($FilePath)
    }

    foreach ($arg in @($ArgumentList)) {
        if ($null -eq $arg) {
            continue
        }

        $text = [string]$arg

        if ($text -match '[\s"]') {
            $escaped = $text.Replace('"', '\"')
            [void]$parts.Add(('"{0}"' -f $escaped))
        }
        else {
            [void]$parts.Add($text)
        }
    }

    $display = $parts -join ' '

    return ConvertTo-UckkCommandSafeText -Text $display -NoSecretMasking:$NoSecretMasking
}

function New-UckkCommandResult {
    [CmdletBinding()]
    param(
        [bool]$Success,
        [string]$Status,
        [string]$FilePath,
        [string[]]$ArgumentList = @(),
        [string]$WorkingDirectory = '',
        [int]$TimeoutSeconds = 300,
        [Nullable[int]]$ExitCode = $null,
        [string]$Stdout = '',
        [string]$Stderr = '',
        [string]$ErrorMessage = '',
        [string]$StartedAt = '',
        [string]$EndedAt = '',
        [Nullable[int]]$DurationMs = $null,
        [string]$LogPath = '',
        [switch]$NoSecretMasking
    )

    $safeStdout = ConvertTo-UckkCommandSafeText -Text $Stdout -NoSecretMasking:$NoSecretMasking
    $safeStderr = ConvertTo-UckkCommandSafeText -Text $Stderr -NoSecretMasking:$NoSecretMasking
    $safeError = ConvertTo-UckkCommandSafeText -Text $ErrorMessage -NoSecretMasking:$NoSecretMasking

    return [pscustomobject]@{
        success          = $Success
        status           = $Status
        filePath         = $FilePath
        argumentList     = @($ArgumentList)
        displayCommand   = Join-UckkCommandForDisplay -FilePath $FilePath -ArgumentList $ArgumentList -NoSecretMasking:$NoSecretMasking
        workingDirectory = $WorkingDirectory
        timeoutSeconds   = $TimeoutSeconds
        exitCode         = $ExitCode
        stdout           = $safeStdout
        stderr           = $safeStderr
        errorMessage     = $safeError
        startedAt        = $StartedAt
        endedAt          = $EndedAt
        durationMs       = $DurationMs
        logPath          = $LogPath
    }
}

function Write-UckkCommandExecutionLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CommandResult,

        [string]$LogPath
    )

    if ([string]::IsNullOrWhiteSpace($LogPath)) {
        return
    }

    $parent = Split-Path -Parent $LogPath

    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }

    $content = @"
# UCKK command log

Started at:
$($CommandResult.startedAt)

Ended at:
$($CommandResult.endedAt)

Status:
$($CommandResult.status)

Success:
$($CommandResult.success)

Working directory:
$($CommandResult.workingDirectory)

Command:
$($CommandResult.displayCommand)

Timeout seconds:
$($CommandResult.timeoutSeconds)

Exit code:
$($CommandResult.exitCode)

Error message:
$($CommandResult.errorMessage)

STDOUT:
$($CommandResult.stdout)

STDERR:
$($CommandResult.stderr)
"@

    $tmpPath = "$LogPath.tmp"

    Set-Content -LiteralPath $tmpPath -Value $content -Encoding UTF8
    Move-Item -LiteralPath $tmpPath -Destination $LogPath -Force
}

function Test-UckkCommandAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    if ([System.IO.Path]::IsPathRooted($FilePath)) {
        return (Test-Path -LiteralPath $FilePath -PathType Leaf)
    }

    $command = Get-Command -Name $FilePath -ErrorAction SilentlyContinue
    return ($null -ne $command)
}

function Invoke-UckkCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string[]]$ArgumentList = @(),

        [string]$WorkingDirectory = '',

        [int]$TimeoutSeconds = 300,

        [hashtable]$Environment = @{},

        [string]$InputText = '',

        [string]$LogPath = '',

        [switch]$AllowNonZeroExitCode,

        [switch]$NoSecretMasking
    )

    $startedAt = Get-UckkCommandTimestamp
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    if ([string]::IsNullOrWhiteSpace($FilePath)) {
        $result = New-UckkCommandResult `
            -Success $false `
            -Status 'Échoué' `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -WorkingDirectory $WorkingDirectory `
            -TimeoutSeconds $TimeoutSeconds `
            -ErrorMessage 'Commande absente.' `
            -StartedAt $startedAt `
            -EndedAt (Get-UckkCommandTimestamp) `
            -DurationMs 0 `
            -LogPath $LogPath `
            -NoSecretMasking:$NoSecretMasking

        Write-UckkCommandExecutionLog -CommandResult $result -LogPath $LogPath
        return $result
    }

    if (-not (Test-UckkCommandAvailable -FilePath $FilePath)) {
        $result = New-UckkCommandResult `
            -Success $false `
            -Status 'Échoué' `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -WorkingDirectory $WorkingDirectory `
            -TimeoutSeconds $TimeoutSeconds `
            -ErrorMessage "Commande introuvable : $FilePath" `
            -StartedAt $startedAt `
            -EndedAt (Get-UckkCommandTimestamp) `
            -DurationMs 0 `
            -LogPath $LogPath `
            -NoSecretMasking:$NoSecretMasking

        Write-UckkCommandExecutionLog -CommandResult $result -LogPath $LogPath
        return $result
    }

    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) {
            $result = New-UckkCommandResult `
                -Success $false `
                -Status 'Échoué' `
                -FilePath $FilePath `
                -ArgumentList $ArgumentList `
                -WorkingDirectory $WorkingDirectory `
                -TimeoutSeconds $TimeoutSeconds `
                -ErrorMessage "Dossier de travail introuvable : $WorkingDirectory" `
                -StartedAt $startedAt `
                -EndedAt (Get-UckkCommandTimestamp) `
                -DurationMs 0 `
                -LogPath $LogPath `
                -NoSecretMasking:$NoSecretMasking

            Write-UckkCommandExecutionLog -CommandResult $result -LogPath $LogPath
            return $result
        }
    }

    if ($TimeoutSeconds -le 0) {
        $TimeoutSeconds = 300
    }

    $process = $null

    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $FilePath
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.RedirectStandardInput = (-not [string]::IsNullOrEmpty($InputText))

        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
            $psi.WorkingDirectory = $WorkingDirectory
        }

        try {
            $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
            $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        }
        catch {
            # Encoding properties may not be available in all hosts.
}

        foreach ($arg in @($ArgumentList)) {
            if ($null -ne $arg) {
                [void]$psi.ArgumentList.Add([string]$arg)
            }
        }

        foreach ($key in @($Environment.Keys)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$key)) {
                $psi.Environment[[string]$key] = [string]$Environment[$key]
            }
        }

        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $psi

        [void]$process.Start()

        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()

        if (-not [string]::IsNullOrEmpty($InputText)) {
            $process.StandardInput.Write($InputText)
            $process.StandardInput.Close()
        }

        $exited = $process.WaitForExit($TimeoutSeconds * 1000)

        if (-not $exited) {
            try {
                $process.Kill($true)
            }
            catch {
                try {
                    $process.Kill()
                }
                catch {
                    # Ignore kill failure. We still return a timeout result.
                }
            }

            $stopwatch.Stop()

            $result = New-UckkCommandResult `
                -Success $false `
                -Status 'Échoué' `
                -FilePath $FilePath `
                -ArgumentList $ArgumentList `
                -WorkingDirectory $WorkingDirectory `
                -TimeoutSeconds $TimeoutSeconds `
                -ExitCode $null `
                -Stdout '' `
                -Stderr '' `
                -ErrorMessage "La commande a dépassé le timeout de $TimeoutSeconds secondes." `
                -StartedAt $startedAt `
                -EndedAt (Get-UckkCommandTimestamp) `
                -DurationMs ([int]$stopwatch.ElapsedMilliseconds) `
                -LogPath $LogPath `
                -NoSecretMasking:$NoSecretMasking

            Write-UckkCommandExecutionLog -CommandResult $result -LogPath $LogPath
            return $result
        }

        $process.WaitForExit()

        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $exitCode = $process.ExitCode

        $stopwatch.Stop()

        $success = ($exitCode -eq 0 -or $AllowNonZeroExitCode)
        $status = if ($success) { 'Réussi' } else { 'Échoué' }
        $errorMessage = ''

        if (-not $success) {
            $errorMessage = "La commande a échoué avec le code de retour $exitCode."
        }

        $result = New-UckkCommandResult `
            -Success $success `
            -Status $status `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -WorkingDirectory $WorkingDirectory `
            -TimeoutSeconds $TimeoutSeconds `
            -ExitCode $exitCode `
            -Stdout $stdout `
            -Stderr $stderr `
            -ErrorMessage $errorMessage `
            -StartedAt $startedAt `
            -EndedAt (Get-UckkCommandTimestamp) `
            -DurationMs ([int]$stopwatch.ElapsedMilliseconds) `
            -LogPath $LogPath `
            -NoSecretMasking:$NoSecretMasking

        Write-UckkCommandExecutionLog -CommandResult $result -LogPath $LogPath
        return $result
    }
    catch {
        $stopwatch.Stop()

        $result = New-UckkCommandResult `
            -Success $false `
            -Status 'Échoué' `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -WorkingDirectory $WorkingDirectory `
            -TimeoutSeconds $TimeoutSeconds `
            -ExitCode $null `
            -Stdout '' `
            -Stderr '' `
            -ErrorMessage $_.Exception.Message `
            -StartedAt $startedAt `
            -EndedAt (Get-UckkCommandTimestamp) `
            -DurationMs ([int]$stopwatch.ElapsedMilliseconds) `
            -LogPath $LogPath `
            -NoSecretMasking:$NoSecretMasking

        Write-UckkCommandExecutionLog -CommandResult $result -LogPath $LogPath
        return $result
    }
    finally {
        if ($null -ne $process) {
            $process.Dispose()
        }
    }
}

function Get-UckkCommandConfigValue {
    [CmdletBinding()]
    param(
        [object]$Config,

        [Parameter(Mandatory)]
        [string]$Path,

        [object]$Default = $null
    )

    if ($null -eq $Config) {
        return $Default
    }

    $current = $Config

    foreach ($part in $Path -split '\.') {
        if ($null -eq $current) {
            return $Default
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

function Invoke-UckkSshCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RemoteCommand,

        [object]$Config = $null,

        [string]$SshTarget = '',

        [int]$SshPort = 0,

        [int]$ConnectTimeoutSeconds = 20,

        [int]$TimeoutSeconds = 300,

        [string]$WorkingDirectory = '',

        [string]$LogPath = '',

        [switch]$AllowNonZeroExitCode,

        [switch]$NoSecretMasking
    )

    if ([string]::IsNullOrWhiteSpace($SshTarget)) {
        $SshTarget = [string](Get-UckkCommandConfigValue -Config $Config -Path 'server.sshTarget' -Default '')
    }

    if ([string]::IsNullOrWhiteSpace($SshTarget)) {
        $user = [string](Get-UckkCommandConfigValue -Config $Config -Path 'server.sshUser' -Default '')
        $hostName = [string](Get-UckkCommandConfigValue -Config $Config -Path 'server.sshHost' -Default '')

        if (-not [string]::IsNullOrWhiteSpace($user) -and -not [string]::IsNullOrWhiteSpace($hostName)) {
            $SshTarget = "$user@$hostName"
        }
    }

    if ($SshPort -le 0) {
        $SshPort = [int](Get-UckkCommandConfigValue -Config $Config -Path 'server.sshPort' -Default 22)
    }

    if ($ConnectTimeoutSeconds -le 0) {
        $ConnectTimeoutSeconds = [int](Get-UckkCommandConfigValue -Config $Config -Path 'server.connectTimeoutSeconds' -Default 20)
    }

    if ($TimeoutSeconds -le 0) {
        $TimeoutSeconds = [int](Get-UckkCommandConfigValue -Config $Config -Path 'server.commandTimeoutSeconds' -Default 300)
    }

    if ([string]::IsNullOrWhiteSpace($SshTarget)) {
        return New-UckkCommandResult `
            -Success $false `
            -Status 'Échoué' `
            -FilePath 'ssh' `
            -ArgumentList @() `
            -WorkingDirectory $WorkingDirectory `
            -TimeoutSeconds $TimeoutSeconds `
            -ErrorMessage 'Cible SSH absente. Vérifier server.sshTarget ou server.sshUser/server.sshHost.' `
            -StartedAt (Get-UckkCommandTimestamp) `
            -EndedAt (Get-UckkCommandTimestamp) `
            -DurationMs 0 `
            -LogPath $LogPath `
            -NoSecretMasking:$NoSecretMasking
    }

    if ([string]::IsNullOrWhiteSpace($RemoteCommand)) {
        return New-UckkCommandResult `
            -Success $false `
            -Status 'Échoué' `
            -FilePath 'ssh' `
            -ArgumentList @($SshTarget) `
            -WorkingDirectory $WorkingDirectory `
            -TimeoutSeconds $TimeoutSeconds `
            -ErrorMessage 'Commande distante absente.' `
            -StartedAt (Get-UckkCommandTimestamp) `
            -EndedAt (Get-UckkCommandTimestamp) `
            -DurationMs 0 `
            -LogPath $LogPath `
            -NoSecretMasking:$NoSecretMasking
    }

    $args = @(
        '-p', [string]$SshPort,
        '-o', 'BatchMode=yes',
        '-o', "ConnectTimeout=$ConnectTimeoutSeconds",
        $SshTarget,
        $RemoteCommand
    )

    return Invoke-UckkCommand `
        -FilePath 'ssh' `
        -ArgumentList $args `
        -WorkingDirectory $WorkingDirectory `
        -TimeoutSeconds $TimeoutSeconds `
        -LogPath $LogPath `
        -AllowNonZeroExitCode:$AllowNonZeroExitCode `
        -NoSecretMasking:$NoSecretMasking
}

function Invoke-UckkSshScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$RemoteLines,

        [object]$Config = $null,

        [string]$SshTarget = '',

        [int]$SshPort = 0,

        [int]$ConnectTimeoutSeconds = 20,

        [int]$TimeoutSeconds = 300,

        [string]$WorkingDirectory = '',

        [string]$LogPath = '',

        [switch]$AllowNonZeroExitCode,

        [switch]$NoSecretMasking
    )

    $safeLines = @($RemoteLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ($safeLines.Count -eq 0) {
        return New-UckkCommandResult `
            -Success $false `
            -Status 'Échoué' `
            -FilePath 'ssh' `
            -ArgumentList @() `
            -WorkingDirectory $WorkingDirectory `
            -TimeoutSeconds $TimeoutSeconds `
            -ErrorMessage 'Script distant vide.' `
            -StartedAt (Get-UckkCommandTimestamp) `
            -EndedAt (Get-UckkCommandTimestamp) `
            -DurationMs 0 `
            -LogPath $LogPath `
            -NoSecretMasking:$NoSecretMasking
    }

    $remoteCommand = $safeLines -join " && "

    return Invoke-UckkSshCommand `
        -RemoteCommand $remoteCommand `
        -Config $Config `
        -SshTarget $SshTarget `
        -SshPort $SshPort `
        -ConnectTimeoutSeconds $ConnectTimeoutSeconds `
        -TimeoutSeconds $TimeoutSeconds `
        -WorkingDirectory $WorkingDirectory `
        -LogPath $LogPath `
        -AllowNonZeroExitCode:$AllowNonZeroExitCode `
        -NoSecretMasking:$NoSecretMasking
}

function ConvertTo-UckkCommandActionSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CommandResult,

        [string]$SuccessSummary = 'La commande a réussi.',

        [string]$FailureSummary = 'La commande a échoué.'
    )

    if ($CommandResult.success) {
        return $SuccessSummary
    }

    if (-not [string]::IsNullOrWhiteSpace($CommandResult.errorMessage)) {
        return "$FailureSummary $($CommandResult.errorMessage)"
    }

    if (-not [string]::IsNullOrWhiteSpace($CommandResult.stderr)) {
        $firstLine = ($CommandResult.stderr -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)
        if (-not [string]::IsNullOrWhiteSpace($firstLine)) {
            return "$FailureSummary $firstLine"
}
    }

    return $FailureSummary
}

Export-ModuleMember -Function @(
    'Invoke-UckkCommand',
    'Invoke-UckkSshCommand',
    'Invoke-UckkSshScript',
    'Test-UckkCommandAvailable',
    'Join-UckkCommandForDisplay',
    'ConvertTo-UckkCommandSafeText',
    'ConvertTo-UckkCommandActionSummary'
)

