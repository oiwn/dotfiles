# Project Overview

## Stack

| Layer | Tool | Why this one |
|---|---|---|
| Package manager | **Lix** | Drop-in Nix fork, flakes on by default, cleaner uninstall, friendlier community fork — same CLI (`nix`) as stock Nix. |
| macOS config | **nix-darwin** | Declarative `system.defaults` (Dock, Finder, key repeat), declarative Homebrew (`brews`/`casks`/fonts), LaunchAgents — the only thing on macOS that turns System Settings into code. |
| User packages + dotfiles | **home-manager** | Per-user `home.packages`, `programs.*` modules (git, gh, gpg, fish, starship, wezterm), and `home.file`/`xdg.configFile` symlinks from `dots/`. |
| Pinning | **Nix flakes** | `flake.nix` + `flake.lock` — reproducible across machines, single source of input versions. |
| Personal values | **`vars.nix`** | Gitignored file holding `userName`/`userEmail`; threaded through `specialArgs`/`extraSpecialArgs` so modules consume it without hardcoding identity in the repo. |

## Architecture

```
dotfiles/
  flake.nix           # inputs + darwinConfigurations.karok, threads vars.nix
  flake.lock          # pinned input versions (committed)
  vars.nix.example    # template — copy to vars.nix and edit before first switch
  vars.nix            # gitignored — { userName, userEmail }
  hosts/
    macbook.nix       # nix-darwin: system.defaults, homebrew brews/casks/fonts, system packages
  home/
    default.nix       # home-manager entry, imports sub-modules
    packages.nix      # home.packages — Nix CLI tools
    dotfiles.nix      # home.file / xdg.configFile — symlinks into dots/
    terminal.nix      # programs.fish, programs.starship, programs.wezterm
    dev.nix           # programs.git (consumes vars), programs.gh, programs.gpg
    apps.nix          # placeholder; brews/casks declared in hosts/macbook.nix
  dots/               # raw dotfiles, source of truth, symlinked by home-manager
```

## Data Flow

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

Single command applies it all:

```sh
darwin-rebuild switch --flake .#karok
```

## Design decisions

- **Rust toolchain via `rustup`** (not Nix) — flexible target/nightly switching. Rust *CLI tools* (ripgrep, bat, fd, eza, etc.) come from Nix as prebuilt binaries.
- **Shell**: fish + starship. zsh + oh-my-zsh + p10k removed.
- **Python**: uv (system-wide via Nix). conda/miniforge removed.
- **Terminal**: WezTerm. Warp removed.
- **Multiplexer**: tmux only. zellij out of scope.
- **Fast-moving CLIs** (`opencode`, `claude-code`, `gemini-cli`, `crush`, `prek`, `codex`): Homebrew `brews` for daily freshness, not Nix.
- **GUI apps**: Homebrew `casks` managed by nix-darwin (declarative install, Gatekeeper kept on).
- **Dotfiles**: raw files in `dots/`, symlinked by home-manager — no inline Nix-generated configs, so files stay editable and portable.
- **`homebrew.onActivation.cleanup = "none"`**: ad-hoc `brew install` survives switches; removing a line from the config does not auto-uninstall (user does that manually).
