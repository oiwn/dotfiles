# Current Task Context: Tighten specdev × pi integration (banners, allowlist, healthcheck)
State: in progress
## Plan
- [x] `modes.ts`: specs-aware banners — `specs/` existence checked once at `session_start` (cwd is fixed per session; only the banner *text* is re-injected each turn — that's the delivery mechanism, not re-detection). All three modes get specs/plain variants. Research (specs): be **aware** of the specdev skill — consult `specs/overview.md` / `specs/ctx.md` when useful, not an obligation; web when needed — search via `web-search-prime` MCP, read pages via **pginf preferred** (`web-reader` MCP fallback, `curl` GET last); prefer rust CLIs (rg, fd, bat, eza, duf). Plan (specs): current specdev text + "verify chosen approach online if needed". Plain variants: plan/plain suggests `specdev init`. Keep `[MODE: x]` tag prefix so the context filter works.

^^^ what do you mean by "per turn"? and no loading specdev is not an obligation, bur research should be aware of the skill and that is can search in internet.
&&& Clarified: detection runs once at session_start; per-turn is only how the banner is delivered. Specdev is framed as awareness — "consult specs when useful", never a mandated startup read. The banner states the agent *can* search the internet (tools listed) and should when the task needs external knowledge.

- [x] Restructure to directory extension `extensions/modes/` (`index.ts` + `readonly.ts`) — pi auto-loads `extensions/*.ts` and `extensions/*/index.ts` only, so a loose helper `.ts` beside `modes.ts` would be misloaded as an extension. `readonly.ts`: data-driven read-only command set, rust-first per installed inventory (nix: fd, bat, eza, duf, btm, tokei, jless…; brew: rg; cargo: specdev, pginf), POSIX fallbacks kept, regexes built from the data. Add read-only `specdev` subcommands (`status`, `scan`, `list`, `--version`, `--help`; `init` stays blocked). Corpus cases in `modes.test.ts` (import path updated); `node --test`.

^^^ need to figure out proper way to do it, maybe separate module which givs set of commands, we prefer rust version of commands look what installed via nix
&&& Resolved: separate module = `readonly.ts` inside a `modes/` directory extension (pi's supported multi-file layout). Rust preference = the module's data leads with the rust tools actually installed (nix `home.packages` + brew `ripgrep`); POSIX names stay allowed as fallback since models emit them naturally.

- [x] New `extensions/healthcheck/index.ts` — `/healthcheck`: quick inventory of available tools + versions in one overlay. Checks: pi / specdev / pginf binaries + `--version` (graceful ⚠ if a crate lacks the flag); rust CLI set from `readonly.ts` data; specdev skill `SKILL.md`; `mcp.json` servers + `auth.json` `.zai.key` (never printed); MCP registration via `pi.getAllTools()`; `keybindings.json` symlink + theme file. Rendered as `ui.custom` overlay table.

^^^ we need to be able to quickly look at what tools available and versions, right
&&& Yes — framed as exactly that: one overlay = what's available + its version. ✗ = missing/unhealthy; ⚠ = present but degraded (e.g. no --version support).

- [x] `home/dotfiles.nix`: symlink `~/.pi/agent/extensions/healthcheck.ts` (same pattern as modes.ts; no test file).

^^^ right
&&& Acknowledged.

- [x] Housekeeping: `CHANGELOG.md` ← dated retirement block (what shipped from the pi-setup effort); clean `specs/pi_setup.md` down to a stub pointing at the CHANGELOG entry — **deletion is yours**; tmux italics gotcha → `specs/overview.md`; LSP + symposium → `specs/ideas.md`.

^^^ move to changelog, cleanup pi_stup.md i'll delete it after by myself.f
&&& Understood: I never delete the file — CHANGELOG gets the history, `pi_setup.md` becomes a stub, you remove it yourself.

- [x] New local skill `.agents/skills/dotfiles/SKILL.md` — how to work in this repo: stage with `just stage` (never bare `git add .`); vars.nix = gitignored + `git add -f --intent-to-add` (flake eval needs it, content never tracked); apply loop = user-run `sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)`; `nix flake update` deliberate only; Nix GC guidance (user-run, e.g. `nix-collect-garbage --delete-older-than 14d`; costs old-generation rollbacks; store ≈ 46G today). Also fix `justfile` `stage` recipe indentation (spaces → tab) so `just stage` works.
- [x] Verify + hand over
- [x] Verify + hand over: `node --test` green; `git add -N` new files; user runs `darwin-rebuild switch`; fresh-session checks — `/healthcheck` green, banners adapt (this repo vs non-specs dir), `specdev status` allowed in research mode, local skill listed, `just stage` works.
- [x] Follow-up (found in fresh-session check): healthcheck MCP name matching — reader pattern `/webreader/i` never matched the registered proxy `mcp__web_reader` (search matched only by luck). Fixed both patterns to tolerate proxy vs flat naming (`web[-_]?…`); web-reader verified end-to-end.
- [x] Follow-up (user report): healthcheck overlay overflow — tokei's long version line ran past the box border (66 chars vs 64 available). Fixed: strip redundant tool-name prefix from version output + visibleWidth-aware `clip()` with ellipsis on the detail column.

^^^ let's add the skill which will instruct agent how to work with this repo, local ".agents" is ok. We just "just stage" to stage everything except "vars.nix" vars.nix should not be under the git, but darwin rebuild require it. Also add instruction about darwin-rebuild and i hard something about nix GC, how many disk space nix got already?
&&& Added as a plan step below. Disk answer: /nix/store = 46G on a 461G volume (94G free, 80% used) — old generations are the reclaimable mass; the skill documents the user-run GC commands and the rollback tradeoff. Bonus find while verifying: `justfile` stage recipe is space-indented and just only accepts tabs → `just stage` errors today; fix included in the step.

## Findings
- Verified live: skill global at `~/.agents/skills/specdev/`; both crates on PATH (`~/.cargo/bin/{specdev,pginf}`); MCP web tools healthy (`web_search_prime` strict schema — param `search_query`; reader tool name `web-reader_webReader`); modes.ts symlink current.
- User decisions: pginf > web-reader for page reading; healthcheck = pi extension (not `specdev doctor`); overlay report; "search if required" tone.
- pi has no built-in doctor; extensions cannot invoke MCP tools (registration check only) but can spawn binaries via child_process (bypasses bash gate).
- `specdev --version` / `pginf --version` output shape unverified (gate blocked) — healthcheck must degrade gracefully; user can add flags to crates.
- Provenance split: rg comes from brew (`hosts/macbook.nix`); fd/bat/eza/duf/btm/tokei/jless from nix `home.packages`; specdev/pginf from cargo — captured in `readonly.ts` data.
- pi multi-file extension layout = `extensions/*/index.ts`; loose `.ts` helpers get misloaded. No built-in doctor.
- /nix/store = 46G (461G volume, 94G free). `justfile` stage recipe is space-indented → `just stage` errors today (tabs required).
## Context
- Files: `dots/pi/agent/extensions/modes/` (index.ts + readonly.ts, replaces modes.ts) + `modes.test.ts`, new `dots/pi/agent/extensions/healthcheck/index.ts`, `home/dotfiles.nix`, `justfile`, new `.agents/skills/dotfiles/SKILL.md`, `specs/overview.md`, `specs/ideas.md`, `CHANGELOG.md`, `specs/pi_setup.md` (stub only; user deletes).
- New files must be git-visible before switch (`git add -N dots/pi/agent/extensions/healthcheck.ts`) or home-manager installs dangling symlinks.
- Apply loop is user-run: `sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostname)`.
## Next
De-secret flip executed (2026-09-20, second CHANGELOG block): `just stage` removed, vars.nix committed-going-forward, docs swept. Open user decisions: fate of `vars.nix.example` (kept as template for now); archive this task (all boxes checked) + delete `specs/pi_setup.md` stub when confirmed. Handover: `git add -A && git commit && git push` (no switch needed — nothing under `dots/` changed).
