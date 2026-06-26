[CmdletBinding(DefaultParameterSetName = "AddNull")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Edit")]
    [switch] $Edit,

    [Parameter(ParameterSetName = "Edit")]
    [ValidateNotNullOrEmpty()]
    [string] $Editor,

    [Parameter(Mandatory = $true, ParameterSetName = "List")]
    [switch] $List,

    [Parameter(Mandatory = $true, ParameterSetName = "Json")]
    [switch] $Json,

    [Parameter(Mandatory = $true, ParameterSetName = "Init")]
    [switch] $Init,

    [Parameter(Mandatory = $true, ParameterSetName = "Clear")]
    [switch] $Clear,

    [Parameter(Mandatory = $true, ParameterSetName = "Regenerate")]
    [switch] $Regenerate,

    [Parameter(Mandatory = $true, ParameterSetName = "Get")]
    [ValidateNotNullOrEmpty()]
    [string] $Get,

    [Parameter(Mandatory = $true, ParameterSetName = "Exists")]
    [ValidateNotNullOrEmpty()]
    [string] $Exists,

    [Parameter(ParameterSetName = "AddNull")]
    [Parameter(Mandatory = $true, ParameterSetName = "AddValue")]
    [Parameter(Mandatory = $true, ParameterSetName = "AddEmpty")]
    [ValidateNotNullOrEmpty()]
    [string] $Add,

    [Parameter(Mandatory = $true, ParameterSetName = "Remove")]
    [ValidateNotNullOrEmpty()]
    [string] $Remove,

    [Parameter(ParameterSetName = "AddValue")]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $Value,

    [Parameter(ParameterSetName = "AddEmpty")]
    [switch] $Empty,

    [Parameter(ParameterSetName = "AddNull")]
    [Parameter(ParameterSetName = "AddValue")]
    [Parameter(ParameterSetName = "AddEmpty")]
    [Parameter(ParameterSetName = "Clear")]
    [Parameter(ParameterSetName = "Regenerate")]
    [Parameter(ParameterSetName = "Remove")]
    [switch] $Force,

    [Parameter(ParameterSetName = "Help")]
    [Alias("h")]
    [switch] $Help,

    [Parameter(ParameterSetName = "Version")]
    [switch] $Version
)

$ErrorActionPreference = "Stop"
$ScriptVersion = "1.1.3"

function Show-Usage {
    $usage = @"
Dev Secrets Manager

Usage:
  .\SecretsManager.ps1 -Init
  .\SecretsManager.ps1 -Clear [-Force]
  .\SecretsManager.ps1 -Regenerate [-Force]
  .\SecretsManager.ps1 -Edit [-Editor <EditorName>]
  .\SecretsManager.ps1 -List
  .\SecretsManager.ps1 -Json
  .\SecretsManager.ps1 -Get <SecretName>
  .\SecretsManager.ps1 -Exists <SecretName>
  .\SecretsManager.ps1 -Add <SecretName> [-Value <Value> | -Empty] [-Force]
  .\SecretsManager.ps1 -Remove <SecretName> [-Force]
  .\SecretsManager.ps1 -Version
  .\SecretsManager.ps1 -Help
  .\SecretsManager.ps1 -h

Storage:
  Project env file:
    env.json, next to SecretsManager.ps1

  User secrets file:
    <HOME>/.devsecretsmanager/<env-id>.json

env.json format:
  {
    "Id": "<guid>"
  }

Secrets file format:
  {
    "SecretName": "secret value",
    "NullSecret": null,
    "EmptySecret": ""
  }

Notes:
  - -Init creates env.json when missing, adds Id when needed, creates the secrets file when missing, and returns the full secrets file path.
  - -Clear asks for confirmation, removes all secrets from the current secrets file, leaves an empty JSON object, and returns true when cleared.
  - -Clear -Force clears without asking for confirmation.
  - -Regenerate asks for confirmation, deletes env.json, creates a new Id, initializes a new secrets file, and returns the full secrets file path.
  - -Regenerate -Force regenerates without asking for confirmation.
  - -Version returns the script version.
  - All operational commands initialize and validate env.json and the secrets file before running.
  - -Regenerate is the exception: it deletes env.json first, then initializes a new environment.
  - Empty env.json or secrets files are regenerated; invalid JSON syntax stops execution.

Read:
  - -List shows all secrets sorted by name.
  - -Json returns the secrets file content exactly as JSON.
  - -Get <SecretName> shows whether the secret exists, highlights null/empty values, and returns the selected value or null.
  - -Exists <SecretName> returns true when the secret exists, false otherwise.
  - -Edit opens the secrets file using Notepad on Windows and vi on Unix-like systems unless -Editor is provided.

Add:
  - -Add <SecretName> always stores string secrets.
  - -Add <SecretName> stores null when -Value and -Empty are not provided.
  - -Add <SecretName> stores an empty string when -Empty or -Value "" is provided.
  - -Add returns true when saved, false when an existing secret was not replaced.
  - -Add -Force overwrites existing secrets and adds missing secrets.

Remove:
  - -Remove <SecretName> shows the selected secret and only removes it when confirmed with y or yes.
  - Confirmation is case-insensitive.
  - -Remove <SecretName> returns true when removed, false otherwise.
  - -Remove <SecretName> -Force shows the selected secret and deletes it without asking for confirmation.
  - Default editor is Notepad on Windows and vi on Linux/macOS.
"@

    Write-Host $usage
}

