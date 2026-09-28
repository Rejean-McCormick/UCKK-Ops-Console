#Requires -Version 7.0
Set-StrictMode -Off
function Get-UckkOpsRoot {
    [CmdletBinding()]
    param()

    $libDir = $PSScriptRoot

    if ([string]::IsNullOrWhiteSpace($libDir)) {
        return (Get-Location).Path
    }

    return (Split-Path -Path $libDir -Parent)
}

function Get-UckkDefaultConfigPath {
    [CmdletBinding()]
    param()

    return (Join-Path -Path (Get-UckkOpsRoot) -ChildPath "config/uckk-ops-console.config.json")
}

function Resolve-UckkConfigPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Path = ""
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return Get-UckkDefaultConfigPath
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-UckkOpsRoot) $Path))
}

function Resolve-UckkPathFromAppRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($Path)

    if ([System.IO.Path]::IsPathRooted($expanded)) {
        return [System.IO.Path]::GetFullPath($expanded)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-UckkOpsRoot) $expanded))
}

function New-UckkConfigIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("error", "warning", "info")]
        [string] $Level,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [string] $NextStep = ""
    )

    return [pscustomobject]@{
        level    = $Level
        path     = $Path
        message  = $Message
        nextStep = $NextStep
    }
}

function Get-UckkObjectMemberValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Object,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [ref] $Found
    )

    $Found.Value = $false

    if ($null -eq $Object) {
        return $null
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            $Found.Value = $true
            return $Object[$Name]
        }

        return $null
    }

    $property = $Object.PSObject.Properties[$Name]

    if ($null -ne $property) {
        $Found.Value = $true
        return $property.Value
    }

    return $null
}

function Test-UckkConfigValueExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $current = $Config

    foreach ($part in ($Path -split "\.")) {
        $found = $false
        $current = Get-UckkObjectMemberValue -Object $current -Name $part -Found ([ref] $found)

        if (-not $found) {
            return $false
        }
    }

    return $true
}

function Get-UckkConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Default = $null
    )

    $current = $Config

    foreach ($part in ($Path -split "\.")) {
        $found = $false
        $current = Get-UckkObjectMemberValue -Object $current -Name $part -Found ([ref] $found)

        if (-not $found) {
            return $Default
        }
    }

    if ($null -eq $current) {
        return $Default
    }

    return $current
}

function Test-UckkValuePresent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [string]) {
        return -not [string]::IsNullOrWhiteSpace($Value)
    }

    if ($Value -is [array]) {
        return $Value.Count -gt 0
    }

    return $true
}

function Test-UckkUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Value
    )

    if (-not (Test-UckkValuePresent -Value $Value)) {
        return $false
    }

    $uri = $null

    if (-not [System.Uri]::TryCreate([string] $Value, [System.UriKind]::Absolute, [ref] $uri)) {
        return $false
    }

    return ($uri.Scheme -in @("http", "https"))
}

function Add-UckkIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $Issues,

        [Parameter(Mandatory = $true)]
        [ValidateSet("error", "warning", "info")]
        [string] $Level,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [string] $NextStep = ""
    )

    $Issues.Add((New-UckkConfigIssue -Level $Level -Path $Path -Message $Message -NextStep $NextStep))
}

