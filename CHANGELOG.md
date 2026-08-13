# Changelog

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
