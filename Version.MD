# Version Release Workflow

This file describes the release flow agents must follow when the user asks to release a new `SecretsManager.ps1` version.

These instructions apply only to the `DevSecretsManagerPs` repository itself. They are not instructions for consuming repositories that install this repository as a tool.

This repository includes both release workflow documents:

- `Version.MD`: English release workflow.
- `Version.es-ES.MD`: Spanish release workflow.

Both files are part of this repository and must stay aligned when the release workflow changes.

This repository also includes both README files:

- `README.md`: English usage documentation.
- `README.es-ES.MD`: Spanish usage documentation.

Both README files are part of this repository and must stay aligned when usage, installation, commands, or behavior change.

## Version Source

The script version is stored in `SecretsManager.ps1`:

```powershell
$ScriptVersion = "2.0.1"
```

The version command must return this value as a JSON string:

```powershell
.\SecretsManager.ps1 -Version
```

Expected output shape:

```json
"2.0.1"
```

## Decide The Next Version

When the user asks to release a new version, inspect the history since the latest tag:

```powershell
git tag --sort=-creatordate
git log --oneline <last-tag>..HEAD
```

If there is no previous tag, inspect the relevant repository history:

```powershell
git log --oneline
```

Choose the next version using SemVer:

- `MAJOR`: incompatible command behavior, output contract breaks, renamed or removed flags, incompatible secrets file format changes, incompatible `env.json` format changes, destructive behavior changes, or migration requirements.
- `MINOR`: new commands, new parameters, new supported workflows, or meaningful backward-compatible feature additions.
- `PATCH`: bug fixes, documentation corrections, tests, help text updates, release guide fixes, or internal refactors that do not change public behavior.

If the right bump is ambiguous, explain the options and recommend one before proceeding.

## Release Order

Follow this order for every release:

- Check `git status --short` and identify unrelated user changes.
- Do not revert unrelated changes.
- Do not clear, reset, overwrite, stage, or commit local secrets except for the explicit `-Clear -Force` step below.
- Before committing or tagging a release, run `.\SecretsManager.ps1 -Clear -Force` to clear the local secrets file used by this repository.
- Validate that tracked files do not contain real secret values, tokens, credentials, private URLs, or connection strings.
- Determine which changes are included in the release.
- Choose the next `X.Y.Z` version using SemVer.
- Create one or more technical Conventional Commits for the actual changes, staging only the files that belong to each commit.
- Prepare the final version bump by updating every file that must mention `X.Y.Z`, including `SecretsManager.ps1`, `CHANGELOG.md`, `README.md`, `README.es-ES.MD`, and any other affected documentation.
- Stage only the final version bump files.
- Create the final release commit with `chore(release): bump DevSecretsManagerPs to X.Y.Z`.
- Confirm there are no pending tracked changes after the final release commit.
- Create the `X.Y.Z` tag.
- Push the branch.
- Push the `X.Y.Z` tag.
- Run the final checks.

The tag must point to the final release commit, and the final release commit must leave the repository with no pending tracked changes.

## Prepare The Release

Before creating commits:

- Update command documentation when behavior changes.
- Keep the `README.md` section that explains how to install this tool in a consumer project with `ToolsManagerPs`.
- Update `Version.MD` and `Version.es-ES.MD` if the release workflow changed.
- Run PowerShell parser validation for `SecretsManager.ps1`.
- Run relevant smoke checks in a controlled temporary environment so local repo secrets are not exposed or modified beyond the required `-Clear -Force` release step.

Secrets are machine-local values managed by this repository's script. They are not release artifacts, they are not part of the Git working tree, and they can vary per developer or build machine.

## Documentation Requirements

For every release:

- `README.md` and `README.es-ES.MD` must show valid commands.
- `README.md` and `README.es-ES.MD` must document command flags, required parameters, behavior, return values, and safety rules.
- `README.md` and `README.es-ES.MD` must keep the consumer-project installation flow that uses `ToolsManagerPs`.
- `README.md` and `README.es-ES.MD` must show the current version if they reference a version.
- `CHANGELOG.md` must contain a section for the released version using the repository format `## X.Y.Z`, without a date suffix.
- `Version.MD` and `Version.es-ES.MD` must remain repository-local and must describe the current release workflow.

Keep `README.md` and `README.es-ES.MD` as the source of truth for script usage, installation, and available commands.

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

Confirm usage/help still renders:

```powershell
.\SecretsManager.ps1
.\SecretsManager.ps1 -Help
```

Do not run commands against real local secrets as part of normal release validation unless the release explicitly requires it.

If behavior for commands that read or mutate secrets changed, validate those commands only in a controlled temporary environment with dummy secrets:

