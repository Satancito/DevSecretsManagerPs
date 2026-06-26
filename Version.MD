# Release Version Guide

This file defines the required workflow for publishing changes from this repository to the remote Git repository.

## Release Flow

Before committing or tagging a release, clear the local secrets file used by this repository:

```powershell
.\SecretsManager.ps1 -Clear -Force
```

Update the script version in:

```text
SecretsManager.ps1
```

Choose the next version based on the changes made.

Example version:

```text
1.0.1
```

Use semantic versioning:

- Patch version for fixes and small documentation updates.
- Minor version for new commands, new behavior, or backward-compatible features.
- Major version for breaking changes.

Also update any documentation that shows the current version, such as:

```text
README.md
```

## Update Help And Documentation

Always update the command help exposed by:

```powershell
.\SecretsManager.ps1 -Help
```

The `-Help` output must describe the current commands, flags, behavior, return values, and important safety rules.

Also update repository documentation when the change affects usage, installation, release flow, or agent instructions:

```text
README.md
Secrets-Agent.MD
Version.MD
```

Keep the README as the source of truth for tool usage and available commands. Keep `Secrets-Agent.MD` focused on installation and agent workflow only.

## Validate Before Commit

Validate the PowerShell script before staging:

```powershell
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path .\SecretsManager.ps1), [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { $_.Message }
    exit 1
}
```

Confirm the script returns the expected version:

```powershell
.\SecretsManager.ps1 -Version
```

## Stage Changes

Stage only the files required for the release.

Do not stage local project environment files unless the release explicitly requires them.

In normal releases, do not stage:

```text
env.json
```

Example:

```powershell
git add SecretsManager.ps1 README.md Secrets-Agent.MD Version.MD
```

Adjust the staged file list to match the actual changes.

## Commit

Create a commit with a message that describes the changes made.

Example:

```powershell
git commit -m "Release 1.0.1"
```

For feature releases, the commit message may include the main change:

```powershell
git commit -m "Release 1.0.1 with updated agent guidance"
```

## Tag

Create an annotated tag using only the release version.

Example:

```powershell
git tag -a 1.0.1 -m "Release 1.0.1"
```

## Push

Push the branch:

```powershell
git push origin main
```

Push the release tag:

```powershell
git push origin 1.0.1
```

## Final Check

Confirm the working tree is clean or only contains intentionally untracked local files:

```powershell
git status --short
```

Confirm the tag points at the release commit:

```powershell
git tag --points-at HEAD
```