function Add-UckkMissingSectionIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $Section,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $Issues
    )

    if (-not (Test-UckkConfigValueExists -Config $Config -Path $Section)) {
        Add-UckkIssue `
            -Issues $Issues `
            -Level "error" `
            -Path $Section `
            -Message "Section de configuration manquante : $Section" `
            -NextStep "Ajouter cette section dans config/uckk-ops-console.config.json."
    }
}

function Add-UckkMissingValueIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $Issues
    )

    if (-not (Test-UckkConfigValueExists -Config $Config -Path $Path)) {
        Add-UckkIssue `
            -Issues $Issues `
            -Level "error" `
            -Path $Path `
            -Message "Valeur de configuration manquante : $Path" `
            -NextStep "Ajouter cette valeur dans config/uckk-ops-console.config.json."
        return
    }

    $value = Get-UckkConfigValue -Config $Config -Path $Path

    if (-not (Test-UckkValuePresent -Value $value)) {
        Add-UckkIssue `
            -Issues $Issues `
            -Level "error" `
            -Path $Path `
            -Message "Valeur de configuration vide : $Path" `
            -NextStep "Remplir cette valeur dans config/uckk-ops-console.config.json."
    }
}

function Add-UckkOneOfMissingValueIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string[]] $Paths,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $Issues,

        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    foreach ($path in $Paths) {
        if (Test-UckkConfigValueExists -Config $Config -Path $path) {
            $value = Get-UckkConfigValue -Config $Config -Path $path

            if (Test-UckkValuePresent -Value $value) {
                return
            }
        }
    }

    Add-UckkIssue `
        -Issues $Issues `
        -Level "error" `
        -Path ($Paths -join " ou ") `
        -Message $Message `
        -NextStep "Ajouter une des valeurs acceptees dans config/uckk-ops-console.config.json."
}

function Set-UckkNestedConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $Value
    )

    $parts = $Path -split "\."
    $current = $Config

    for ($i = 0; $i -lt ($parts.Count - 1); $i++) {
        $part = $parts[$i]

        if (-not (Test-UckkConfigValueExists -Config $current -Path $part)) {
            $current | Add-Member -MemberType NoteProperty -Name $part -Value ([pscustomobject]@{})
        }

        $found = $false
        $current = Get-UckkObjectMemberValue -Object $current -Name $part -Found ([ref] $found)
    }

    $leaf = $parts[-1]
    $existingProperty = $current.PSObject.Properties[$leaf]

    if ($null -eq $existingProperty) {
        $current | Add-Member -MemberType NoteProperty -Name $leaf -Value $Value
    }
    else {
        $existingProperty.Value = $Value
    }
}

function Protect-UckkConfigSafetyDefaults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $Issues
    )

    if (-not (Test-UckkConfigValueExists -Config $Config -Path "safety")) {
        Set-UckkNestedConfigValue -Config $Config -Path "safety.enabled" -Value $true
    }

    $safeDefaults = [ordered]@{
        "safety.requireSimulationBeforeApply" = $true
        "safety.forbidDirectTableCopy"        = $true
        "safety.forbidSqlDumpNormalWorkflow"  = $true
        "safety.confirmServerActions"         = $true
        "safety.confirmDatabaseWrites"        = $true
        "safety.confirmGitWrites"             = $true
        "safety.confirmRecoveryActions"       = $true
        "safety.requireBackupForRecovery"     = $true
    }

    foreach ($key in $safeDefaults.Keys) {
        if (-not (Test-UckkConfigValueExists -Config $Config -Path $key)) {
            Set-UckkNestedConfigValue -Config $Config -Path $key -Value $safeDefaults[$key]

            Add-UckkIssue `
                -Issues $Issues `
                -Level "warning" `
                -Path $key `
                -Message "Valeur de securite absente. Valeur sure appliquee : true." `
                -NextStep "Ajouter cette valeur dans la configuration."
        }
    }

    if (-not (Test-UckkConfigValueExists -Config $Config -Path "safety.requireBackupBeforeDangerLevel")) {
        Set-UckkNestedConfigValue -Config $Config -Path "safety.requireBackupBeforeDangerLevel" -Value 5

        Add-UckkIssue `
            -Issues $Issues `
            -Level "warning" `
            -Path "safety.requireBackupBeforeDangerLevel" `
            -Message "Seuil de sauvegarde absent. Valeur sure appliquee : 5." `
            -NextStep "Ajouter safety.requireBackupBeforeDangerLevel dans la configuration."
    }
}