function Get-HomeDirectory {
    if (-not [string]::IsNullOrWhiteSpace($HOME)) {
        return $HOME
    }

    return [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
}

function Test-IsWindows {
    return [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::Windows)
}

function Get-DefaultEditor {
    if (Test-IsWindows) {
        return "Notepad"
    }

    return "vi"
}

function Get-ScriptDirectory {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        return $PSScriptRoot
    }

    return Split-Path -Parent $PSCommandPath
}

function Get-EnvFilePath {
    return Join-Path (Get-ScriptDirectory) "env.json"
}

function Get-SecretsDirectory {
    return Join-Path (Get-HomeDirectory) ".devsecretsmanager"
}

function Get-SecretsFilePath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Id
    )

    return Join-Path (Get-SecretsDirectory) "$Id.json"
}

function Read-JsonObjectFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $DisplayName
    )

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    if (-not $raw.TrimStart().StartsWith("{")) {
        throw "$DisplayName must contain a JSON object."
    }

    try {
        $json = ConvertFrom-Json -InputObject $raw -ErrorAction Stop
    }
    catch {
        throw "$DisplayName has invalid JSON syntax. $($_.Exception.Message)"
    }

    if ($json -isnot [PSCustomObject]) {
        throw "$DisplayName must contain a JSON object."
    }

    return $json
}

function Initialize-EnvironmentId {
    param(
        [Parameter(Mandatory = $true)]
        [string] $EnvFilePath
    )

    $id = [Guid]::NewGuid().ToString()

    if (-not (Test-Path -LiteralPath $EnvFilePath)) {
        Write-JsonFile -Path $EnvFilePath -Value ([ordered]@{
            Id = $id
        })

        return [PSCustomObject]@{
            Id = $id
            Status = "Created"
        }
    }

    $envJson = Read-JsonObjectFile -Path $EnvFilePath -DisplayName "env.json"
    if ($null -eq $envJson) {
        Write-JsonFile -Path $EnvFilePath -Value ([ordered]@{
            Id = $id
        })

        return [PSCustomObject]@{
            Id = $id
            Status = "Regenerated"
        }
    }

    $envValues = [ordered]@{}
    foreach ($property in $envJson.PSObject.Properties) {
        $envValues[$property.Name] = $property.Value
    }

    $existingId = [string] $envValues["Id"]

    if ([string]::IsNullOrWhiteSpace($existingId)) {
        $envValues["Id"] = $id
        Write-JsonFile -Path $EnvFilePath -Value $envValues

        return [PSCustomObject]@{
            Id = $id
            Status = "IdAdded"
        }
    }

    $parsedGuid = [Guid]::Empty
    if (-not [Guid]::TryParse($existingId, [ref] $parsedGuid)) {
        throw "env.json Id value is not a valid GUID."
    }

    return [PSCustomObject]@{
        Id = $parsedGuid.ToString()
        Status = "Existing"
    }
}

function Initialize-SecretsFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-JsonFile -Path $Path -Value ([ordered]@{})
        return "Created"
    }

    $secretsJson = Read-JsonObjectFile -Path $Path -DisplayName "secrets file"
    if ($null -eq $secretsJson) {
        Write-JsonFile -Path $Path -Value ([ordered]@{})
        return "Regenerated"
    }

    return "Existing"
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [object] $Value
    )

    $json = $Value | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Initialize-SecretsEnvironment {
    $envFilePath = Get-EnvFilePath
    $envState = Initialize-EnvironmentId -EnvFilePath $envFilePath
    $id = $envState.Id

    $secretsDirectory = Get-SecretsDirectory
    $secretsDirectoryStatus = "Existing"
    if (-not (Test-Path -LiteralPath $secretsDirectory)) {
        New-Item -ItemType Directory -Path $secretsDirectory | Out-Null
        $secretsDirectoryStatus = "Created"
    }

    $secretsFilePath = Get-SecretsFilePath -Id $id
    $secretsFileStatus = Initialize-SecretsFile -Path $secretsFilePath

    return [PSCustomObject]@{
        Id = $id
        EnvFilePath = $envFilePath
        EnvFileStatus = $envState.Status
        SecretsDirectory = $secretsDirectory
        SecretsDirectoryStatus = $secretsDirectoryStatus
        SecretsFilePath = $secretsFilePath
        SecretsFileStatus = $secretsFileStatus
    }
}

