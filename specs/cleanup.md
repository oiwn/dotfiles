# Cleanup

Code smells, duplication, and refactor notes. Read on demand only — not session context. Each entry is a `##` heading with the file or component, followed by 1-3 sentences.

## dots/ — unreferenced leftovers

`dots/alacritty.toml`, `dots/leftwm_config.ron`, and `dots/.wakatime.cfg` are tracked but symlinked by nothing in `home/dotfiles.nix` (alacritty/leftwm are Linux leftovers; terminal is WezTerm). Confirm and delete, or wire them up if any is still wanted.
