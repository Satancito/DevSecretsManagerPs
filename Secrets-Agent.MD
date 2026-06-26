# Dev Secrets Manager Agent Guide

This file defines the required workflow for installing `DevSecretsManagerPs` inside a containing repository.

## Required Location

`DevSecretsManagerPs` must always be installed as a Git submodule in the containing repository.

Required path:

```text
Tools/DevSecretManagerPs
```

Do not install the tool in another folder. Keeping the path stable lets scripts, agents, and project documentation reference the same location in every repository.

## Add The Submodule

From the root of the containing repository, add the submodule with:

```powershell
git submodule add https://github.com/Satancito/DevSecretsManagerPs.git Tools/DevSecretManagerPs
```

After adding the submodule, initialize it:

```powershell
git submodule sync --recursive Tools/DevSecretManagerPs
git submodule update --init --recursive Tools/DevSecretManagerPs
```

Commit the submodule reference from the containing repository:

```powershell
git add .gitmodules Tools/DevSecretManagerPs
git commit -m "Add DevSecretsManagerPs submodule"
```

## Update The Submodule

The containing repository must update this tool through Git submodule commands.

From the root of the containing repository, run:

```powershell
git submodule sync --recursive Tools/DevSecretManagerPs
git submodule update --init --recursive Tools/DevSecretManagerPs
git submodule update --remote --recursive Tools/DevSecretManagerPs
```

Only stage and commit when the submodule revision changes, meaning the containing repository shows `Tools/DevSecretManagerPs` as modified after the update.

When the submodule revision changes, also copy the latest version of this guide to the root of the containing repository before staging.

Then stage and commit only the submodule reference and the copied guide:

```powershell
git add Tools/DevSecretManagerPs Secrets-Agent.MD
git commit -m "Update DevSecretsManagerPs submodule"
```

If the submodule revision does not change, do not stage or commit the submodule or the copied guide.

## Copy This Guide

This file must be copied to the root of the containing repository where the tool is installed.

Recommended target path in the containing repository:

```text
Secrets-Agent.MD
```

The copied file is intended to give agents a stable, repository-local instruction source for installing and updating the secrets manager.

During updates, stage and commit the copied guide only when the submodule has a new revision. Do not stage or commit the copied guide when the submodule did not change.

## Tool Documentation

Tool usage, behavior, and available commands are documented in the tool README:

```text
Tools/DevSecretManagerPs/README.md
```

Do not duplicate command usage in this file. Treat the tool README as the source of truth for how to use `SecretsManager.ps1`.

## Project Environment File

Each containing repository must have its own `env.json` for this tool.

Required location:

```text
Tools/DevSecretManagerPs/env.json
```

The `env.json` file identifies the secrets file used by that containing repository. It must not be shared across unrelated projects unless they intentionally need to use the same development secret set.

Initialize this file by following the tool README.

## Secret Storage Location

Secret values are not stored in the containing repository.

The actual secrets file is stored in the current user's home directory:

```text
<HOME>/.devsecretsmanager/<guid>.json
```

The `<guid>` value comes from:

```text
Tools/DevSecretManagerPs/env.json
```

## Agent Rules

When working in a repository that uses this tool:

- Treat `Tools/DevSecretManagerPs` as the required submodule path.
- Use submodule commands to install or update the tool.
- Read `Tools/DevSecretManagerPs/README.md` for command usage and available flags.
- Do not manually create or edit secret files unless the task explicitly requires manual repair.
- Do not store actual secret values in the containing repository.
- Keep each repository's `env.json` scoped to that repository.
