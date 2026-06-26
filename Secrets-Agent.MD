# Dev Secrets Manager Agent Guide

This file defines the required workflow for installing `DevSecretsManagerPs` inside a containing repository.

## Required Location

`DevSecretsManagerPs` must always be installed as a Git submodule in the containing repository.

Required path:

```text
Tools/DevSecretManagerPs
```

Do not install the tool in another folder. Keeping the path stable lets scripts, agents, and project documentation reference the same location in every repository.

## Add Or Update The Submodule

From the root of the containing repository, first check whether the submodule already exists at:

```text
Tools/DevSecretManagerPs
```

If it does not exist, add it with:

```powershell
git submodule add https://github.com/Satancito/DevSecretsManagerPs.git Tools/DevSecretManagerPs
```

After adding the submodule, or when the submodule already exists in the containing repository, always synchronize, initialize, and update it with:

```powershell
git submodule sync --recursive Tools/DevSecretManagerPs
git submodule update --init --recursive Tools/DevSecretManagerPs
git submodule update --remote --recursive Tools/DevSecretManagerPs
```

When the submodule was added for the first time, copy this guide to the containing repository root before staging:

```text
Tools/DevSecretManagerPs/Secrets-Agent.MD -> Secrets-Agent.MD
```

Then commit the submodule reference and the copied guide from the containing repository:

```powershell
git add .gitmodules Tools/DevSecretManagerPs Secrets-Agent.MD
git commit -m "Add DevSecretsManagerPs submodule and agent guide"
```

## Update The Submodule

When the submodule already exists in the containing repository, do not add it again. Update it from the root of the containing repository with:

```powershell
git submodule sync --recursive Tools/DevSecretManagerPs
git submodule update --init --recursive Tools/DevSecretManagerPs
git submodule update --remote --recursive Tools/DevSecretManagerPs
```

Only stage and commit when the submodule revision changes, meaning the containing repository shows `Tools/DevSecretManagerPs` as modified after the update.

When the submodule revision changes, also copy the latest version of this guide to the root of the containing repository before staging.

Then stage and commit only the submodule reference and the copied guide. The commit message must mention both the submodule update and the agent guide update:

```powershell
git add Tools/DevSecretManagerPs Secrets-Agent.MD
git commit -m "Update DevSecretsManagerPs submodule and agent guide"
```

If the submodule revision does not change, do not stage or commit the submodule or the copied guide.

## Copy This Guide

This file must exist in the root of the containing repository where the tool is installed.

Recommended target path in the containing repository:

```text
Secrets-Agent.MD
```

The copied file should stay updated in the containing repository root so agents can invoke a single, predictable, repository-local instruction file without searching inside the submodule.

During updates, copy this guide to the containing repository root only when the submodule has a new revision. This avoids unnecessary file copies and commits.

When the submodule has a new revision, stage and commit both:

```text
Tools/DevSecretManagerPs
Secrets-Agent.MD
```

Use a commit message that mentions both the submodule and the copied guide.

Do not stage or commit the copied guide when the submodule did not change.

## Tool Documentation

Tool usage, behavior, and available commands are documented in the tool README:

```text
Tools/DevSecretManagerPs/README.md
```

Do not duplicate command usage in this file. Treat the tool README as the source of truth for how to use `SecretsManager.ps1`.

## Before Running The Tool

Before running the tool from a containing repository, always synchronize, initialize, and update the submodule from the root of the containing repository:

```powershell
git submodule sync --recursive Tools/DevSecretManagerPs
git submodule update --init --recursive Tools/DevSecretManagerPs
git submodule update --remote --recursive Tools/DevSecretManagerPs
```

After the submodule is synchronized and updated, check whether the containing repository shows `Tools/DevSecretManagerPs` as modified.

If the submodule revision changed, copy the latest `Secrets-Agent.MD` from the submodule to the root of the containing repository:

```text
Tools/DevSecretManagerPs/Secrets-Agent.MD -> Secrets-Agent.MD
```

If the submodule revision did not change, do not copy `Secrets-Agent.MD`.

After this check, initialize the secrets environment for the current containing repository:

```powershell
.\Tools\DevSecretManagerPs\SecretsManager.ps1 -Init
```

Only after these steps should the tool be executed for other operations by following `Tools/DevSecretManagerPs/README.md`.

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
- Keep an updated copy of `Secrets-Agent.MD` in the containing repository root.
- Before running the tool, synchronize, initialize, and update the submodule.
- Copy `Secrets-Agent.MD` to the containing repository root only when the submodule revision changed.
- When the submodule was added or its revision changed, stage and commit both `Tools/DevSecretManagerPs` and the root `Secrets-Agent.MD`, using a message that mentions both.
- Run `-Init` for the current project before other tool operations.
- Read `Tools/DevSecretManagerPs/README.md` for command usage and available flags.
- Do not manually create or edit secret files unless the task explicitly requires manual repair.
- Do not store actual secret values in the containing repository.
- Keep each repository's `env.json` scoped to that repository.
