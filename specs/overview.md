# Project Overview

## Stack

| Layer | Tool | Why this one |
|---|---|---|
| Package manager | **Lix** | Drop-in Nix fork, flakes on by default, cleaner uninstall, friendlier community fork — same CLI (`nix`) as stock Nix. |
| macOS config | **nix-darwin** | Declarative `system.defaults` (Dock, Finder, key repeat), declarative Homebrew (`brews`/`casks`/fonts), LaunchAgents — turns System Settings + brew into code. |
| User packages + dotfiles | **home-manager** | Per-user `home.packages`, `programs.*` modules (git, gh, gpg, fish, starship), and `home.file`/`xdg.configFile` symlinks from `dots/`. |
| Flakes | **Nix flakes** | `flake.nix` declares inputs; `flake.lock` is **gitignored** — each machine resolves fresh (similar dev env, not bit-identical). |
| Per-machine values | **`vars.nix`** | Committed (de-secreted 2026-09-20). Holds `hostName` / `systemUser` / `gitName` / `gitEmail`; threaded into modules via `specialArgs` / `extraSpecialArgs`. |

## Architecture

```
dotfiles/
  flake.nix           # inputs + darwinConfigurations.${vars.hostName}, threads vars + home-manager wiring
  vars.nix.example    # committed template (placeholder fields)
  vars.nix            # committed, per machine
  hosts/
    macbook.nix       # nix-darwin: system.stateVersion, primaryUser, system.defaults,
                      # homebrew brews/casks/fonts, programs.fish.enable, system packages
  home/
    default.nix       # home-manager entry; derives username/homeDirectory from vars.systemUser
    packages.nix      # home.packages — Nix CLI tools
    dotfiles.nix      # home.file / xdg.configFile — symlinks into dots/
    terminal.nix      # programs.fish (incl. brew shellenv sourcing) + programs.starship
    dev.nix           # programs.git (vars.gitName/gitEmail), programs.gh, programs.gpg
    apps.nix          # placeholder; brews/casks declared in hosts/macbook.nix
  dots/               # raw dotfiles, source of truth, symlinked by home-manager
    .tmux.conf, helix.toml, languages.toml, init.lua, init.vim,
    .editorconfig, hammerspoon.lua, wezterm.lua
    pi/agent/         # extensions/modes/{index,readonly}.ts, extensions/healthcheck/index.ts,
                      # keybindings.json, mcp.json (z.ai MCP tools)
```

## Data flow

```
vars.nix ─┐
          ├─► flake.nix (specialArgs / extraSpecialArgs)
          │       │
          │       ├─► hosts/macbook.nix ─► nix-darwin ─► system defaults + Homebrew
          │       │
          │       └─► home/*.nix       ─► home-manager ─► user packages + dotfile symlinks
          │
dots/ ────┴─► home.file / xdg.configFile (read-only symlinks into ~/.config and ~)
```

Single command applies it all (hostname must match `vars.hostName`):

```sh
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)
```

## Runtime layout — where installed software lives

| Path | Source |
|---|---|
| `/opt/homebrew/bin/*` | brews + cask CLI shims (`brew`, `codex`, `claude`, `mosh`, `opencode`, …) |
| `/Applications/*.app` | casks (WezTerm, Slack, GIMP, …) |
| `~/.nix-profile/bin/*` | `home.packages` (ripgrep, fd, helix, neovim, fish, starship, …) |
| `/run/current-system/sw/bin/*` | `environment.systemPackages` (coreutils, nmap) |

Fish picks up `/opt/homebrew/bin` because `home/terminal.nix` sources `brew shellenv` in `interactiveShellInit` — the brew installer only patches zsh's profile, not fish's.

## Design decisions

