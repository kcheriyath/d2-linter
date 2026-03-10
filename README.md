# D2 Linter Action

GitHub Action that lints [D2](https://d2lang.com) declarative diagram files using the official [d2](https://github.com/terrastruct/d2) formatter and parser.

By default the action validates **syntax only** (no file modifications). Optionally it can enforce canonical D2 formatting.

## Features

- ✅ Validates D2 syntax — catches parse errors before they reach your diagrams
- ✅ Optional formatting enforcement (`check_format: "true"`)
- ✅ Supports a static file list (e.g. only changed files) or path-based discovery
- ✅ Configurable exit behaviour (`fail_on_error`)
- ✅ Minimal Docker image (`debian:bookworm-slim`, non-root user, no extra packages)
- ✅ Pinned d2 version with SHA-256 checksum verification

## Usage

### Lint all D2 files on every push

```yaml
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    name: D2 lint
    steps:
      - uses: actions/checkout@v4
      - name: d2linter
        uses: kcheriyath/d2-linter@v0.1.0
```

### Lint a specific directory

```yaml
      - name: d2linter
        uses: kcheriyath/d2-linter@v0.1.0
        with:
          find_path: "./docs/diagrams"
          find_pattern: "*.d2"
```

### Lint only changed D2 files (with masesgroup/retrieve-changed-files)

```yaml
      - uses: actions/checkout@v4

      - name: Get changed files
        uses: masesgroup/retrieve-changed-files@v3
        id: changed_files

      - name: d2linter
        uses: kcheriyath/d2-linter@v0.1.0
        with:
          file_list: ${{ steps.changed_files.outputs.all }}
```

### Enforce canonical formatting as well as syntax

```yaml
      - name: d2linter
        uses: kcheriyath/d2-linter@v0.1.0
        with:
          check_format: "true"
```

### Warn on errors but never fail the build

```yaml
      - name: d2linter
        uses: kcheriyath/d2-linter@v0.1.0
        with:
          fail_on_error: "false"
```

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `file_list` | No | — | Space/comma-delimited list of D2 files to lint. When set, `find_path` and `find_pattern` are ignored. |
| `find_path` | No | `.` | Directory to search for D2 files, relative to the project root. |
| `find_pattern` | No | `*.d2` | Filename pattern used with `find`. |
| `check_format` | No | `false` | Set to `true` to also enforce D2 canonical formatting (`d2 fmt --check`). |
| `extra_params` | No | — | Extra flags forwarded to `d2 fmt`. |
| `verbose` | No | `true` | Set to `false` to suppress informational output and only show errors. |
| `fail_on_error` | No | `true` | Set to `false` to allow the action to pass even when lint errors are found. |

## Lint modes

| `check_format` | What is checked |
|---|---|
| `false` (default) | **Syntax only** — the file can be parsed without errors. File content is never modified. |
| `true` | **Syntax + formatting** — equivalent to `d2 fmt --check`. Fails if the file is not in canonical D2 format. |

## Security

This action is built with a minimal attack surface:

- Base image is **`debian:bookworm-slim`** (pinned version, not `:latest`).
- The d2 binary is downloaded with **SHA-256 checksum verification**.
- The container runs as a **non-root user** (`linter`).
- `curl` and other build-time tools are removed from the final image.
- The action only **reads** your D2 files — it never writes to the workspace.

## Examples

See the [`examples/`](./examples) directory for sample valid and invalid D2 files.

## License

[MIT](./LICENSE)