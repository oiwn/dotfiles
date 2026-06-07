# Dotfiles — pending work

Everything not listed here is already implemented. See `flake.nix`, `hosts/macbook.nix`, `home/*.nix`, and `dots/` for the current state.

## TODO

### Nix packages to add (in `home/packages.nix`)

- `libyaml`
- `zstd`
- `m4`

### Configs still to write

| Target path | Where to wire it |
|---|---|
| `~/.config/fish/config.fish` | `home/terminal.nix` via `programs.fish` (aliases/env) or symlink from `dots/` |
| `~/.config/starship.toml` | `home/terminal.nix` via `programs.starship.settings` or symlink from `dots/` |
| `~/.config/wezterm/wezterm.lua` | replace the `return {}` stub in `home/terminal.nix` (`programs.wezterm.extraConfig`) or symlink from `dots/wezterm.lua` |

## Out of scope (for now)

- per-project `nix develop` / `shell.nix`
- NixOS (Linux machines)
- secrets management (agenix / sops-nix)
- `sagemath` via Nix (does not build on aarch64-darwin; using the brew cask `sage` instead)
