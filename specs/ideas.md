# Ideas

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