function Test-UckkConfigSafetyFlags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $Issues
    )

    $mustBeTrue = @(
        "safety.requireSimulationBeforeApply",
        "safety.forbidDirectTableCopy",
        "safety.forbidSqlDumpNormalWorkflow",
        "safety.confirmServerActions",
        "safety.confirmDatabaseWrites",
        "safety.confirmGitWrites",
        "safety.confirmRecoveryActions",
        "safety.requireBackupForRecovery"
    )

    foreach ($path in $mustBeTrue) {
        $value = Get-UckkConfigValue -Config $Config -Path $path -Default $null

        if ($value -ne $true) {
            Add-UckkIssue `
                -Issues $Issues `
                -Level "error" `
                -Path $path `
                -Message "Valeur de securite dangereuse : $path doit etre true." `
                -NextStep "Mettre cette valeur a true dans la configuration."
        }
    }
}

function Test-UckkConfigForSecrets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $Issues,

        [Parameter(Mandatory = $false)]
        [string] $Prefix = "",

        [Parameter(Mandatory = $false)]
        [int] $Depth = 0
    )

    if ($null -eq $Config) {
        return
    }

    if ($Depth -gt 64) {
        Add-UckkIssue `
            -Issues $Issues `
            -Level "warning" `
            -Path $(if ([string]::IsNullOrWhiteSpace($Prefix)) { "config" } else { $Prefix }) `
            -Message "Analyse des secrets arretee : profondeur maximale atteinte." `
            -NextStep "Verifier que la configuration ne contient pas de structure recursive."

        return
    }

    # Valeurs simples : ne pas parcourir leurs proprietes PowerShell internes.
    if ($Config -is [string] -or $Config -is [ValueType]) {
        return
    }

    $secretNames = @(
        "password",
        "passwd",
        "token",
        "secret",
        "apikey",
        "api_key",
        "privatekey",
        "private_key",
        "cookie",
        "session"
    )

    if ($Config -is [System.Collections.IDictionary]) {
        foreach ($key in $Config.Keys) {
            $keyText = [string] $key

            $path = if ([string]::IsNullOrWhiteSpace($Prefix)) {
                $keyText
            }
            else {
                "$Prefix.$keyText"
            }

            $nameLower = $keyText.ToLowerInvariant()
            $value = $Config[$key]

            foreach ($secretName in $secretNames) {
                if ($nameLower -eq $secretName -or $nameLower.Contains($secretName)) {
                    # Ne signaler que les valeurs textuelles.
                    # Exemple valide : safety.maskSecretsInReports = true
                    if ($value -is [string] -and (Test-UckkValuePresent -Value $value)) {
                        Add-UckkIssue `
                            -Issues $Issues `
                            -Level "error" `
                            -Path $path `
                            -Message "Secret possible detecte dans la configuration : $path" `
                            -NextStep "Retirer le secret du fichier de configuration."
                    }
                }
            }

            Test-UckkConfigForSecrets `
                -Config $value `
                -Issues $Issues `
                -Prefix $path `
                -Depth ($Depth + 1)
        }

        return
    }

    # Tableaux/listes : parcourir les elements, jamais les proprietes internes du tableau.
    if (
        $Config -is [System.Collections.IEnumerable] -and
        $Config -isnot [string] -and
        $Config -isnot [System.Collections.IDictionary] -and
        $Config -isnot [System.Management.Automation.PSCustomObject]
    ) {
        $index = 0

        foreach ($item in $Config) {
            $itemPath = if ([string]::IsNullOrWhiteSpace($Prefix)) {
                "[$index]"
            }
            else {
                "$Prefix[$index]"
            }

            Test-UckkConfigForSecrets `
                -Config $item `
                -Issues $Issues `
                -Prefix $itemPath `
                -Depth ($Depth + 1)

            $index++
        }

        return
    }

    # ConvertFrom-Json produit des PSCustomObject.
    # Les autres objets PowerShell ne sont pas inspectes pour eviter la recursion interne.
    if ($Config -isnot [System.Management.Automation.PSCustomObject]) {
        return
    }

    foreach ($property in $Config.PSObject.Properties) {
        $path = if ([string]::IsNullOrWhiteSpace($Prefix)) {
            $property.Name
        }
        else {
            "$Prefix.$($property.Name)"
        }

        $nameLower = $property.Name.ToLowerInvariant()
        $value = $property.Value

        foreach ($secretName in $secretNames) {
            if ($nameLower -eq $secretName -or $nameLower.Contains($secretName)) {
                # Ne signaler que les valeurs textuelles.
                # Les booleens comme safety.maskSecretsInReports ne sont pas des secrets.
                if ($value -is [string] -and (Test-UckkValuePresent -Value $value)) {
                    Add-UckkIssue `
                        -Issues $Issues `
                        -Level "error" `
                        -Path $path `
                        -Message "Secret possible detecte dans la configuration : $path" `
                        -NextStep "Retirer le secret du fichier de configuration."
                }
            }
        }

        Test-UckkConfigForSecrets `
            -Config $value `
            -Issues $Issues `
            -Prefix $path `
            -Depth ($Depth + 1)
    }
}

function Test-UckkConfiguredLocalPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $ConfigPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]] $Issues,

        [Parameter(Mandatory = $false)]
        [switch] $Required
    )

    $value = Get-UckkConfigValue -Config $Config -Path $ConfigPath -Default $null

    if (-not (Test-UckkValuePresent -Value $value)) {
        if ($Required) {
            Add-UckkIssue `
                -Issues $Issues `
                -Level "error" `
                -Path $ConfigPath `
                -Message "Chemin local manquant : $ConfigPath" `
                -NextStep "Verifier la configuration."
        }

        return
    }

    $text = [string] $value

    if ($text.StartsWith("/")) {
        return
    }

    $resolved = Resolve-UckkPathFromAppRoot -Path $text

    if (-not (Test-Path -LiteralPath $resolved)) {
        $level = if ($Required) { "error" } else { "warning" }

        Add-UckkIssue `
            -Issues $Issues `
            -Level $level `
            -Path $ConfigPath `
            -Message "Chemin local introuvable : $resolved" `
            -NextStep "Verifier le chemin ou creer le dossier attendu."
    }
}

