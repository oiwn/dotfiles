# Current Task Context: Adopt 3 pi extensions + pi_setup.md
State: planned (agreed in research; awaiting implement)
Predecessor: pi-subagents/pi-lens/cc-safety-net task — packages installed & in live use; its pending docs round is folded into this one.

## Plan
- [x] `Justfile` — extend `pi-setup` recipe with 3 idempotent lines (tab-indented, bare npm specs, consistent with existing style):
  `pi install npm:@narumitw/pi-usage` · `pi install npm:@juicesharp/rpiv-ask-user-question` · `pi install npm:@juicesharp/rpiv-todo`
- [x] `pi_setup.md` (new, repo root — user decision: NOT in specs/) — the pi setup reference:
  - 3-layer architecture: nix-managed (`dots/pi/agent/` → extensions/modes/healthcheck/footer, keybindings.json, mcp.json, deployed by switch) · imperative-converged (`just pi-setup` — the declarative package list) · runtime-mutable (`settings.json`/`auth.json`, written by pi, never nix-linked)
  - package catalog: 7 entries (existing pi-mcp-adapter, pi-subagents, pi-lens, cc-safety-net + the 3 new) — purpose, one-line provenance
  - operating commands: `just pi-setup` (install/converge) · `pi update --extensions` (refresh) · `pi -e npm:<pkg>` (ephemeral trial) · `pi remove npm:<pkg>` (uninstall)
  - notes: zai adapter is `/usage`-menu-only (no statusline); rpiv XDG configs (`~/.config/rpiv-*/config.json`, read-only, optional); Node ≥22 requirement (satisfied, v26.9.0)
- [x] `README.md` — bootstrap gains one step after chsh: `just pi-setup` (converge pi runtime packages); "Managing packages" table gains row: pi runtime package → Justfile `pi-setup` recipe (see `pi_setup.md`)
- [x] `specs/overview.md` — surgical addendum to the "pi agent: config managed, state live" bullet: runtime packages converged by `just pi-setup`, catalogued in `pi_setup.md` (closes predecessor's docs item in the user-chosen direction — no package list duplicated in specs)
- [x] `CHANGELOG.md` — one block (2026-09-21): 3 extensions adopted (usage/quota for zai; structured ask-user dialog; live todo overlay); `pi-setup` recipe → 7 packages; `pi_setup.md` introduced; README/overview pointers. Implicitly closes predecessor's changelog debt (its recipe + healthcheck/readonly edits shipped earlier).
- [x] Hand over (user-run, NO darwin-rebuild — nothing nix-managed changes): `just pi-setup` → restart pi (new session loads packages).
- [ ] Verify (fresh session): `/usage` shows Z.AI GLM quota windows (5h/weekly/MCP allowance); a decision-bearing prompt triggers `ask_user_question` dialog (tabbed, typed options); multi-step task shows todo panel, survives `/reload`; composition clean — modes gates, footer, `/subagents-doctor`, `/healthcheck` all unaffected.
- [ ] Close out: ctx.md compressed to done-state.

## Findings
- Research (2026-09-21): full survey of pi ecosystem (pi.dev gallery, 5.3k packages) + OMP identified as separate Rust pi-fork (not installable here). Shortlist vetted to 4; pi-delete-session skipped (user call: too green, trivially replaceable by hand).
- Vetted: pi-usage v0.54.0 (narumiruna/pi-extensions; ~daily releases; paranoid credential handling — in-memory only, origin-validated, fail-closed; zai support queries official `/api/monitor/usage/quota/limit`) · rpiv-ask-user-question & rpiv-todo v2.10.1 lockstep (juicesharp/rpiv-mono; 16/14 dependents; zero runtime deps, no network, no disk writes; todo has 12 test files incl. session-isolation; state replayed from conversation — survives /reload+compaction).
- Collision checks: keybindings (ours `ctrl+alt+t` vs theirs `ctrl+shift+t`/`ctrl]`) ✓ · todo panel above editor vs our footer below ✓ · todo session-isolation vs pi-subagents children ✓ · Node 22+ vs v26.9.0 ✓ · pi ≥0.81 for pi-usage vs 0.86.1 ✓.
- Decisions: global/user scope · direct install via recipe (idempotent; `pi remove` trivial — no `pi -e` detour) · docs home `pi_setup.md` at root, specs untouched otherwise.

## Risks
- zai quota endpoint is undocumented (used by Z.AI's own plugin) — shape may drift; pi-usage updates ~daily.
- GLM-5.3 eagerness to call the new tools unproven — `guidance.*` knobs in the rpiv XDG configs if tuning needed.
- rpiv-todo overlay × footer co-rendering untested live (different screen regions; expected fine).

## Context
- Files: `Justfile`, `pi_setup.md` (new), `README.md`, `specs/overview.md`, `CHANGELOG.md`, this file. No `dots/` changes → no `git add -N` ceremony, no switch.
- Apply: user runs `just pi-setup` after edits; staging plain `git add -A`.

## Next
Implement on `/mode implement`.
