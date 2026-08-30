# Changelog

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
