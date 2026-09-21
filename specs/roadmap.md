# Roadmap

## Issue

- The issue:

  - goose is installed and executable at /Users/alexch/.local/bin/goose.
  - Fish cannot find it because /Users/alexch/.local/bin is missing from Fish’s PATH.
  - ~/.config/fish/config.fish is a Home Manager-generated symlink into /nix/store; do not edit it directly.
  - The declarative source is /Users/alexch/code/dotfiles/home/terminal.nix.
  - No files were changed.

  Required change in home/terminal.nix:

  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
  ];

  And update the Fish initialization to:

  shellInit = ''
    fish_add_path --global --move /opt/homebrew/bin /opt/homebrew/sbin /Users/alexch/.local/bin
  '';

  Prefer $HOME/.local/bin in home.sessionPath; Fish’s fish_add_path receives a concrete path so it persists correctly.

  Then rebuild from the dotfiles repo:

  cd /Users/alexch/code/dotfiles
  sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)

  Then verify:

  type -a goose
  goose --version

## Planned

### Nix packages to add (in `home/packages.nix`)

- `libyaml`
- `zstd`
- `m4`

### Configs still to write

| Target path | Where to wire it |
|---|---|
| `~/.config/starship.toml` | `home/terminal.nix` via `programs.starship.settings`, or symlink `dots/starship.toml` from `home/dotfiles.nix` |
| `~/.config/fish/conf.d/*.fish` (aliases / env beyond `brew shellenv`) | extend `programs.fish.interactiveShellInit` in `home/terminal.nix`, or drop fish snippets in `dots/` and symlink |

### Quarantine popup fix (deferred)

"Apple could not verify 'rg' is free of malware" when codex spawns rg. Cause: `codex` cask carries `com.apple.quarantine` (`xattr` confirmed), not rg's source. Fix: a nix-darwin `system.activationScripts` block running `xattr -dr com.apple.quarantine` over `/opt/homebrew/Caskroom/codex` (+ `claude-code`) on each switch, keeping Gatekeeper on globally.

## Out of scope (for now)

- per-project `nix develop` / `shell.nix`
- NixOS (Linux machines)
- secrets management (agenix / sops-nix) — `vars.nix` covers identity, no real secrets yet
- `sagemath` via Nix (does not build on aarch64-darwin; using the brew cask `sage` instead)
