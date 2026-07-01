# Changelog

## Unreleased

## 2.0.1

- Added `Version.es-ES.MD` as the Spanish repository-local release workflow and documented both release workflow files as part of the project.
- Added `README.es-ES.MD` as the Spanish usage documentation and documented both README files as part of the project.

## 2.0.0

- Removed the reusable agent instruction file because `ToolsManagerPs` manages tool installation and updates in consumer projects.
- Updated documentation to use the `ToolsManagerPs` installation flow.
- Changed `-List` to return the secrets file content as raw JSON and removed the separate `-Json` command from operational documentation.
- Updated `-Init` so invalid `env.json` states are regenerated automatically.
- Added a yellow warning when `-Init` creates or regenerates `env.json`.
- Changed command pipeline output to JSON objects or JSON content, except `-Edit`, which only opens the editor and returns no pipeline value.
- Changed `-Init` to return only the full `guid.json` secrets file path as a JSON string.
- Changed `-Get` to return only the selected secret value as JSON, or `null` when the secret does not exist.
- Changed `-Exists` to return only a JSON boolean.
- Changed `-Add` to return only a JSON boolean.
- Changed `-Remove` to return only a JSON boolean.
- Changed `-Clear` to return only a JSON boolean.
- Changed `-Regenerate` to return only a JSON boolean while keeping interactive confirmation unless `-Force` is used.
- Changed `-Version` to return only the version as a JSON string.
- Changed `-Edit` to return no pipeline value.
