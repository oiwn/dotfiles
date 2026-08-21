# Pi Agent Setup (global, dotfiles-managed)

State: not started

Scope: global pi configuration for the dotfiles project (terminal, tmux, `~/.pi/agent/`, `~/.agents/`). Not tied to any single code project.

## Purpose

Bootstrap a fresh pi session with the full agent workflow: three working modes (research / plan / implement), web fetch, Rust LSP tooling, and crate-matched skills. This spec carries the research done on 2025-08-19 so it does not need to be redone.

## Current State (verified 2025-08-19)

- **pi CLI:** installed at `/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent` (homebrew npm global).
- **Theme:** custom `matrix` at `~/.pi/agent/themes/matrix.json` (dark, `thinkingText: #5faf5f`). Alternatives: `hideThinkingBlock: true`, Ctrl+T/Ctrl+O collapse.
- **tmux italics (fixed):** panes must get `TERM=tmux-256color` (has `sitm`/`ritm`). tmux.conf (home-manager symlink) sets:
  ```
  set -g default-terminal "tmux-256color"
  set-option -sa terminal-overrides ',xterm-256color:RGB'
  set -as terminal-overrides ',*:sitm=\E[3m,ritm=\E[23m'
  ```
  Gotcha: a running tmux server predating a conf change keeps old options — `tmux source-file ~/.tmux.conf` (or full server restart) after edits. Verify with `printf 'normal \e[3mitalic\e[23m normal\n'` in a fresh pane.
- **MCP:** `pi-mcp-adapter` extension handles `.mcp.json` (project root, `mcpServers` entries, `"type": "http"` + `"url"`). Supports `"headers"` with `${VAR}` env interpolation (keeps API keys out of dotfiles/repos). OAuth tokens go to the OS keychain.
- **Skills:** pi discovers `~/.agents/skills/`, `.pi/agent/skills/`, and project `.agents/skills/` (agent-neutral locations shared with Codex/Copilot/Gemini/OpenCode). `specdev` skill already lives at `~/.agents/skills/specdev/`.

^^^ this is not related to our current business, this already done
&&& Acknowledged — the whole *Current State* section is already-completed setup (pi install, matrix theme, tmux italics fix, MCP adapter, skills discovery; verified 2025-08-19), not task work. Kept purely as reference for the tmux-restart gotcha and keychain/env-interpolation details. Active work lives in `specs/ctx.md`; where this spec's Target/Plan diverges from ctx.md, ctx.md wins.

## Target Capabilities

### 1. Three modes via one extension (`~/.pi/agent/extensions/modes.ts` or reuse)

`/mode` command + statusline indicator; mode injected into model context on switch; persisted across sessions (`appendEntry` + `session_start`).

| Tool | research | plan | implement |
|---|---|---|---|
| read | allow | allow | allow |
| bash | read-only allowlist | read-only allowlist | allow |
| edit/write | block | `specs/**` only | allow |
| web fetch / LSP nav | allow | allow | allow |
| LSP fixAll/rename | block | block | allow |

- Bash read-only allowlist (heuristic guardrail, **not** a sandbox — `sh -c` can evade): `rg`, `find`, `fd`, `cat`, `head`, `ls`, `git log|diff|show|status`, `cargo metadata|tree`, `pageinfo`, `curl` (GET).
- Built on `pi.on("tool_call")` → `{ block: true, reason }`, `pi.registerCommand()`, `ctx.ui.select`, footer/statusline widget.

### 2. Web fetch

- **Primary:** `pageinfo` (crate `pageinfo-rs` v0.2.5, GPL-3.0, https://github.com/oiwn/pageinfo-rs) — CLI, structured LLM-friendly page output, no API key. Call via bash.
- **Fallback (needs GLM Coding Plan key):** z.ai remote MCP servers, Bearer auth via env interpolation:
  ```json
  "web-search": { "type": "http", "url": "https://api.z.ai/api/mcp/web_search_prime/mcp",
                  "headers": { "Authorization": "Bearer ${ZAI_API_KEY}" } },
  "web-reader": { "type": "http", "url": "https://api.z.ai/api/mcp/web_reader/mcp",
                  "headers": { "Authorization": "Bearer ${ZAI_API_KEY}" } }
  ```
  Tools: `webSearchPrime` (search), `webReader` (full page: title, content, metadata, links). Docs: https://docs.z.ai/devpack/mcp/search-mcp-server, .../reader-mcp-server

### 3. Rust LSP

- **Candidate:** `@narumitw/pi-lsp` (v0.49.4) — language-agnostic, JSON routes per file extension, diagnostics + code actions + workspace edits, starts servers only on tool calls. `pi install npm:@narumitw/pi-lsp`, then a `rust-analyzer` route (`include: ["**/*.rs"]`, `rootMarkers: ["Cargo.toml"]`).
- **Alternatives:** `pi-lsp` (v0.1.7, declarative `~/.pi/agent/lsp.json`, hashed-trust for project configs), `pi-lens`, `pi-lsp-lite` (diagnostics-only).
- **Permission-system reuse candidate:** `@gotgenes/pi-permission-system` (v26.3.0) — inspect before hand-writing the modes gate; may cover most of it.

### 4. Symposium (crate-matched Rust skills)

Symposium (https://github.com/symposium-dev/symposium, https://symposium.dev/about.html) is an agent-agnostic installer, not an agent: `cargo agents init` adapts one config to each person's agent. pi is not in its supported list, but Codex CLI / Copilot / Gemini / OpenCode use `.agents/skills/` — the same dirs pi discovers.

```bash
cargo binstall symposium
cargo agents init   # pick an agent whose skill dir is .agents/skills/ (e.g. Codex CLI; OpenCode is skills-only)
cargo agents sync   # per project; auto-sync on hooks is the default
```

Only skills reach pi (hooks/MCP registration target other agents' formats). Also mentioned: `rtk` project for token reduction — unreviewed.

## Plan

- [ ] Inspect `@gotgenes/pi-permission-system` and `@narumitw/pi-lsp` sources/config in detail; decide build-vs-reuse for the modes gate.
- [ ] Implement/configure modes (research/plan/implement) with the gate table above; add `/mode` + statusline indicator.
- [ ] Add z.ai fallback MCP entries (global or per-project `.mcp.json`) with `${ZAI_API_KEY}`; export key in shell env.
- [ ] Install + configure LSP extension with a rust-analyzer route; verify diagnostics/navigation in a Rust project.
- [ ] Install symposium, sync, verify crate-matched skills appear in pi skill discovery.
- [ ] End-to-end verify: fresh pi session in a Rust repo — italics render, mode gates behave per table, pageinfo + webReader work, LSP diagnostics return.

## Decisions

- Bash in research/plan: **read-only allowlist** (search/consume only), accepted as heuristic, not a sandbox.
- Plan-mode edits: **specs/** only** — composes with the specdev workflow.
- Web fetch: **pageinfo primary, z.ai fallback** (future: additional fallbacks).
- Placement: everything global under `~/.pi/agent/` (extensions, settings, themes) + tmux/home-manager in dotfiles; per-project only `.mcp.json` and trust decisions.
