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
1.1.0
```

`-Version` and `-Help` do not initialize or create files.

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

This file identifies the secret set used by the project. If it does not exist, `-Init` creates it. If it exists but does not contain `Id`, the script adds that property while preserving any other properties.

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
- Regenerates `env.json` or `<guid>.json` when either file is empty.
- Stops with an error when either file has invalid JSON syntax.
- Stops with an error when either file does not contain a JSON object.

`-Regenerate` is the exception: it deletes `env.json` first, then initializes a new environment.

## Help

```powershell
.\SecretsManager.ps1 -Help
.\SecretsManager.ps1 -h
```

Shows the script's summary help. It does not create or modify files.

## Init

```powershell
.\SecretsManager.ps1 -Init
```

Initializes the current environment.

It does the following:

- Creates `env.json` if it does not exist.
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

At the end, it returns the full secrets file path so it can be captured:

```powershell
$path = .\SecretsManager.ps1 -Init
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

Capturable return value:

- `$true` when the secret was added or replaced.
- `$false` when the secret already existed and `-Force` was not used.

Examples:

```powershell
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "abc123"
$saved = .\SecretsManager.ps1 -Add OptionalSecret
$saved = .\SecretsManager.ps1 -Add EmptySecret -Empty
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "new-value" -Force
```

JSON result:

```json
{
  "ApiKey": "new-value",
  "OptionalSecret": null,
  "EmptySecret": ""
}
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
- If the secret does not exist, shows that it does not exist and returns `$null`.
- Does not fail when the secret does not exist.

Capturable return value:

- The real JSON value when the secret exists.
- `$null` when the secret does not exist.

Example:

```powershell
$apiKey = .\SecretsManager.ps1 -Get ApiKey
```

## Exists

```powershell
.\SecretsManager.ps1 -Exists <SecretName>
```

Checks whether a secret exists without showing its value.

Capturable return value:

- `$true` when the secret exists.
- `$false` when the secret does not exist.

This returns `$true` even when the secret value is `null` or an empty string.

Example:

```powershell
if (-not (.\SecretsManager.ps1 -Exists ApiKey)) {
    throw "ApiKey is not configured"
}
```

## List

```powershell
.\SecretsManager.ps1 -List
```

Shows all secrets sorted by name in a table.

Visual details:

- Headers are magenta.
- Names are bright blue.
- `null` and `empty` are cyan.
- Column separators use a continuous Unicode line.

Example:

```text
Name         Value
───────────  ─────
ApiKey       abc123
EmptySecret  empty
NullSecret   null
```

## Json

```powershell
.\SecretsManager.ps1 -Json
```

Returns the raw JSON content of the current secrets file.

Example:

```powershell
$json = .\SecretsManager.ps1 -Json
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

Capturable return value:

- `$true` when the secret was removed.
- `$false` when the secret did not exist or removal was not confirmed.

Examples:

```powershell
$removed = .\SecretsManager.ps1 -Remove ApiKey
$removed = .\SecretsManager.ps1 -Remove ApiKey -Force
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

Capturable return value:

- `$true` when the file was cleared.
- `$false` when the action was canceled.

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
- Returns the path of the new secrets file.

Behavior:

- Without `-Force`, asks for confirmation.
- With `-Force`, regenerates without asking.
- If canceled, does not delete `env.json`.

Capturable return value:

- Path of the new secrets file when regeneration happens.
- `$null` when the action is canceled.

## Version

```powershell
.\SecretsManager.ps1 -Version
```

Returns the script version.

```text
1.1.0
```

Does not initialize or modify files.

## Capturing Output

The script separates visible messages from capturable output.

Examples:

```powershell
$path = .\SecretsManager.ps1 -Init
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "abc123"
$value = .\SecretsManager.ps1 -Get ApiKey
$exists = .\SecretsManager.ps1 -Exists ApiKey
$removed = .\SecretsManager.ps1 -Remove ApiKey -Force
```

Informational messages are shown on screen with `Write-Host`; important return values are written to the pipeline with `Write-Output`.

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
$apiKey = .\SecretsManager.ps1 -Get ApiKey
if ($null -eq $apiKey) {
    throw "ApiKey is not configured"
}
```

List configured values:

```powershell
.\SecretsManager.ps1 -List
```

Export JSON:

```powershell
.\SecretsManager.ps1 -Json
```