function Read-Secrets {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $raw = Get-Content -LiteralPath $Path -Raw
    $secrets = [ordered]@{}

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $secrets
    }

    $parsed = Read-JsonObjectFile -Path $Path -DisplayName "secrets file"
    foreach ($property in $parsed.PSObject.Properties) {
        $secrets[$property.Name] = $property.Value
    }

    return $secrets
}

function Convert-SecretToTableRow {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [AllowNull()]
        [object] $Entry
    )

    return [PSCustomObject]@{
        Name = $Name
        Value = $Entry
    }
}

function Convert-SecretValueToText {
    param(
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return "null"
    }

    if ([string]::Empty -eq [string] $Value) {
        return "empty"
    }

    return [string] $Value
}

function Write-ColoredText {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Text,

        [Parameter(Mandatory = $true)]
        [string] $AnsiColor,

        [switch] $NoNewline
    )

    $escape = [char] 27
    $coloredText = "$escape[$AnsiColor`m$Text$escape[0m"

    if ($NoNewline) {
        Write-Host $coloredText -NoNewline
    }
    else {
        Write-Host $coloredText
    }
}

function Write-SecretsTable {
    param(
        [Parameter(Mandatory = $true)]
        [array] $Rows
    )

    $nameHeader = "Name"
    $valueHeader = "Value"
    $nameWidth = $nameHeader.Length
    $valueWidth = $valueHeader.Length

    foreach ($row in $Rows) {
        $nameWidth = [Math]::Max($nameWidth, ([string] $row.Name).Length)
        $valueText = Convert-SecretValueToText -Value $row.Value
        $valueWidth = [Math]::Max($valueWidth, $valueText.Length)
    }

    Write-Host ("{0,-$nameWidth}" -f $nameHeader) -ForegroundColor Magenta -NoNewline
    Write-Host "  " -NoNewline
    Write-Host ("{0,-$valueWidth}" -f $valueHeader) -ForegroundColor Magenta

    Write-Host ("{0,-$nameWidth}" -f ("─" * $nameWidth)) -ForegroundColor DarkGray -NoNewline
    Write-Host "  " -NoNewline
    Write-Host ("{0,-$valueWidth}" -f ("─" * $valueWidth)) -ForegroundColor DarkGray

    foreach ($row in $Rows) {
        $name = [string] $row.Name
        $valueText = Convert-SecretValueToText -Value $row.Value
        Write-ColoredText -Text ("{0,-$nameWidth}" -f $name) -AnsiColor "94" -NoNewline
        Write-Host "  " -NoNewline

        if ($null -eq $row.Value -or [string]::Empty -eq [string] $row.Value) {
            Write-Host ("{0,-$valueWidth}" -f $valueText) -ForegroundColor Cyan
        }
        else {
            Write-Host ("{0,-$valueWidth}" -f $valueText)
        }
    }
}

function Write-SecretLookupMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [bool] $Found,

        [AllowNull()]
        [object] $Value
    )

    if (-not $Found) {
        Write-Host "Secret '$Name' does not exist. Value: " -NoNewline
        Write-Host "null" -ForegroundColor Cyan
        return
    }

    Write-Host "Secret '$Name' found."
    if ($null -eq $Value) {
        Write-Host "Value: " -NoNewline
        Write-Host "null" -ForegroundColor Cyan
    }
    elseif ([string]::Empty -eq [string] $Value) {
        Write-Host "Value: " -NoNewline
        Write-Host "empty" -ForegroundColor Cyan
    }
}

function Get-SecretValue {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary] $Secrets,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if (-not $Secrets.Contains($Name)) {
        Write-SecretLookupMessage -Name $Name -Found $false -Value $null

        return [PSCustomObject]@{
            Exists = $false
            Value = $null
        }
    }

    $secretValue = $Secrets[$Name]
    Write-SecretLookupMessage -Name $Name -Found $true -Value $secretValue

    return [PSCustomObject]@{
        Exists = $true
        Value = $secretValue
    }
}

function Write-InitializationSummary {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Environment
    )

    Write-Host "Environment Id: $($Environment.Id)"
    Write-Host "env.json: $($Environment.EnvFilePath) [$($Environment.EnvFileStatus)]"
    Write-Host "Secrets directory: $($Environment.SecretsDirectory) [$($Environment.SecretsDirectoryStatus)]"
    Write-Host "Secrets file: $($Environment.SecretsFilePath) [$($Environment.SecretsFileStatus)]"
}

