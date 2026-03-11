# D2 Linter Action

GitHub Action that lints [D2](https://d2lang.com) declarative diagram files using the official [d2](https://github.com/terrastruct/d2) toolchain.

By default the action runs **all three checks** on every matching file: format, validate, and render. Each check can be individually disabled.

## Features

- ✅ **Format check** — `d2 fmt --check` enforces canonical D2 formatting (never modifies workspace files)
- ✅ **Syntax validation** — `d2 validate` catches parse errors
- ✅ **Render check** — `d2 <file> /dev/null` verifies the diagram renders without errors
- ✅ All three checks run by default; individually disable with `format=false`, `validate=false`, or `render=false`
- ✅ Supports a static file list (e.g. only changed files) or path-based discovery
- ✅ Configurable exit behaviour (`fail_on_error`)
- ✅ Minimal Docker image (`debian:bookworm-slim`, non-root user, no extra packages)
- ✅ Pinned d2 version with SHA-256 checksum verification

## Usage

### Lint all D2 files on every push (all checks)

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

### Skip the format check (validate + render only)

```yaml
      - name: d2linter
        uses: kcheriyath/d2-linter@v0.1.0
        with:
          format: "false"
```

### Skip the render check (format + validate only)

```yaml
      - name: d2linter
        uses: kcheriyath/d2-linter@v0.1.0
        with:
          render: "false"
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
| `format` | No | `true` | Run `d2 fmt --check` to enforce canonical formatting. Set to `false` to skip. |
| `validate` | No | `true` | Run `d2 validate` to check syntax. Set to `false` to skip. |
| `render` | No | `true` | Run `d2 <file> /dev/null` to verify rendering. Set to `false` to skip. |
| `extra_params` | No | — | Extra flags forwarded to every d2 sub-command. |
| `verbose` | No | `true` | Set to `false` to suppress informational output and only show errors. |
| `fail_on_error` | No | `true` | Set to `false` to allow the action to pass even when errors are found. |

## Checks explained

| Check | Command | What it catches |
|---|---|---|
| `format` | `d2 fmt --check diagram.d2` | Files not in canonical D2 format. Never modifies workspace files. |
| `validate` | `d2 validate diagram.d2` | Syntax / parse errors. |
| `render` | `d2 diagram.d2 /dev/null` | Errors that only surface during rendering (layout, references, etc.). |

## Security

This action is built with a minimal attack surface:

- Base image is **`debian:bookworm-slim`**.
- The d2 binary is downloaded with **SHA-256 checksum verification**.
- The container runs as a **non-root user** (`linter`).
- `curl` and other build-time tools are removed from the final image.
- The action only **reads** your D2 files — it never writes to the workspace.

## Examples

See the [`examples/`](./examples) directory for sample valid and invalid D2 files.

## License

[MIT](./LICENSE)