function Read-UckkConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Path = ""
    )

    $resolvedPath = Resolve-UckkConfigPath -Path $Path
    $errors = [System.Collections.Generic.List[object]]::new()

    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        Add-UckkIssue `
            -Issues $errors `
            -Level "error" `
            -Path "config" `
            -Message "Fichier de configuration introuvable : $resolvedPath" `
            -NextStep "Creer config/uckk-ops-console.config.json."

        return [pscustomobject]@{
            success    = $false
            configPath = $resolvedPath
            config     = $null
            errors     = @($errors)
        }
    }

    try {
        $raw = Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8
    }
    catch {
        Add-UckkIssue `
            -Issues $errors `
            -Level "error" `
            -Path "config" `
            -Message "Impossible de lire le fichier de configuration : $resolvedPath" `
            -NextStep "Verifier les permissions."

        return [pscustomobject]@{
            success    = $false
            configPath = $resolvedPath
            config     = $null
            errors     = @($errors)
        }
    }

    try {
        $config = $raw | ConvertFrom-Json -Depth 100
    }
    catch {
        Add-UckkIssue `
            -Issues $errors `
            -Level "error" `
            -Path "config" `
            -Message "JSON invalide dans le fichier de configuration : $resolvedPath" `
            -NextStep "Corriger le JSON."

        return [pscustomobject]@{
            success    = $false
            configPath = $resolvedPath
            config     = $null
            errors     = @($errors)
        }
    }

    return [pscustomobject]@{
        success    = $true
        configPath = $resolvedPath
        config     = $config
        errors     = @()
    }
}

function Test-UckkConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $false)]
        [switch] $CheckFileSystem
    )

    $issues = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $Config) {
        Add-UckkIssue `
            -Issues $issues `
            -Level "error" `
            -Path "config" `
            -Message "Configuration absente." `
            -NextStep "Charger la configuration avant de la valider."

        return [pscustomobject]@{
            success  = $false
            status   = "Echoue"
            issues   = @($issues)
            errors   = @($issues)
            warnings = @()
        }
    }

    $requiredSections = @(
        "app",
        "paths",
        "urls",
        "server",
        "git",
        "mediatheque",
        "safety"
    )

    foreach ($section in $requiredSections) {
        Add-UckkMissingSectionIssue -Config $Config -Section $section -Issues $issues
    }

    $requiredValues = @(
        "paths.uckkMoodleSource",
        "paths.localMoodleRoot",
        "paths.localMoodleRuntime",
        "paths.serverMoodleSource",
        "paths.serverMoodleRoot",
        "paths.serverMoodleRuntime",
        "server.sshUser",
        "server.sshHost",
        "server.sshTarget",
        "git.repoRoot",
        "mediatheque.serviceName"
    )

    foreach ($path in $requiredValues) {
        Add-UckkMissingValueIssue -Config $Config -Path $path -Issues $issues
    }

    $publicFacades = @(Get-UckkConfigValue -Config $Config -Path 'publicFacades.sites' -Default @())

    if ($publicFacades.Count -eq 0) {
        Add-UckkIssue `
            -Issues $issues `
            -Level "warning" `
            -Path "publicFacades.sites" `
            -Message "Configuration multi-façades absente : les valeurs UCKK/UCC/Math par défaut seront utilisées par le module local." `
            -NextStep "Ajouter publicFacades à la configuration pour rendre le switcher explicite et testable."
    }
    elseif ($publicFacades.Count -lt 3) {
        Add-UckkIssue `
            -Issues $issues `
            -Level "error" `
            -Path "publicFacades.sites" `
            -Message "Configuration multi-façades partielle : UCKK, UCC et Math doivent être déclarés ensemble." `
            -NextStep "Compléter publicFacades.sites avec les trois façades Moodle."
    }
    else {
        $seenFacadeIds = @{}
        $seenFacadeThemes = @{}

        foreach ($facade in $publicFacades) {
            $facadeId = [string](Get-UckkConfigValue -Config $facade -Path 'id' -Default '')
            $facadeLabel = [string](Get-UckkConfigValue -Config $facade -Path 'label' -Default '')
            $facadeTheme = [string](Get-UckkConfigValue -Config $facade -Path 'theme' -Default '')
            $facadeMarker = [string](Get-UckkConfigValue -Config $facade -Path 'expectedMarker' -Default '')

            if ([string]::IsNullOrWhiteSpace($facadeId) -or [string]::IsNullOrWhiteSpace($facadeLabel) -or [string]::IsNullOrWhiteSpace($facadeTheme)) {
                Add-UckkIssue `
                    -Issues $issues `
                    -Level "error" `
                    -Path "publicFacades.sites" `
                    -Message "Chaque façade doit définir id, label et theme." `
                    -NextStep "Compléter la définition de la façade publique."
                continue
            }

            if ($seenFacadeIds.ContainsKey($facadeId)) {
                Add-UckkIssue -Issues $issues -Level "error" -Path "publicFacades.sites" -Message "Identifiant de façade dupliqué : $facadeId" -NextStep "Utiliser un id unique par façade."
            }
            else {
                $seenFacadeIds[$facadeId] = $true
            }

            if ($seenFacadeThemes.ContainsKey($facadeTheme)) {
                Add-UckkIssue -Issues $issues -Level "error" -Path "publicFacades.sites" -Message "Thème de façade dupliqué : $facadeTheme" -NextStep "Utiliser un thème Moodle distinct par façade."
            }
            else {
                $seenFacadeThemes[$facadeTheme] = $true
            }

            if ([string]::IsNullOrWhiteSpace($facadeMarker)) {
                Add-UckkIssue -Issues $issues -Level "warning" -Path "publicFacades.sites.$facadeId.expectedMarker" -Message "Aucun marqueur de contenu n est défini pour $facadeId." -NextStep "Ajouter expectedMarker pour permettre le diagnostic du switcher."
            }
        }

        foreach ($requiredFacadeId in @('uckk', 'ucc', 'math')) {
            if (-not $seenFacadeIds.ContainsKey($requiredFacadeId)) {
                Add-UckkIssue -Issues $issues -Level "error" -Path "publicFacades.sites" -Message "Façade obligatoire absente : $requiredFacadeId" -NextStep "Déclarer UCKK, UCC et Math dans publicFacades.sites."
            }
        }
    }

    Add-UckkOneOfMissingValueIssue `
        -Config $Config `
        -Paths @("urls.localBase", "urls.localMoodle") `
        -Issues $issues `
        -Message "URL locale manquante : urls.localBase ou urls.localMoodle."

    Add-UckkOneOfMissingValueIssue `
        -Config $Config `
        -Paths @("urls.serverBase", "urls.publicSite") `
        -Issues $issues `
        -Message "URL serveur manquante : urls.serverBase ou urls.publicSite."

    Add-UckkOneOfMissingValueIssue `
        -Config $Config `
        -Paths @("paths.reportsDir", "reports.dir") `
        -Issues $issues `
        -Message "Dossier rapports manquant : paths.reportsDir ou reports.dir."

    Add-UckkOneOfMissingValueIssue `
        -Config $Config `
        -Paths @("paths.logsDir", "logs.dir") `
        -Issues $issues `
        -Message "Dossier logs manquant : paths.logsDir ou logs.dir."

    Protect-UckkConfigSafetyDefaults -Config $Config -Issues $issues
    Test-UckkConfigSafetyFlags -Config $Config -Issues $issues
    Test-UckkConfigForSecrets -Config $Config -Issues $issues

    $urlPaths = @(
        "urls.localBase",
        "urls.serverBase",
        "urls.localMoodle",
        "urls.publicSite",
        "urls.localMediatheque",
        "urls.serverMediatheque",
        "urls.localCourseIndex",
        "urls.serverCourseIndex"
    )

    foreach ($path in $urlPaths) {
        if (Test-UckkConfigValueExists -Config $Config -Path $path) {
            $value = Get-UckkConfigValue -Config $Config -Path $path

            if ((Test-UckkValuePresent -Value $value) -and -not (Test-UckkUrl -Value $value)) {
                Add-UckkIssue `
                    -Issues $issues `
                    -Level "error" `
                    -Path $path `
                    -Message "URL invalide : $path" `
                    -NextStep "Corriger cette URL dans la configuration."
            }
        }
    }

    if ($CheckFileSystem) {
        $localPathChecks = @(
            "paths.uckkMoodleSource",
            "paths.localMoodleRoot",
            "paths.localMoodleRuntime",
            "git.repoRoot"
        )

        foreach ($path in $localPathChecks) {
            Test-UckkConfiguredLocalPath -Config $Config -ConfigPath $path -Issues $issues -Required
        }

        $optionalLocalPathChecks = @(
            "paths.reportsDir",
            "paths.logsDir",
            "reports.dir",
            "logs.dir",
            "mediatheque.manifestPath"
        )

        foreach ($path in $optionalLocalPathChecks) {
            if (Test-UckkConfigValueExists -Config $Config -Path $path) {
                Test-UckkConfiguredLocalPath -Config $Config -ConfigPath $path -Issues $issues
            }
        }
    }

    $errors = @($issues | Where-Object { $_.level -eq "error" })
    $warnings = @($issues | Where-Object { $_.level -eq "warning" })

    $success = ($errors.Count -eq 0)

    $status = if ($success -and $warnings.Count -gt 0) {
        "Reussi avec avertissements"
    }
    elseif ($success) {
        "Reussi"
    }
    else {
        "Echoue"
    }

    return [pscustomobject]@{
        success  = $success
        status   = $status
        issues   = @($issues)
        errors   = @($errors)
        warnings = @($warnings)
    }
}