```powershell
.\SecretsManager.ps1 -Init
.\SecretsManager.ps1 -Add Example -Value "dummy"
.\SecretsManager.ps1 -Get Example
.\SecretsManager.ps1 -Exists Example
.\SecretsManager.ps1 -List
.\SecretsManager.ps1 -Remove Example -Force
.\SecretsManager.ps1 -Clear -Force
.\SecretsManager.ps1 -Regenerate -Force
```

## Conventional Commits

Create commits using Conventional Commits. Use a short subject and a detailed body when the change needs context for future changelog generation.

Example:

```powershell
git commit -m "docs(release): update release guide" -m "Update the internal release guide for DevSecretsManagerPs with the current validation, documentation, staging, tagging, and push workflow. This change does not alter script behavior."
```

Use commit types according to the release impact:

- `feat` for backward-compatible features.
- `fix` or `perf` for patch-level runtime changes.
- `docs` for documentation-only changes.
- `test` for test-only changes.
- `chore`, `refactor`, `style`, `build`, or `ci` for maintenance changes that do not affect runtime behavior.
- Add `!` or `BREAKING CHANGE:` only for breaking changes.

Do not include personal data, secrets, credentials, tokens, certificates, private URLs, or connection strings in commit messages.

Use one or more technical conventional commits before the final release commit. Stage only the files that belong to each commit.

Do not include the final version bump in a technical commit unless the entire release consists only of the version bump. The version bump belongs in the final release commit.

Examples for the current repository:

```powershell
git status --short
git add SecretsManager.ps1
git commit -m "fix(secrets): repair init regeneration"
git add README.md
git commit -m "docs(readme): document ToolsManagerPs installation"
git add README.es-ES.MD
git commit -m "docs(readme): add Spanish usage documentation"
git add Version.MD
git commit -m "docs(release): align release workflow"
git add Version.es-ES.MD
git commit -m "docs(release): add Spanish release workflow"
```

Commit messages must be detailed enough to understand what changed from the Git history.

## Final Release Commit

After feature, fix, test, and documentation commits are complete, create one final release commit:

```text
chore(release): bump DevSecretsManagerPs to X.Y.Z
```

Before this commit:

- Ensure `SecretsManager.ps1` has `$ScriptVersion = "X.Y.Z"`.
- Ensure `README.md` and `README.es-ES.MD` reference `X.Y.Z` where relevant.
- Ensure `CHANGELOG.md` moved the released items from `Unreleased` into `## X.Y.Z`.
- Ensure no secret files, consumer project state, local environment files, or generated output are staged.

Stage only the final bump files:

```powershell
git add SecretsManager.ps1 README.md README.es-ES.MD CHANGELOG.md Version.MD Version.es-ES.MD
```

Create the final release commit:

```powershell
git commit -m "chore(release): bump DevSecretsManagerPs to X.Y.Z"
```

After this commit, there must be no pending tracked changes. If anything remains pending, fix it with another appropriate commit before tagging.

In normal releases, do not stage:

```text
env.json
.devsecretsmanager
Tools
Project.json
```

## Tag

Create a Git tag using only the SemVer release version.

```powershell
git tag X.Y.Z
```

Example:

```powershell
git tag 2.0.0
```

Do not prefix the tag with `v`.

Use an annotated tag only if the user or repository policy asks for one. The tag name still must not use `v`:

```powershell
git tag -a X.Y.Z -m "Release X.Y.Z"
```

## Push

Push the branch:

```powershell
git push origin main
```

Push the release tag:

```powershell
git push origin X.Y.Z
```

If the branch is not `main`, verify the target branch with the user or repository policy before pushing.

## Final Check

Confirm the working tree is clean or only contains intentionally untracked local files:

```powershell
git status --short
```

Confirm the tag points at the release commit:

```powershell
git tag --points-at HEAD
```

Confirm the tag exists on the remote:

```powershell
git ls-remote --tags origin X.Y.Z
```

## Safety Notes

- Do not stage local project environment files, secret files, generated output, or temporary test artifacts.
- Do not stage consumer-generated `.gitmodules`, `Tools/`, `Project.json`, or project build output unless the user explicitly asks for that repository state.
- Do not run destructive cleanup unless explicitly requested, except the required release `.\SecretsManager.ps1 -Clear -Force` step.
- Do not create tags before the final release commit exists.
- If tests or validation require network access or external services, ask for approval before running them.

## Future Improvement

A more automated release flow could later:

- Read the latest tag.
- Calculate the next SemVer version from conventional commits.
- Update `SecretsManager.ps1`, `README.md`, `README.es-ES.MD`, and `CHANGELOG.md`.
- Run safe validations.
- Create the release commit and tag.

Until that exists, agents should follow this manual release workflow.
