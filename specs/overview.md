# Project Overview

## Stack

| Layer | Tool | Why this one |
|---|---|---|
| Package manager | **Lix** | Drop-in Nix fork, flakes on by default, cleaner uninstall, friendlier community fork — same CLI (`nix`) as stock Nix. |
| macOS config | **nix-darwin** | Declarative `system.defaults` (Dock, Finder, key repeat), declarative Homebrew (`brews`/`casks`/fonts), LaunchAgents — turns System Settings + brew into code. |
| User packages + dotfiles | **home-manager** | Per-user `home.packages`, `programs.*` modules (git, gh, gpg, fish, starship), and `home.file`/`xdg.configFile` symlinks from `dots/`. |
| Flakes | **Nix flakes** | `flake.nix` declares inputs; `flake.lock` is **gitignored** — each machine resolves fresh (similar dev env, not bit-identical). |
| Per-machine values | **`vars.nix`** | Gitignored, registered via `git add -f --intent-to-add` so the flake can see it without staging content. Holds `hostName` / `systemUser` / `gitName` / `gitEmail`; threaded into modules via `specialArgs` / `extraSpecialArgs`. |

## Architecture

```
dotfiles/
  flake.nix           # inputs + darwinConfigurations.${vars.hostName}, threads vars + home-manager wiring
  vars.nix.example    # committed template (placeholder fields)
  vars.nix            # gitignored, intent-to-add, per machine
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
| `/opt/homebrew/bin/*` | brews + cask CLI shims (`brew`, `codex`, `claude`, `opencode`, …) |
| `/Applications/*.app` | casks (WezTerm, Slack, GIMP, …) |
| `~/.nix-profile/bin/*` | `home.packages` (ripgrep, fd, helix, neovim, fish, starship, …) |
| `/run/current-system/sw/bin/*` | `environment.systemPackages` (coreutils, mosh, nmap) |

Fish picks up `/opt/homebrew/bin` because `home/terminal.nix` sources `brew shellenv` in `interactiveShellInit` — the brew installer only patches zsh's profile, not fish's.

## Design decisions

- **Reproducibility is "similar," not "identical."** `flake.lock` is gitignored so each machine resolves fresh. Inputs are pinned to the `nixos-26.05` / `nix-darwin-26.05` / `home-manager release-26.05` release branches (not `unstable`), so `nix flake update` moves within a frozen channel → cache hits, tiny downloads between updates.
- **Rust toolchain via `rustup`** (installed by Nix). Toolchains/components managed by rustup for flexible target/nightly switching. Rust CLI tools (ripgrep, bat, fd, eza, …) come from Nix as prebuilt binaries.
- **Shell**: fish + starship. zsh + oh-my-zsh + p10k removed.
- **Python**: uv (via Nix). conda/miniforge removed.
- **Terminal**: WezTerm (cask), config symlinked from `dots/wezterm.lua`.
- **Multiplexer**: tmux only. zellij out of scope.
- **Fast-moving CLIs** as Homebrew brews for daily freshness: `opencode`, `gemini-cli`, `prek`, `charmbracelet/tap/crush`. Anthropic and OpenAI ship their CLIs as Homebrew **casks**: `claude-code`, `codex`.
- **GUI apps**: Homebrew casks managed by nix-darwin; Gatekeeper kept on (no `no_quarantine`).
- **`homebrew.onActivation.cleanup = "none"`**: ad-hoc `brew install` survives switches; remove a line from this repo and run `brew uninstall` manually when you really want it gone.
- **`homebrew.onActivation.upgrade = false`** (with `autoUpdate = true`): switches install only *missing* brews/casks and keep the formula index fresh, but never `brew upgrade` — so a dotfile-only `switch` is seconds, not a multi-GB cask re-download. Update packages explicitly with `brew upgrade`.
- **`home-manager.backupFileExtension = "hm-bak"`**: when home-manager wants to write a file you already have, it renames the existing one to `<file>.hm-bak` instead of refusing to activate.
- **Dotfiles** as raw files in `dots/`, symlinked by home-manager — no inline Nix-generated configs, so files stay editable and portable across non-Nix environments.
- **Personal values isolated in `vars.nix`** (gitignored + intent-to-add) — repo is forkable without leaking identity, and per-machine values (hostName, systemUser) don't pollute git history.

## Operational notes

- **Sudo required**: nix-darwin activation now runs as root. Every `darwin-rebuild switch` needs `sudo`.
- **Rebase + intent-to-add**: `git pull --rebase` fails on a dirty index. Use `git pull --rebase --autostash`, or set `git config --global rebase.autoStash true`, or set `programs.git.settings.rebase.autoStash = true` in `home/dev.nix`.
- **Hostname binding**: `flake.nix` defines exactly `darwinConfigurations.${vars.hostName}`. A new machine needs its own `vars.nix` with the right `hostName` (matching `scutil --get LocalHostName`) and its own `systemUser` (matching `whoami`).
