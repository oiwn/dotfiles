# pi setup

The [pi coding agent](https://pi.dev) is managed in three layers. This file is
the reference for the runtime-package layer and how the layers fit together.

## Three layers

| Layer | Where | How it deploys |
| --- | --- | --- |
| Nix-managed config | `dots/pi/agent/` — extensions (`modes/`, `healthcheck/`, `footer/`), `keybindings.json`, `mcp.json` | home-manager symlinks → `~/.pi/agent/`, applied by `sudo darwin-rebuild switch` |
| Imperative-converged packages | `Justfile` → `just pi-setup` (catalog below) | `pi install` writes `~/.pi/agent/settings.json` + `~/.pi/agent/npm/` |
| Runtime state | `~/.pi/agent/settings.json`, `auth.json`, `sessions/` | Written by pi at runtime — deliberately not nix-linked |

Rule of thumb: dotfile content lives in `dots/pi/agent/` (declarative, needs a
switch); npm-installable extensions/skills live in the `pi-setup` recipe
(imperative, one command, no switch).

## Runtime packages (`just pi-setup`)

| Package | Purpose | Provenance |
| --- | --- | --- |
| `pi-mcp-adapter` | MCP client adapter — loads the z.ai MCP servers from `mcp.json` (web-search-prime, web-reader) | nicopreme |
| `pi-subagents` | Subagent delegation, scripted workflows, council mode, supervisor channel | nicopreme |
| `pi-lens` | LSP diagnostics/navigation, linters/formatters, ast-grep, read guards | apmantza |
| `cc-safety-net` | Blocks destructive commands + secret-file access (parser-based; Standard preset) | kenryu42 — installed via `npx cc-safety-net@latest install` |
| `@narumitw/pi-usage` | `/usage` quota display — for Z.AI: GLM Coding Plan 5h/weekly windows + monthly MCP allowance + plan level | narumiruna/pi-extensions, ~daily releases |
| `@juicesharp/rpiv-ask-user-question` | `ask_user_question` tool — tabbed dialog with typed options + descriptions instead of the model guessing | juicesharp/rpiv-mono, zero deps, no network |
| `@juicesharp/rpiv-todo` | `todo` tool + `/todos` + live task panel above the editor; state replayed from the conversation (survives `/reload` + compaction), session-isolated from subagents | juicesharp/rpiv-mono, heavily tested |

## Operating commands

```sh
just pi-setup              # converge: install everything above (idempotent)
pi update --extensions     # refresh all packages to latest
pi remove npm:<pkg>        # uninstall one
pi -e npm:<pkg>            # ephemeral trial, no settings mutation
```

After installing or removing, restart pi (fresh session) to load changes.

## Notes

- **`settings.json` stays mutable** — it carries runtime fields
  (`lastChangelogVersion`, theme, the `packages` list pi writes). Only
  `mcp.json` and `keybindings.json` are nix-symlinked; nix-linking
  `settings.json` would make every `pi install` fight the store.
- **pi-usage × z.ai**: quota shows via the `/usage` command only (menu — no
  statusline item for zai). It queries Z.AI's own coding-plugin endpoint
  (`/api/monitor/usage/quota/limit`) with the key from `auth.json`, sent only
  to official origins; mismatch → fail closed.
- **rpiv configs**: optional and read-only —
  `~/.config/rpiv-ask-user-question/config.json` and
  `~/.config/rpiv-todo/config.json` (collapse keys, guidance prompts, panel
  size). The extensions never write them.
- **Keybindings**: rpiv defaults are `ctrl+]` (collapse question dialog) and
  `ctrl+shift+t` (collapse todo panel); our only custom binding is
  `ctrl+alt+t` (thinking cycle) — no collisions.
- **Version floors**: Node ≥ 22 (rpiv packages) and pi ≥ 0.81 (pi-usage
  origin-validated auth) — both satisfied on this machine.
