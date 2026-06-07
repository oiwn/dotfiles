# Dotfiles — pending work

Everything not listed here is already implemented. See `flake.nix`, `hosts/macbook.nix`, `home/*.nix`, and `dots/` for the current state.

## TODO

### Nix packages still to add (in `home/packages.nix`)

- `libyaml`
- `zstd`
- `m4`

### Configs still to write

| Target path | Where to wire it |
|---|---|
| `~/.config/starship.toml` | `home/terminal.nix` via `programs.starship.settings`, or symlink `dots/starship.toml` from `home/dotfiles.nix` |
| `~/.config/fish/conf.d/*.fish` (aliases / env beyond `brew shellenv`) | extend `programs.fish.interactiveShellInit` in `home/terminal.nix`, or drop fish snippets in `dots/` and symlink |

Fish is enabled (`programs.fish.enable`), starship integration is auto-wired, and WezTerm is symlinked from `dots/wezterm.lua`. The two remaining items are pure customization, not breakage.

## Nice-to-haves (not blocking)

- `just bootstrap` recipe wrapping the curl + clone + intent-to-add + switch dance.
- `system.stateVersion` review — currently pinned at `7`, bump only after reading `darwin-rebuild changelog`.

## Out of scope (for now)

- per-project `nix develop` / `shell.nix`
- NixOS (Linux machines)
- secrets management (agenix / sops-nix) — `vars.nix` covers identity, no real secrets yet
- `sagemath` via Nix (does not build on aarch64-darwin; using the brew cask `sage` instead)
