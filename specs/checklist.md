Test checklist:
 1. /mode → picker appears → pick research → footer shows 🔍 research, notification confirms

^^^ no picker
&&& diagnosed: `~/.pi/agent/extensions/modes.ts` was a **dangling symlink** — `dots/pi/` was untracked, so flake eval's git-filtered copy of `dots/` had no `pi/` and home-manager silently linked into nothing (no build error; extension simply never loaded). Fixed: `git add -N dots/pi` (same mechanism as `vars.nix`); `nix eval` of the `home.file` source now resolves. Pending re-switch, then re-test.

 2. Shift+Tab → cycles to 🧭 plan → again → mode clears (implement)

^^^ no cycles
&&& same root cause — `keybindings.json` symlink also dangled, so pi fell back to defaults (Shift+Tab kept cycling thinking level). Same intent-to-add fix; pending re-switch.

 3. In research: ask something that tempts an edit, e.g. "add a comment to README.md" → the edit call should be blocked with the research-mode reason
 4. In plan: ask it to touch README.md → blocked with the specs-only reason; ask it to update specs/ctx.md → allowed
 5. ls > /tmp/x style bash in research → blocked; git log --oneline | head -3 → allowed
 6. Exit and pi --resume (pick session) → mode persists, footer shows it

 Caveats: if ~/.pi/agent/keybindings.json or extensions/ already exists as real files, home-manager renames them to *.hm-bak on first switch — that's the configured safety net, nothing
 is lost. If Shift+Tab still cycles thinking level after the switch, /reload once inside pi; if the extension misbehaves, /reload also hot-reloads it.

 Tell me how the checklist goes (or paste any weirdness) and I'll fix — then we move to mcp.json + pginf per plan.