- **Reproducibility is "similar," not "identical."** `flake.lock` is gitignored so each machine resolves fresh. Inputs are pinned to the `nixos-26.05` / `nix-darwin-26.05` / `home-manager release-26.05` release branches (not `unstable`), so `nix flake update` moves within a frozen channel → cache hits, tiny downloads between updates.
- **Rust toolchain via `rustup`** (installed by Nix). Toolchains/components managed by rustup for flexible target/nightly switching. Rust CLI tools (ripgrep, bat, fd, eza, …) come from Nix as prebuilt binaries.
- **Shell**: fish + starship. zsh + oh-my-zsh + p10k removed.
- **Python**: uv (via Nix). conda/miniforge removed.
- **Terminal**: WezTerm (cask), config symlinked from `dots/wezterm.lua`.
- **Multiplexer**: tmux primary; zellij via brew (nixpkgs dropped zellij entirely; brew tracks releases — `brew upgrade zellij` for freshness).
- **Fast-moving CLIs** as Homebrew brews for daily freshness: `anomalyco/tap/opencode-v2` (moved off the plain `opencode` formula 2026-09-20 — same binary name, the two formulas fight over `/opt/homebrew/bin/opencode`), `gemini-cli`, `prek`, `charmbracelet/tap/crush`. Anthropic and OpenAI ship their CLIs as Homebrew **casks**: `claude-code`, `codex`.
- **mosh via Homebrew, not nixpkgs** (hit 2026-09-20): the nix mosh bundle ships its own OpenSSH build that rejects `UseKeychain` from `~/.ssh/config` (and doesn't even honor `IgnoreUnknown`); brew mosh invokes `ssh` from PATH — Apple's `/usr/bin/ssh`, which parses the config fine. Keep it in `hosts/macbook.nix` `brews`, not `environment.systemPackages`. Fallback if ssh resolution ever goes odd again: `mosh --ssh=/usr/bin/ssh <host>`.
- **GUI apps**: Homebrew casks managed by nix-darwin; Gatekeeper kept on (no `no_quarantine`).
- **`homebrew.onActivation.cleanup = "none"`**: ad-hoc `brew install` survives switches; remove a line from this repo and run `brew uninstall` manually when you really want it gone.
- **`homebrew.onActivation.upgrade = false`** (with `autoUpdate = true`): switches install only *missing* brews/casks and keep the formula index fresh, but never `brew upgrade` — so a dotfile-only `switch` is seconds, not a multi-GB cask re-download. Update packages explicitly with `brew upgrade`.
- **`home-manager.backupFileExtension = "hm-bak"`**: when home-manager wants to write a file you already have, it renames the existing one to `<file>.hm-bak` instead of refusing to activate.
- **Dotfiles** as raw files in `dots/`, symlinked by home-manager — no inline Nix-generated configs, so files stay editable and portable across non-Nix environments.
- **Personal values in `vars.nix` are committed** (de-secreted 2026-09-20): identity values were already public in pushed history (since `2b9805b`) and commit metadata, so the gitignored + intent-to-add ceremony was retired — it cost recurring flake-eval breakage (dropped flag after pull/rebase/stash) and protected nothing not already exposed. Forks edit `vars.nix` directly; `vars.nix.example` stays as a template.
- **pi agent: config managed, state live** — `dots/pi/agent/` holds only config (`extensions/modes/` (index + readonly), `extensions/healthcheck/`, `keybindings.json`, `mcp.json`), symlinked by home-manager. `mcp.json` is symlink-safe: pi-mcp-adapter reads but never rewrites the source. `settings.json`/`auth.json` are deliberately NOT managed (pi writes them at runtime). The z.ai MCP tools (`web-search-prime`, `web-reader` servers) authenticate via an adapter command-secret — `"bearerToken": "!jq -r .zai.key ~/.pi/agent/auth.json"` under `auth: "bearer"` — so the API key lives *only* in `auth.json`: zero env vars, zero key copies in git/store (`jq` resolves via pi's inherited PATH).

## Operational notes

- **Sudo required**: nix-darwin activation now runs as root. Every `darwin-rebuild switch` needs `sudo`.
- **New files must be git-visible before a switch**: flake eval reads the repo through git — tracked files (worktree content) plus intent-to-add entries; plain untracked files are invisible. Symptom: home-manager installs **dangling symlinks** with no build error (hit with untracked `dots/pi/` — extension/keybindings silently never appeared in `~/.pi/agent`). Fix: `git add -N <path>` before `darwin-rebuild switch`; sanity-check with `nix eval --no-warn-dirty --raw '.#<host>.config.home-manager.users.<user>.home.file."<path>".source'` and `test -f` the printed store path.
- **Hostname binding**: `flake.nix` defines exactly `darwinConfigurations.${vars.hostName}`. A new machine needs its own `vars.nix` with the right `hostName` (matching `scutil --get LocalHostName`) and its own `systemUser` (matching `whoami`).
- **z.ai API surface** (hit 2026-09-20): GLM Coding Plan credits cover only the **MCP** endpoints — `api.z.ai/api/mcp/{web_search_prime,web_reader}/mcp`. The REST tools (`/api/paas/v4/*`, even under the coding base `/api/coding/paas/v4/*`) are open-platform pay-per-use → plan keys get 1113/429 there. Docs names can lie: tool is `web_search_prime`, not `webSearchPrime`; schemas are strict (`additionalProperties: false` — no `count` param). **Don't infer endpoint URLs from sibling services**: a wrong-but-existing endpoint (`/mcp/web_search/mcp` — legacy, initializes fine) hides the mistake until the first billable call. Verify new MCP wiring with one real `tools/call` before declaring done.
- **tmux config changes need a live-server nudge**: a running tmux server predating a conf change keeps the old options — `tmux source-file ~/.tmux.conf` (or a full server restart) after edits; verify italics in a *fresh* pane with `printf 'normal \e[3mitalic\e[23m normal\n'`. Panes must get `TERM=tmux-256color` (has `sitm`/`ritm`); `dots/.tmux.conf` sets `default-terminal "tmux-256color"` plus `terminal-overrides` for RGB and sitm/ritm. (Routed here from the retired `specs/pi_setup.md`.)
- **pi default footer stats decoded** (2026-09-21, for the one-line `/footer` extension): `↑`/`↓` = cumulative input/output tokens; `R`/`W` = cache **read/write** tokens (not reasoning); `CH%` = latest-request cache-hit rate = `cacheRead/(input + cacheRead + cacheWrite)`; `$` = session cost; `pct%/window` = context usage via `getContextUsage()` (compaction-aware, null right after compaction); `(auto)` = auto-compaction mode. Context % colorized >70% warning / >90% error.
