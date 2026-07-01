# DevSecretsManagerPs

`DevSecretsManagerPs` is a PowerShell script for managing per-project development secrets without storing the secret values in the repository.

The script uses a local `env.json` file next to `SecretsManager.ps1` to identify the project, and stores the actual secrets in the user's home directory:

```text
<HOME>/.devsecretsmanager/<guid>.json
```

## Script

```powershell
.\SecretsManager.ps1
```

Current version:

```powershell
.\SecretsManager.ps1 -Version
```

Returns:

```text
2.0.0
```

`-Version` and `-Help` do not initialize or create files.

Commands that return pipeline output return JSON. `-Edit` only shows information on screen and does not return a pipeline value. Informational messages, colored warnings, confirmations, and lookup notices are written with `Write-Host` and are not intended to be captured as command output.

## Install In A Consumer Project With ToolsManagerPs

Consumer projects can install this repository as a tool by using `ToolsManagerPs`.

Download `ProjectManager.ps1` in the consumer project root:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Satancito/ToolsManagerPs/main/ProjectManager.ps1" -OutFile "ProjectManager.ps1" -UseBasicParsing
```

Initialize the consumer project configuration:

```powershell
.\ProjectManager.ps1 -Init
```

Add `DevSecretsManagerPs` as a Git submodule tool:

```powershell
.\ProjectManager.ps1 -Tools Add -RepositoryName DevSecretsManagerPs -RepositoryUrl https://github.com/Satancito/DevSecretsManagerPs.git -Tag ""
```

`-Tag ""` stores `Tag` as `null`. A `null` tag means the tool is updated to the latest remote commit when `-Tools Update` runs.

The `-Tag` value can be:

- `null`, by passing `-Tag ""`, to track the latest remote commit.
- A Git tag, to pin the tool to a released version.
- A Git commit SHA, to pin the tool to an exact commit.

## Files

### env.json

Location:

```text
<script-directory>/env.json
```

Format:

```json
{
  "Id": "<guid>"
}
```

This file identifies the secret set used by the project. If it does not exist, `-Init` creates it. If it exists but is empty, invalid, not a JSON object, or contains an invalid `Id`, `-Init` regenerates it. If it exists but does not contain `Id`, the script adds that property while preserving any other properties.

### Secrets File

Location:

```text
<HOME>/.devsecretsmanager/<guid>.json
```

Format:

```json
{
  "ApiKey": "secret value",
  "OptionalSecret": null,
  "EmptySecret": ""
}
```

Secrets are stored as direct JSON values. The script does not store extra properties such as `Value`, `Type`, or `Sensitive`.

## Validation

All operational commands, except `-Regenerate`, initialize and validate the environment before running:

- Creates `env.json` if it does not exist.
- Creates `<HOME>/.devsecretsmanager` if it does not exist.
- Creates `<guid>.json` if it does not exist.
- Regenerates `env.json` when it is empty, invalid, not a JSON object, or contains an invalid `Id`.
- Regenerates `<guid>.json` when the secrets file is empty.
- Stops with an error when the secrets file has invalid JSON syntax.
- Stops with an error when the secrets file does not contain a JSON object.

`-Regenerate` is the exception: it deletes `env.json` first, then initializes a new environment.

## Help

```powershell
.\SecretsManager.ps1 -Help
.\SecretsManager.ps1 -h
```

Returns the script's summary help as JSON. It does not create or modify files.

## Init

```powershell
.\SecretsManager.ps1 -Init
```

Initializes the current environment.

It does the following:

- Creates `env.json` if it does not exist.
- Regenerates `env.json` if it is empty, invalid, not a JSON object, or contains an invalid `Id`.
- Adds `Id` to `env.json` if it is missing.
- Creates `<HOME>/.devsecretsmanager` if it does not exist.
- Creates `<guid>.json` if it does not exist.
- Validates that existing JSON files contain valid objects.

It shows non-capturable status information:

```text
Environment Id: ...
env.json: ... [Created|Existing|Regenerated|IdAdded]
Secrets directory: ... [Created|Existing]
Secrets file: ... [Created|Existing|Regenerated]
```

At the end, it returns the full `guid.json` secrets file path as a JSON string:

```powershell
$path = .\SecretsManager.ps1 -Init | ConvertFrom-Json
```

## Add

```powershell
.\SecretsManager.ps1 -Add <SecretName>
.\SecretsManager.ps1 -Add <SecretName> -Value <Value>
.\SecretsManager.ps1 -Add <SecretName> -Empty
.\SecretsManager.ps1 -Add <SecretName> -Value <Value> -Force
```

Adds a secret.

Behavior:

- Without `-Value` or `-Empty`, stores `null`.
- With `-Value "abc"`, stores `"abc"`.
- With `-Value ""`, stores an empty string.
- With `-Empty`, stores an empty string.
- If the secret already exists, it is not replaced unless `-Force` is used.
- With `-Force`, replaces existing secrets and adds missing secrets.

JSON return value:

- `true` when the secret was added or replaced.
- `false` when the secret already existed and `-Force` was not used.

Examples:

```powershell
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "abc123" | ConvertFrom-Json
$saved = .\SecretsManager.ps1 -Add OptionalSecret | ConvertFrom-Json
$saved = .\SecretsManager.ps1 -Add EmptySecret -Empty | ConvertFrom-Json
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "new-value" -Force | ConvertFrom-Json
```

JSON result:

```json
true
```

## Get

```powershell
.\SecretsManager.ps1 -Get <SecretName>
```

Gets a secret value.

Behavior:

- If the secret exists, shows that it was found.
- If the value is `null`, shows `Value: null` in cyan.
- If the value is an empty string, shows `Value: empty` in cyan.
- If the secret does not exist, shows that it does not exist and returns `null`.
- Does not fail when the secret does not exist.

JSON return value:

- The secret value as JSON when the secret exists.
- `null` when the secret does not exist.
- `null` when the secret exists and its stored value is `null`.
- `""` when the secret exists and its stored value is an empty string.

Example:

```powershell
$apiKey = .\SecretsManager.ps1 -Get ApiKey | ConvertFrom-Json
```

## Exists

```powershell
.\SecretsManager.ps1 -Exists <SecretName>
```

Checks whether a secret exists without showing its value.

JSON return value:

- `true` when the secret exists.
- `false` when the secret does not exist.

This returns `true` even when the secret value is `null` or an empty string.

Example:

```powershell
$exists = .\SecretsManager.ps1 -Exists ApiKey | ConvertFrom-Json
if (-not $exists) {
    throw "ApiKey is not configured"
}
```

## List

```powershell
.\SecretsManager.ps1 -List
```

Returns the raw JSON content of the current secrets file.

Example:

```powershell
$json = .\SecretsManager.ps1 -List
```

Output:

```json
{
  "ApiKey": "abc123",
  "OptionalSecret": null,
  "EmptySecret": ""
}
```

## Edit

```powershell
.\SecretsManager.ps1 -Edit
.\SecretsManager.ps1 -Edit -Editor <EditorName>
```

Opens the current secrets file in an editor.

This command only shows information on screen and does not return a pipeline value.

Default editor:

- Windows: `Notepad`
- Linux/macOS/Unix-like: `vi`

Examples:

```powershell
.\SecretsManager.ps1 -Edit
.\SecretsManager.ps1 -Edit -Editor code
```

## Remove

```powershell
.\SecretsManager.ps1 -Remove <SecretName>
.\SecretsManager.ps1 -Remove <SecretName> -Force
```

Removes a secret.

Behavior:

- Always shows the value first using the same display logic as `-Get`.
- If the secret exists, also shows a table with the value that will be removed.
- Without `-Force`, asks for confirmation.
- Removes only when confirmed with `y` or `yes`.
- Confirmation is case-insensitive: `Y`, `YES`, `yEs`, etc. are valid.
- Confirmation prompts are shown in bright yellow.
- When confirmation is accepted, shows `Confirmed.` in bright green.
- With `-Force`, does not ask and removes directly.
- Does not fail when the secret does not exist.

JSON return value:

- `true` when the secret was removed.
- `false` when the secret did not exist or removal was not confirmed.

Examples:

```powershell
$removed = .\SecretsManager.ps1 -Remove ApiKey | ConvertFrom-Json
$removed = .\SecretsManager.ps1 -Remove ApiKey -Force | ConvertFrom-Json
```

## Clear

```powershell
.\SecretsManager.ps1 -Clear
.\SecretsManager.ps1 -Clear -Force
```

Removes all secrets from the current secrets file, leaving the JSON as:

```json
{}
```

Behavior:

- Without `-Force`, asks for confirmation.
- With `-Force`, clears without asking.
- Confirmation prompts are shown in bright yellow.
- When confirmation is accepted, shows `Confirmed.` in bright green.

JSON return value:

- `true` when the file was cleared.
- `false` when the action was canceled.

## Regenerate

```powershell
.\SecretsManager.ps1 -Regenerate
.\SecretsManager.ps1 -Regenerate -Force
```

Regenerates the project environment.

It does the following:

- Deletes `env.json`.
- Creates a new `env.json` with a new `Id`.
- Initializes a new `<HOME>/.devsecretsmanager/<new-guid>.json` file.

Behavior:

- Without `-Force`, asks for confirmation.
- With `-Force`, regenerates without asking.
- If canceled, does not delete `env.json`.

JSON return value:

- `true` when the environment was regenerated.
- `false` when the action was canceled.

## Version

```powershell
.\SecretsManager.ps1 -Version
```

Returns the script version as JSON.

```json
"2.0.0"
```

Does not initialize or modify files.

## JSON Output

The script separates visible messages from JSON pipeline output. `-Edit` opens the editor and does not return a pipeline value.

Examples:

```powershell
$init = .\SecretsManager.ps1 -Init | ConvertFrom-Json
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "abc123" | ConvertFrom-Json
$value = .\SecretsManager.ps1 -Get ApiKey | ConvertFrom-Json
$exists = .\SecretsManager.ps1 -Exists ApiKey | ConvertFrom-Json
$removed = .\SecretsManager.ps1 -Remove ApiKey -Force | ConvertFrom-Json
```

Informational messages are shown on screen with `Write-Host`; command output written to the pipeline is JSON.

## Recommended Workflow

Initialize once per project:

```powershell
.\SecretsManager.ps1 -Init
```

Add secrets:

```powershell
.\SecretsManager.ps1 -Add ApiUrl -Value "https://localhost:5001"
.\SecretsManager.ps1 -Add ApiKey -Value "dev-key"
```

Consume from scripts:

```powershell
$apiKeyExists = .\SecretsManager.ps1 -Exists ApiKey | ConvertFrom-Json
if (-not $apiKeyExists) {
    throw "ApiKey is not configured"
}
$apiKey = .\SecretsManager.ps1 -Get ApiKey | ConvertFrom-Json
```

Export JSON:

```powershell
.\SecretsManager.ps1 -List
```
