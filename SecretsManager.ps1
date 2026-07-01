[CmdletBinding(DefaultParameterSetName = "AddNull")]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Edit")]
    [switch] $Edit,

    [Parameter(ParameterSetName = "Edit")]
    [ValidateNotNullOrEmpty()]
    [string] $Editor,

    [Parameter(Mandatory = $true, ParameterSetName = "List")]
    [switch] $List,

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
$ScriptVersion = "2.0.0"

function Show-Usage {
    Write-JsonResult ([ordered]@{
        Command = "Help"
        Version = $ScriptVersion
        Usage = @(
            ".\SecretsManager.ps1 -Init",
            ".\SecretsManager.ps1 -Clear [-Force]",
            ".\SecretsManager.ps1 -Regenerate [-Force]",
            ".\SecretsManager.ps1 -Edit [-Editor <EditorName>]",
            ".\SecretsManager.ps1 -List",
            ".\SecretsManager.ps1 -Get <SecretName>",
            ".\SecretsManager.ps1 -Exists <SecretName>",
            ".\SecretsManager.ps1 -Add <SecretName> [-Value <Value> | -Empty] [-Force]",
            ".\SecretsManager.ps1 -Remove <SecretName> [-Force]",
            ".\SecretsManager.ps1 -Version",
            ".\SecretsManager.ps1 -Help",
            ".\SecretsManager.ps1 -h"
        )
        Storage = [ordered]@{
            EnvFile = "env.json, next to SecretsManager.ps1"
            SecretsFile = "<HOME>/.devsecretsmanager/<env-id>.json"
        }
        Notes = @(
            "-Init creates env.json when missing, regenerates it when it is invalid, adds Id when needed, creates the secrets file when missing, and returns JSON.",
            "-List returns the secrets file content exactly as JSON.",
            "-Get returns only the selected secret value as JSON, or null when it does not exist.",
            "Commands that return pipeline output return JSON. -Edit does not return a pipeline value.",
            "Informational messages and colored warnings are written with Write-Host."
        )
    })
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

    try {
        $envJson = Read-JsonObjectFile -Path $EnvFilePath -DisplayName "env.json"
    }
    catch {
        Write-JsonFile -Path $EnvFilePath -Value ([ordered]@{
            Id = $id
        })

        return [PSCustomObject]@{
            Id = $id
            Status = "Regenerated"
        }
    }
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
        Write-JsonFile -Path $EnvFilePath -Value ([ordered]@{
            Id = $id
        })

        return [PSCustomObject]@{
            Id = $id
            Status = "Regenerated"
        }
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

function Write-JsonResult {
    param(
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        Write-Output "null"
        return
    }

    Write-Output ($Value | ConvertTo-Json -Depth 20)
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
    $envSummary = "env.json: $($Environment.EnvFilePath) [$($Environment.EnvFileStatus)]"
    if ($Environment.EnvFileStatus -in @("Created", "Regenerated")) {
        Write-ColoredText -Text "WARNING: $envSummary" -AnsiColor "93"
    }
    else {
        Write-Host $envSummary
    }
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
    Write-JsonResult $ScriptVersion
    return
}

if ($PSCmdlet.ParameterSetName -like "Add*" -and [string]::IsNullOrWhiteSpace($Add)) {
    throw "Use -Add <SecretName>."
}

if ($PSCmdlet.ParameterSetName -eq "Regenerate") {
    if (-not $Force -and -not (Confirm-Action -Prompt "Regenerate environment? This deletes env.json and creates a new Id. Type y or yes to confirm")) {
        Write-Host "Environment was not regenerated."
        Write-JsonResult $false
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
        Write-JsonResult $environment.SecretsFilePath
    }

    "Clear" {
        Write-Host "Secrets file: $($environment.SecretsFilePath)"
        if (-not $Force -and -not (Confirm-Action -Prompt "Clear all secrets? Type y or yes to confirm")) {
            Write-Host "Secrets file was not cleared."
            Write-JsonResult $false
            return
        }

        Write-JsonFile -Path $environment.SecretsFilePath -Value ([ordered]@{})
        Write-Host "Secrets file cleared."
        Write-JsonResult $true
    }

    "Regenerate" {
        Write-Host "Environment regenerated."
        Write-InitializationSummary -Environment $environment
        Write-JsonResult $true
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
        Write-Output (Get-Content -LiteralPath $environment.SecretsFilePath -Raw)
    }

    "Get" {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath
        $secret = Get-SecretValue -Secrets $secrets -Name $Get

        Write-JsonResult $secret.Value
    }

    "Exists" {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath
        Write-JsonResult $secrets.Contains($Exists)
    }

    { $_ -like "Add*" } {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath

        if ($secrets.Contains($Add) -and -not $Force) {
            Write-Host "Secret '$Add' already exists. Use -Force to overwrite it."
            Write-JsonResult $false
            return
        }

        $replaced = $secrets.Contains($Add)
        $convertedValue = switch ($PSCmdlet.ParameterSetName) {
            "AddEmpty" { [string]::Empty }
            "AddValue" { $Value }
            default { $null }
        }

        $secrets[$Add] = $convertedValue

        Write-JsonFile -Path $environment.SecretsFilePath -Value $secrets
        if ($replaced) {
            Write-Host "Secret '$Add' replaced."
        }
        elseif ($Force) {
            Write-Host "Secret '$Add' added with -Force."
        }
        else {
            Write-Host "Secret '$Add' added."
        }
        Write-JsonResult $true
    }

    "Remove" {
        $secrets = Read-Secrets -Path $environment.SecretsFilePath
        $secret = Get-SecretValue -Secrets $secrets -Name $Remove

        if (-not $secret.Exists) {
            Write-JsonResult $false
            return
        }

        $row = Convert-SecretToTableRow -Name $Remove -Entry $secret.Value
        Write-SecretsTable -Rows @($row)

        if (-not $Force) {
            if (-not (Confirm-Action -Prompt "Remove this secret? Type y or yes to confirm")) {
                Write-Host "Secret '$Remove' was not removed."
                Write-JsonResult $false
                return
            }
        }

        $secrets.Remove($Remove)
        Write-JsonFile -Path $environment.SecretsFilePath -Value $secrets
        Write-Host "Secret '$Remove' removed."
        Write-JsonResult $true
    }
}
