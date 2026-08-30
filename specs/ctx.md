# Current Task Context: Pi harness setup (modes, ~/.pi sync, z.ai MCP, pageinfo)
State: in progress (modes extension done + hardened; remaining: live re-probe, z.ai MCP, pginf, e2e verify)

## Plan
- [ ] `/reload` in the live session + re-probe the exact commands that false-positived pre-hardening (`grep -n "a\|b" f` class must pass now; `&&` chains, `2>/dev/null`, `echo "$(rm)"` must still block). First probe also settles which gate generation the running session holds — store copy is current, in-memory extension may predate it. Folds in `specs/checklist.md` tests 3 & 5.
- [ ] Add z.ai `web-search` / `web-reader` to `~/.pi/agent/mcp.json` (pi-specific layer), `headers` via `${ZAI_API_KEY}`; wire `dots/pi/agent/mcp.json` → `home.file` once it gains content.
- [ ] Add `pginf` (pageinfo-rs) via local flake build (`rustPlatform.buildRustPackage` + `fetchCrate`); not in nixpkgs, no upstream releases — compile once per version bump.
- [ ] End-to-end verify: fresh pi session — mode gates behave, banner/status render, resume keeps mode (checklist test 6), MCP tools reachable.
- [ ] Scope call: rust LSP (`@narumitw/pi-lsp`) + Symposium crate-matched skills — decided: later pass.

## Findings
- **`~/.pi/agent` split:** config (settings/themes/extensions/prompts/mcp.json) vs state (auth/trust/sessions/npm/mcp-cache) → symlink individual files, never the dir; mcp-adapter never rewrites source `mcp.json` → symlink-safe for the z.ai step.
- **pageinfo-rs:** Alex's own crate; upstream packaging deferred to him. Binary is `pginf`; value = `wreq` browser-impersonating fetches (blocks that stop curl); author ships a skill in-repo.
- **Order + deferrals (user):** z.ai `mcp.json` → `pginf` → e2e verify; rust LSP + Symposium later pass. tmuxp-parity moved OUT to the zelp repo (v2 revival; transit prompt delivered 2026-08-29 — zelp session starts from oiwn/zelp with that brief).
- **Iteration-loop gotcha:** `~/.pi/agent/extensions/modes.ts` symlinks to the **nix store copy** — repo edits reach the live session only after a user-run switch; `/reload` then hot-reloads into memory. Loop: patch → `node --test` corpus → switch → `/reload` → re-probe.

## Context
Mode table: research = read/grep/find/ls + gated bash, edit/write disabled; plan = all tools + `edit`/`write` path-gated to `specs/**`; implement = all tools, no bash gate. checklist.md: tests 1–2 resolved; 3 & 5 fold into the re-probe above; 4 — specs-allowed side verified, block-side unprobed (fold into re-probe); 6 → e2e. Known accepted gate gaps (heuristic, not sandbox): quoted args hiding non-token-list flags (`date "-s"`-class); awk/sed scriptability (`system()`, internal redirects).

## Next
`/reload` here → run the re-probe commands (settles gate generation) → z.ai `mcp.json` (needs `ZAI_API_KEY` present in shell env) → `pginf` flake build → e2e verify.
