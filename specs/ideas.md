# Ideas

# Rust LSP extension for pi

Deferred from the retired `specs/pi_setup.md` (never implemented). Candidate:
`@narumitw/pi-lsp` — language-agnostic, JSON routes per file extension,
diagnostics + code actions, starts servers only on tool calls. Setup:
`pi install npm:@narumitw/pi-lsp`, then a `rust-analyzer` route
(`include: ["**/*.rs"]`, `rootMarkers: ["Cargo.toml"]`). Alternatives:
`pi-lsp` (declarative `~/.pi/agent/lsp.json`), `pi-lens`, `pi-lsp-lite`
(diagnostics only). Design note: pi has no built-in LSP; the modes gates
would need LSP navigation allowed in research/plan, fix/rename in implement.

# Symposium (crate-matched skills)

`cargo-agents` binary is installed (`~/.cargo/bin`, 2026-08) but never
configured. Symposium adapts one skill config across agents; pi discovers
the same `.agents/skills/` dirs other agents use — `cargo agents init`
(pick an agent using `.agents/skills/`), then `cargo agents sync` per
project (auto-sync on hooks is the default).

# starship timeout

```
[WARN] - (starship::utils): Executing command "/opt/homebrew/bin/node" timed out.
[WARN] - (starship::utils): You can set command_timeout in your config to a higher value to allow longer-running commands to keep executing.
```

# add AI agents dotfiles

- [ ] claude
- [ ] opencode
- [ ] chatgpt
- [ ] crush

# just bootstrap recipe

- wrap the curl + clone + intent-to-add + switch dance.

# system.stateVersion review

- currently pinned at `7`; bump only after reading `darwin-rebuild changelog`.

# implement-mode approve-edits (Claude Code style)

Deferred until real Pi usage shows it's needed. Decided so far:
- UX: 4-position Shift+Tab cycle — research → plan → implement (auto) → implement (approve).
- Scope: edit/write only; bash stays ungated in implement.
- Preview: the WHOLE change must be visible, not a truncated hunk.
- DIY mechanism: tool_call → ui.confirm/custom + {block, reason}; policy in footer +
  appendEntry persistence; fail-safe block when no UI.

Existing extensions (npm survey 2025-08-19): @gotgenes/pi-permission-system is the
serious one (allow/ask/deny everywhere; Ctrl+O expands prompt to full request — no
rendered diff; heavy config, overlaps modes.ts). @diegopetrucci/pi-permission-gate is
a trivial Yes/No. Nothing ships a rendered-diff approval UI; DIY = ctx.ui.custom()
overlay reusing pi's built-in diff rendering.