function Confirm-Action {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Prompt
    )

    Write-ColoredText -Text $Prompt -AnsiColor "93" -NoNewline
    Write-Host " " -NoNewline
    $confirmation = [string] (Read-Host)
    $confirmed = $confirmation.Trim().ToLowerInvariant() -in @("yes", "y")

    if ($confirmed) {
        Write-ColoredText -Text "Confirmed." -AnsiColor "92"
    }

    return $confirmed
}

if ($PSBoundParameters.Count -eq 0 -or $PSCmdlet.ParameterSetName -eq "Help") {
    Show-Usage
    return
}

if ($PSCmdlet.ParameterSetName -eq "Version") {
    Write-Output $ScriptVersion
    return
}

if ($PSCmdlet.ParameterSetName -like "Add*" -and [string]::IsNullOrWhiteSpace($Add)) {
    throw "Use -Add <SecretName>."
}

if ($PSCmdlet.ParameterSetName -eq "Regenerate") {
    if (-not $Force -and -not (Confirm-Action -Prompt "Regenerate environment? This deletes env.json and creates a new Id. Type y or yes to confirm")) {
        Write-Host "Environment was not regenerated."
        Write-Output $null
        return
    }

    $envFilePath = Get-EnvFilePath
    if (Test-Path -LiteralPath $envFilePath) {
        Remove-Item -LiteralPath $envFilePath
    }
}

$environment = Initialize-SecretsEnvironment

switch ($PSCmdlet.ParameterSetName) {
    "Init" {
        Write-InitializationSummary -Environment $environment
        Write-Output $environment.SecretsFilePath
    }

    "Clear" {
        Write-Host "Secrets file: $($environment.SecretsFilePath)"
        if (-not $Force -and -not (Confirm-Action -Prompt "Clear all secrets? Type y or yes to confirm")) {
            Write-Host "Secrets file was not cleared."
            Write-Output $false
            return
        }

        Write-JsonFile -Path $environment.SecretsFilePath -Value ([ordered]@{})
        Write-Host "Secrets file cleared."
        Write-Output $true
    }

    "Regenerate" {
        Write-Host "Environment regenerated."
        Write-InitializationSummary -Environment $environment
        Write-Output $environment.SecretsFilePath
    }

    "Edit" {
        $selectedEditor = if ([string]::IsNullOrWhiteSpace($Editor)) {
            Get-DefaultEditor
        }
        else {
            $Editor
        }

        & $selectedEditor $environment.SecretsFilePath
    }

    "List" {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath

        if ($secrets.Count -eq 0) {
            Write-Host "No secrets found."
            return
        }

        $rows = $secrets.Keys |
            Sort-Object |
            ForEach-Object {
                Convert-SecretToTableRow -Name $_ -Entry $secrets[$_]
            }

        Write-SecretsTable -Rows @($rows)
    }

    "Json" {
        Write-Output (Get-Content -LiteralPath $environment.SecretsFilePath -Raw)
    }

    "Get" {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath
        $secret = Get-SecretValue -Secrets $secrets -Name $Get

        Write-Output $secret.Value
    }

    "Exists" {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath
        Write-Output $secrets.Contains($Exists)
    }

    { $_ -like "Add*" } {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath

        if ($secrets.Contains($Add) -and -not $Force) {
            Write-Host "Secret '$Add' already exists. Use -Force to overwrite it."
            Write-Output $false
            return
        }

        $convertedValue = switch ($PSCmdlet.ParameterSetName) {
            "AddEmpty" { [string]::Empty }
            "AddValue" { $Value }
            default { $null }
        }

        $secrets[$Add] = $convertedValue

        Write-JsonFile -Path $environment.SecretsFilePath -Value $secrets
        if ($Force) {
            Write-Host "Secret '$Add' saved with -Force."
        }
        else {
            Write-Host "Secret '$Add' saved."
        }
        Write-Output $true
    }

    "Remove" {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath
        $secret = Get-SecretValue -Secrets $secrets -Name $Remove

        if (-not $secret.Exists) {
            Write-Output $false
            return
        }

        $row = Convert-SecretToTableRow -Name $Remove -Entry $secret.Value
        Write-SecretsTable -Rows @($row)

        if (-not $Force) {
            if (-not (Confirm-Action -Prompt "Remove this secret? Type y or yes to confirm")) {
                Write-Host "Secret '$Remove' was not removed."
                Write-Output $false
                return
            }
        }

        $secrets.Remove($Remove)
        Write-JsonFile -Path $environment.SecretsFilePath -Value $secrets
        Write-Host "Secret '$Remove' removed."
        Write-Output $true
    }
}
