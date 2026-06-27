# Dev Secrets Manager Agent Guide

This file defines the required agent workflow for installing and updating `DevSecretsManagerPs` inside a containing repository.

## Required Location

`DevSecretsManagerPs` must always be installed as a Git submodule in the containing repository.

Required path:

```text
Tools/DevSecretsManagerPs
```

Do not install the tool in another folder. Keeping the path stable lets scripts, agents, and project documentation reference the same location in every repository.

## Step 1: Add Or Update The Submodule

From the root of the containing repository, check whether the submodule already exists at:

```text
Tools/DevSecretsManagerPs
```

If it does not exist, add it with:

```powershell
git submodule add https://github.com/Satancito/DevSecretsManagerPs.git Tools/DevSecretsManagerPs
```

If it already exists as a submodule at that path, do not add it again.

After adding it, or when it already exists, synchronize, initialize, and update the submodule:

```powershell
git submodule sync --recursive Tools/DevSecretsManagerPs
git submodule update --init --recursive Tools/DevSecretsManagerPs
git submodule update --remote --recursive Tools/DevSecretsManagerPs
```

## Step 2: Copy This Agent Guide

Copy this file from the submodule to the root of the containing repository:

```text
Tools/DevSecretsManagerPs/Agent-DevSecretsManagerPs.MD -> Agent-DevSecretsManagerPs.MD
```

The root copy gives agents a single, predictable, repository-local instruction file.

## Step 3: Stage Only When There Are Changes

Stage the copied guide and the submodule only when there are real changes.

There are real changes when:

- The submodule was added for the first time.
- The submodule revision changed after synchronization or update.
- The copied `Agent-DevSecretsManagerPs.MD` changed because the submodule has a newer version of this file.

When there are real changes, stage the submodule and the copied guide:

```powershell
git add Tools/DevSecretsManagerPs Agent-DevSecretsManagerPs.MD
```

If the submodule was added for the first time, also stage `.gitmodules`:

```powershell
git add .gitmodules Tools/DevSecretsManagerPs Agent-DevSecretsManagerPs.MD
```

If there are no real changes after synchronization and update, do not stage the submodule or the copied guide.

## Step 4: Commit With A Clear Message

When changes were staged, create a commit with a message that mentions both the submodule and the agent guide.

For a first-time install:

```powershell
git commit -m "Add DevSecretsManagerPs submodule and agent guide"
```

For an update:

```powershell
git commit -m "Update DevSecretsManagerPs submodule and agent guide"
```

Do not create a commit when there were no real changes.

## Step 5: Read The Tool README

After the submodule is installed or updated, read the tool README to learn how to use the tool:

```text
Tools/DevSecretsManagerPs/README.md
```

The README is the source of truth for tool usage, available commands, flags, behavior, return values, and safety rules.

Do not duplicate command usage in this file.

## Project Environment

Each containing repository must have its own `env.json` for this tool.

Required location:

```text
Tools/DevSecretsManagerPs/env.json
```

The `env.json` file identifies the secrets file used by that containing repository. It must not be shared across unrelated projects unless they intentionally need to use the same development secret set.

Before using the tool for project secrets, initialize the current containing repository by following the README.

Secret values are not stored in the containing repository. The actual secrets file is stored in the current user's home directory:

```text
<HOME>/.devsecretsmanager/<guid>.json
```

The `<guid>` value comes from:

```text
Tools/DevSecretsManagerPs/env.json
```

## Agent Rules

When working in a repository that uses this tool:

- Treat `Tools/DevSecretsManagerPs` as the required submodule path.
- Add the submodule only when it does not already exist at the required path.
- If the submodule already exists, only synchronize, initialize, and update it.
- Copy `Agent-DevSecretsManagerPs.MD` to the containing repository root.
- Stage and commit the copied guide and submodule only when there are real changes.
- Use a commit message that mentions both the submodule and the agent guide.
- Read `Tools/DevSecretsManagerPs/README.md` before using the tool.
- Do not manually create or edit secret files unless the task explicitly requires manual repair.
- Do not store actual secret values in the containing repository.
- Keep each repository's `env.json` scoped to that repository.

