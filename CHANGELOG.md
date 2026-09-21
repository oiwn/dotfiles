# Changelog

## 2026-09-21 — one-line status footer extension

- **New `/footer` extension** (`dots/pi/agent/extensions/footer/index.ts`, default on): replaces pi's multi-segment footer with one line — `~/code/dotfiles · 🔍 research · ↑1.4M ↓108k · 17.2%/1.0M · 172k · glm-5.3`. Left block: abbreviated cwd, mode in a fixed-width slot right after cwd (visibleWidth-padded — mode switches never move later segments), cumulative in/out tokens (session entries incl. compaction usage blocks — counts survive compaction), context % via `ctx.getContextUsage()` with pi's >70/>90 colorization. Right block: absolute context tokens + model id. Spacer line after the status keeps it off the editor; `?`/`?/window` right after compaction. Dropped: R/W cache tokens, CH%, $, `(auto)`. `/footer` toggles custom ↔ default; live updates via `onBranchChange` + `model_select`/`agent_end` re-renders.
- **modes**: footer status is now always-on — `⚙ implement` (dim) where it previously cleared the status; research/plan unchanged.
- Default-footer stats decoded and documented in `specs/overview.md` operational notes (`R` = cache-read, not reasoning; `CH%` = latest-request cache-hit rate).

## 2026-09-20 — vars.nix de-secreted: committed, staging ceremony removed

- **Policy flip**: `vars.nix` is now a normal tracked, committed file. Rationale: its values (hostName/systemUser/gitName/gitEmail) have been public in pushed history since `2b9805b` and in commit metadata regardless; the gitignore + `git add -f --intent-to-add` ceremony protected nothing not already exposed while costing recurring flake-eval breakage (flag dropped after pull/rebase/stash rounds → eval fails / dangling symlinks).
- **Removed**: `vars.nix` from `.gitignore`; the `just stage` recipe (staging is plain `git add -A` now — justfile keeps `scan`); the i-t-a gotchas from `specs/overview.md`.
- **Docs swept**: README (bootstrap minus the i-t-a step, renumbered; stack table; architecture; design decisions), AGENTS.md (gotchas: staging is plain git), `.agents/skills/dotfiles` (golden rules).
- **Kept**: the new-files-under-`dots/` gotcha (`git add -N` before a switch — flake reads the repo through git; independent of vars.nix); `vars.nix.example` as a forker template; `git pull --rebase --autostash` advice (now for dirty indexes generally).
- Post-flip: `git commit -a`, GUI "stage all", and bare `git add .` are all safe — the whole class of vars.nix leak vectors is gone.

## 2026-09-20 — pi ↔ specdev integration tightened · /healthcheck · pi_setup.md retired

- **modes extension became a directory** (`dots/pi/agent/extensions/modes/{index,readonly}.ts`): specs-aware banners per mode — `specs/` detected once at `session_start`, every mode injects a specs/plain variant each turn (tag prefix unchanged, context filter still drops stale banners). specdev in research is **awareness, not obligation** (consult specs when useful); research/plan name the web stack — search via web-search-prime MCP, read pages via **pginf preferred** (web-reader MCP fallback, curl GET last), used when the task needs it; rust-CLI preference voiced (rg/fd/bat/eza/duf). Plain plan banner suggests `specdev init`.
- **allowlist extracted to `readonly.ts`** (data-driven entries + `CLI_INSTRUMENTS` — single source of truth shared with healthcheck; rust-first per installed provenance: rg brew, fd/bat/eza/duf/tokei/jq nix, specdev/pginf cargo). Read-only `specdev status|scan|list|--version|--help` now allowed in research/plan (`init`/`skill install` stay blocked); corpus → 132 tests.
- **new `/healthcheck` extension** (`dots/pi/agent/extensions/healthcheck/index.ts`): overlay inventory of the workflow instruments — pi + CLI instruments via `--version` (✗ missing / ⚠ no `--version` support), specdev skill frontmatter, mcp.json servers + auth.json `.zai.key` presence (value never printed), MCP tool registration via `getAllTools()`, keybindings/theme/modes files. Binaries spawned via child_process, independent of the bash gate.
- **local skill `.agents/skills/dotfiles/`** — repo workflow for agents (just stage, vars.nix intent-to-add, user-run darwin-rebuild, flake-update policy, Nix GC guidance + rollback tradeoff). `justfile` `stage` recipe fixed (spaces → tab — `just stage` was erroring; just only accepts tabs).
- **wiring** (`home/dotfiles.nix`): modes dir + healthcheck entries; first switch to this layout must be followed by `rm ~/.pi/agent/extensions/modes.ts` (stale pre-layout symlink would double-register `/mode`).
- **`specs/pi_setup.md` retired** — implemented in full (modes, MCP web tools, theme, tmux italics, global specdev skill; verified 2026-09-20). Durable leftovers routed: tmux italics gotcha → `specs/overview.md` Operational notes; LSP + symposium candidates → `specs/ideas.md`. File reduced to a stub; deletion by the user.
- **healthcheck MCP-name fix** (same day, fresh-session check): `getAllTools()` exposes server proxies (`mcp__web_reader`), not internal tool names (`web-reader_webReader`) — the reader pattern `/webreader/i` never matched (false ⚠; search matched by luck). Patterns now tolerate both schemes (`web[-_]?…`); web-reader verified end-to-end.
- **healthcheck overlay overflow fix** (same day, user report): tokei's version line (`tokei 14.0.0 compiled with serialization support: …`, 66 chars) ran past the 64-char detail column. Version output now strips the redundant tool-name prefix, and the detail column is clipped visibleWidth-aware with an ellipsis — long output from any instrument can no longer break the box.