function Import-UckkConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Path = "",

        [Parameter(Mandatory = $false)]
        [switch] $CheckFileSystem,

        [Parameter(Mandatory = $false)]
        [switch] $ThrowOnError
    )

    $readResult = Read-UckkConfig -Path $Path

    if (-not $readResult.success) {
        $validation = [pscustomobject]@{
            success  = $false
            status   = "Echoue"
            issues   = @($readResult.errors)
            errors   = @($readResult.errors)
            warnings = @()
        }

        $result = [pscustomobject]@{
            success    = $false
            status     = "Echoue"
            configPath = $readResult.configPath
            config     = $null
            validation = $validation
        }

        if ($ThrowOnError) {
            throw $readResult.errors[0].message
        }

        return $result
    }

    $validation = Test-UckkConfig -Config $readResult.config -CheckFileSystem:$CheckFileSystem

    $result = [pscustomobject]@{
        success    = $validation.success
        status     = $validation.status
        configPath = $readResult.configPath
        config     = $readResult.config
        validation = $validation
    }

    if (-not $result.success -and $ThrowOnError) {
        $firstError = $validation.errors | Select-Object -First 1

        if ($null -ne $firstError) {
            throw $firstError.message
        }

        throw "Configuration invalide."
    }

    return $result
}

function Get-UckkReportsDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    $path = Get-UckkConfigValue -Config $Config -Path "reports.dir" -Default $null

    if (-not (Test-UckkValuePresent -Value $path)) {
        $path = Get-UckkConfigValue -Config $Config -Path "paths.reportsDir" -Default "./reports"
    }

    return Resolve-UckkPathFromAppRoot -Path ([string] $path)
}

