---
id: 0001-tmuxp-init-fish
status: done
scope: [dots/tmuxp/rust.yaml, dots/fish/functions/tmuxp-init.fish, home/dotfiles.nix, .tmuxp.rust.yaml]
created: 2026-10-27
source: session 2026-10-27: fish command to bootstrap .tmuxp.yaml from the rust template (replace name, skip if present); also removes the dangling nvim/init.vim symlink left by the dots cleanup
---
# Task: tmuxp init fish

## Plan

- [x] Move `.tmuxp.rust.yaml` → `dots/tmuxp/rust.yaml` (content as-is), delete the root file
- [x] Add `dots/fish/functions/tmuxp-init.fish` — refuse if `./.tmuxp.yaml` exists; else write it from `~/.config/tmuxp/rust.yaml` with `session_name` = `$argv[1]` or `basename $PWD`
- [x] `home/dotfiles.nix`: symlink `~/.config/tmuxp/rust.yaml` and `~/.config/fish/functions/tmuxp-init.fish` via `xdg.configFile`; drop the dangling `nvim/init.vim` line (source file deleted in the dots cleanup)
- [x] `git add -N` the new dots paths (flake reads the repo through git)

## Acceptance

- [x] `prek run --all-files`
- [x] `p=$(nix eval --no-warn-dirty --raw '.#darwinConfigurations.bakodo.config.home-manager.users.alexch.xdg.configFile."fish/functions/tmuxp-init.fish".source') && test -f "$p" && echo OK`
- [x] `p=$(nix eval --no-warn-dirty --raw '.#darwinConfigurations.bakodo.config.home-manager.users.alexch.xdg.configFile."tmuxp/rust.yaml".source') && test -f "$p" && echo OK`

## Summary

Fish `tmuxp-init` bootstraps a project's `./.tmuxp.yaml` from `dots/tmuxp/rust.yaml`; template moved under dots, both symlinked by home-manager, dangling `nvim/init.vim` link removed.

## Review

Diff matches plan exactly: template moved byte-identical (git shows `R .tmuxp.rust.yaml -> dots/tmuxp/rust.yaml`), function + two `xdg.configFile` entries added, `nvim/init.vim` line dropped, both new paths intent-to-added. Behavior smoke-tested outside activation with a scratch HOME: writes `./.tmuxp.yaml` with the dir name, honors an explicit name, refuses with exit 1 when the file exists. Activation itself is user-run (sudo), covered by the Manual check.

## Manual checks

- [x] After the user's switch, in a fresh fish: `type tmuxp-init` resolves; in a scratch dir it writes `./.tmuxp.yaml` with the dir name as session; a second run refuses — agent: verified post-switch on the live install — `fish -c 'type tmuxp-init'` resolves; scratch-dir run wrote `session_name: my-proj`; second run refused with exit 1

## Context

- Root `.tmuxp.yaml` is the gitignored local session for this repo — untouched.
- The template's name placeholder is `session_name: pick-a-name`; only that line changes on bootstrap.
- fish autoloads files in `~/.config/fish/functions/`; tmuxp and starship are already brew-installed.

## Log

- 2026-10-27 created: tmuxp init fish
- 2026-10-27 set source session 2026-10-27: fish command to bootstrap .tmuxp.yaml from the rust template (replace name, skip if present); also removes the dangling nvim/init.vim symlink left by the dots cleanup
- 2026-10-27 scope add dots/tmuxp/rust.yaml — template move + fish function + symlink wiring; root template deleted after the move
- 2026-10-27 scope add dots/fish/functions/tmuxp-init.fish — template move + fish function + symlink wiring; root template deleted after the move
- 2026-10-27 scope add home/dotfiles.nix — template move + fish function + symlink wiring; root template deleted after the move
- 2026-10-27 scope add .tmuxp.rust.yaml — template move + fish function + symlink wiring; root template deleted after the move
- 2026-10-27 draft approved: let's go
- 2026-10-27 advance draft → ready
- 2026-10-27 scope approved: dots/tmuxp/rust.yaml, dots/fish/functions/tmuxp-init.fish, home/dotfiles.nix, .tmuxp.rust.yaml
- 2026-10-27 advance ready → in-progress/implement
- 2026-10-27 baseline: .agents/skills/specdev/SKILL.md@3ff2681be1ba, .agents/skills/specdev/references/config.md@33f7670d82ea, .agents/skills/specdev/references/examples.md@51bf9e0996b0, .agents/skills/specdev/specdev.meta@8f50d99580b2, AGENTS.md@243fbb5afc14, dots/.condarc@deleted, dots/.p10k.zsh@deleted, dots/.spacemacs@deleted, dots/.zshrc@deleted, dots/init.vim@deleted, install-linux.sh@deleted, install-osx.sh@deleted, pi_setup.md@deleted, specdev.toml@0232d0e35b01
- 2026-10-27 advance in-progress/implement → in-progress/verify
- 2026-10-27 advance in-progress/verify → in-progress/review
- 2026-10-27 advance in-progress/review → approval
- 2026-10-28 approved: ok close it, i just did darwin-rebuild and it works
- 2026-10-28 advance approval → done