## 2026-08-29 — pi modes extension (written + hardened) · zellij adopted · tmux mouse

- **modes extension shipped and hardened** (`dots/pi/agent/extensions/modes.ts`, wired via `home.file`): `/mode` + Shift+Tab / Ctrl+Alt+M cycle (thinking-cycle remapped to `ctrl+alt+t`), research/plan/implement gates (tool swap, plan-mode `specs/**` path gate, bash read-only allowlist), per-mode banners via `before_agent_start`, session persistence. Hardening after live false positives: quote/escape-aware `maskShellQuoting()` (quoted `"a\|b"`/`'a; b'`/escaped pipes are literals now; `$(…)`/backticks stay rejected even inside double quotes); find/`date`/curl write-flag checks moved quote-tolerant onto the raw string (closes `find "-exec"` evasion); block-reason copy fixed; 122-test corpus in `modes.test.ts` (repo-only, `node --test` — never symlinked, pi never loads it).
- **zellij adopted** (tmux stays primary): `zellij` added to `brews` — nixpkgs dropped zellij entirely (verified at our pin and master); "tmux only. zellij out of scope" amended in `specs/overview.md` + `README.md`. `dots/zellij.kdl` rewritten from a stale pre-nix dump to a minimal delta config: `catppuccin-mocha` (matches WezTerm), `pane_frames false`, `default_layout "compact"`, pbcopy clipboard, `default_mode "locked"`, and the tmux-style `` ` `` prefix as a **mode hop** (`` ` 1..9`` jumps 1-based like `base-index 1`, `` ` c/n/p/d ``, double-backtick literal) — zellij has no key sequences, caught by `zellij setup --check` before shipping. Wired via `xdg.configFile."zellij/config.kdl"`; live dump preserved as `config.kdl.hm-bak`; verified in a fresh session.
- **tmux mouse**: `set -g mouse on` added to `dots/.tmux.conf` (conf never set it → wheel never scrolled pane history; `set-clipboard on` + WezTerm OSC52 already covered copy). Applied live via `tmux source-file` — no server restart.
- **Gotchas documented** (`specs/overview.md` Operational notes): commit/rebase/stash rounds can silently drop `vars.nix`'s intent-to-add flag — check `git ls-files -s vars.nix` (expect empty blob `e69de29…`) after any commit round; re-register with `git add -f --intent-to-add vars.nix`.
- **Routed out:** tmuxp-parity work → zelp v2 revival (separate project, github.com/oiwn/zelp; transit prompt delivered 2026-08-29). Approve-edits mode idea → `specs/ideas.md`.

## 2026-08-13 — stable channel pin + activation fixes

- `flake.nix`: pinned `nixpkgs`→`nixos-26.05`, `nix-darwin`→`nix-darwin-26.05`, `home-manager`→`release-26.05` (were `unstable`/`master`/default). Stable channel ⇒ `nix flake update` stays cheap (cache hits), no more ~1 GB closure re-download per update.
- `hosts/macbook.nix`: `homebrew.onActivation.upgrade = false` (was `true`) — switches no longer `brew upgrade` (which re-downloaded multi-GB casks every switch); `autoUpdate` stays `true`.
- `dots/wezterm.lua`: added `Cmd+Shift+Left/Right` → `MoveTabRelative(-1/1)`.
- Docs: standardized the switch command to the installed `darwin-rebuild`; `AGENTS.md` splits "apply changes" from "bump inputs".

## 2026-08-13 — starship/tabiew moved to Homebrew (resolves cctools linker regression)

- macOS Tahoe + nixpkgs `cctools` linker regression (nixpkgs#540450, fixed by PR#540463) blocked local from-source builds of `starship`/`tabiew`.
- `starship`/`tabiew` → `brews` (bottles bypass nix build); dropped `programs.starship.enable`; fish now sources `starship init fish` via `if type -q starship`.

## (earlier) — ripgrep ownership consolidation (Issue #5)

- brew `rg` (hard dep of `codex`/`opencode`) was shadowing the nix `rg`. Let brew own `rg`: removed from `home/packages.nix`, added to `brews`.