function Get-UckkLogsDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    $path = Get-UckkConfigValue -Config $Config -Path "logs.dir" -Default $null

    if (-not (Test-UckkValuePresent -Value $path)) {
        $path = Get-UckkConfigValue -Config $Config -Path "paths.logsDir" -Default "./logs"
    }

    return Resolve-UckkPathFromAppRoot -Path ([string] $path)
}

function Initialize-UckkConfigRuntimeDirs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    $created = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[object]]::new()

    $dirs = @(
        (Get-UckkReportsDir -Config $Config),
        (Get-UckkLogsDir -Config $Config)
    )

    foreach ($dir in $dirs) {
        if (-not (Test-UckkValuePresent -Value $dir)) {
            continue
        }

        try {
            if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                $created.Add($dir)
            }
        }
        catch {
            Add-UckkIssue `
                -Issues $errors `
                -Level "error" `
                -Path $dir `
                -Message "Impossible de creer le dossier : $dir" `
                -NextStep "Verifier les permissions."
        }
    }

    return [pscustomobject]@{
        success = ($errors.Count -eq 0)
        created = @($created)
        errors = @($errors)
    }
}

function Get-UckkServerSshTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    $target = Get-UckkConfigValue -Config $Config -Path "server.sshTarget" -Default $null

    if (Test-UckkValuePresent -Value $target) {
        return [string] $target
    }

    $user = Get-UckkConfigValue -Config $Config -Path "server.sshUser" -Default $null
    $host = Get-UckkConfigValue -Config $Config -Path "server.sshHost" -Default $null

    if ((Test-UckkValuePresent -Value $user) -and (Test-UckkValuePresent -Value $host)) {
        return "$user@$host"
    }

    return $null
}

function ConvertTo-UckkConfigIssueText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Issue
    )

    if ($null -eq $Issue) {
        return ""
    }

    if ($Issue -is [string]) {
        return [string] $Issue
    }

    $level = ""
    $path = ""
    $message = ""
    $nextStep = ""

    if ($Issue.PSObject.Properties.Name -contains "level") {
        $level = [string] $Issue.level
    }

    if ($Issue.PSObject.Properties.Name -contains "path") {
        $path = [string] $Issue.path
    }

    if ($Issue.PSObject.Properties.Name -contains "message") {
        $message = [string] $Issue.message
    }

    if ($Issue.PSObject.Properties.Name -contains "nextStep") {
        $nextStep = [string] $Issue.nextStep
    }

    $parts = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($path)) {
        [void] $parts.Add($path)
    }

    if (-not [string]::IsNullOrWhiteSpace($message)) {
        [void] $parts.Add($message)
    }

    if (-not [string]::IsNullOrWhiteSpace($nextStep)) {
        [void] $parts.Add("Prochaine etape : $nextStep")
    }

    if ($parts.Count -gt 0) {
        if (-not [string]::IsNullOrWhiteSpace($level)) {
            return (($level.ToUpperInvariant()) + " — " + ($parts -join " — "))
        }

        return ($parts -join " — ")
    }

    return [string] $Issue
}

function ConvertTo-UckkConfigIssueTextArray {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Issues
    )

    $items = New-Object System.Collections.Generic.List[string]

    if ($null -eq $Issues) {
        return @()
    }

    foreach ($issue in @($Issues)) {
        $text = ConvertTo-UckkConfigIssueText -Issue $issue

        if (-not [string]::IsNullOrWhiteSpace($text)) {
            [void] $items.Add($text)
        }
    }

    return @($items)
}

function New-UckkConfigActionResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool] $Success,

        [Parameter(Mandatory = $true)]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [string] $Summary,

        [Parameter(Mandatory = $false)]
        [array] $Warnings = @(),

        [Parameter(Mandatory = $false)]
        [array] $Errors = @(),

        [Parameter(Mandatory = $false)]
        [string] $NextStep = "",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Data = $null
    )

    return [pscustomobject]@{
        success     = $Success
        status      = $Status
        action      = "Verifier la configuration"
        domain      = "configuration"
        target      = "configuration"
        dangerLevel = 1
        mode        = "verification"
        summary     = $Summary
        warnings    = @(ConvertTo-UckkConfigIssueTextArray -Issues $Warnings)
        errors      = @(ConvertTo-UckkConfigIssueTextArray -Issues $Errors)
        nextStep    = $NextStep
        reportPath  = ""
        logPath     = ""
        data        = $Data
    }
}

function Test-UckkConfigAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string] $Path = "",

        [Parameter(Mandatory = $false)]
        [switch] $CheckFileSystem
    )

    $import = Import-UckkConfig -Path $Path -CheckFileSystem:$CheckFileSystem

    if ($import.success) {
        return New-UckkConfigActionResult `
            -Success $true `
            -Status $import.status `
            -Summary "Configuration valide." `
            -Warnings $import.validation.warnings `
            -Errors @() `
            -NextStep "Aucune action requise." `
            -Data @{
                configPath = $import.configPath
                validation = $import.validation
            }
    }

    return New-UckkConfigActionResult `
        -Success $false `
        -Status "Echoue" `
        -Summary "Configuration invalide." `
        -Warnings $import.validation.warnings `
        -Errors $import.validation.errors `
        -NextStep "Corriger config/uckk-ops-console.config.json, puis relancer la verification." `
        -Data @{
            configPath = $import.configPath
            validation = $import.validation
        }
}

Export-ModuleMember -Function `
    Get-UckkOpsRoot, `
    Get-UckkDefaultConfigPath, `
    Resolve-UckkConfigPath, `
    Resolve-UckkPathFromAppRoot, `
    Read-UckkConfig, `
    Test-UckkConfig, `
    Import-UckkConfig, `
    Initialize-UckkConfigRuntimeDirs, `
    Get-UckkConfigValue, `
    Get-UckkReportsDir, `
    Get-UckkLogsDir, `
    Get-UckkServerSshTarget, `
    Test-UckkConfigAction
