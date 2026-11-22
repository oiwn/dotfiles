# Current Task Context: herdr migration apply — specdev ws, live herdr config, font rotation

State: edits done; **waiting on user apply** (exact commands printed in session 2026-11-22).

## Context

- Multiplexer is **herdr** (brew); workspace = gitignored root `.ws.ron` (specdev tree format, single opencode agent) via `specdev ws up|down|status`. Needs **specdev ≥ 0.5.2** (fish `agent_pane_busy` fix; installed binary is 0.5.1).
- herdr `~/.config/herdr/config.toml` is **live, not nix-managed**; `prefix = "backtick"` set (reload: `herdr server reload-config`).
- opencode pinned to `zai-coding-plan/glm-5.3-flash` via gitignored root `opencode.json` (per machine).
- WezTerm rotates Nerd Font stacks (`CMD+ALT+F` picker / `CMD+ALT+SHIFT+F` cycle; **JetBrainsMono default**); JetBrainsMono/FiraCode NF casks install **ad-hoc** via brew.
- zellij stays (secondary multiplexer); `dotfiles` CLI + rmux fully out of the config.

## Next

User runs the apply block from the session: commit A (pending dotfiles-CLI fixes + skills-gitignore rework), commit B (this migration), `git push` (nix has unpushed `a3235f7`), specdev cargo install, font casks, `sudo darwin-rebuild switch …`, `brew uninstall rmux`, stale-dir cleanup, `herdr server reload-config`, then `specdev ws up` in this repo as the smoke test.
