---
id: 0002-multihost-kodo
status: approval
scope: [flake.nix, vars/, vars.nix, vars.nix.example, hosts/macbook.nix, AGENTS.md]
created: 2026-10-27
source: session 2026-10-27: run the same stack on second MacBook 'kodo' (alexch, Apple Silicon) — per-host vars, genAttrs flake, lighter cask set (drops: blender, gimp, krita, reaper, obs, bambu-studio, surge-xt, docker-desktop)
---
# Task: multihost kodo

## Plan

- [x] `vars/bakodo.nix` + `vars/kodo.nix`: `hostName`, `systemUser`, `platform`, git identity; kodo adds `caskExclude` with the 8 drops, bakodo gets an empty list; delete `vars.nix`; rewrite `vars.nix.example` to the new shape
- [x] `flake.nix`: host list `[ "bakodo" "kodo" ]` → `genAttrs` builds one `darwinConfiguration` per host, each importing `vars/<host>.nix`; `system` + `nixpkgs.hostPlatform` come from `vars.platform`
- [x] `hosts/macbook.nix`: shared full cask list stays as-is; `builtins.filter` removes `vars.caskExclude` entries
- [x] `specs/overview.md`: architecture tree + hostname-binding note → per-host vars + kodo bootstrap steps
- [x] `AGENTS.md`: common-actions table row `vars.nix` → `vars/<host>.nix`
- [x] `git add -N vars/` (new dir must be git-visible to the flake)

## Acceptance

- [x] `prek run --all-files`
- [x] `test "$(nix eval --no-warn-dirty --raw '.#darwinConfigurations.bakodo.config.system.primaryUser')" = alexch`
- [x] `test "$(nix eval --no-warn-dirty --raw '.#darwinConfigurations.kodo.config.system.primaryUser')" = alexch`
- [x] `nix eval --no-warn-dirty --raw '.#darwinConfigurations.kodo.config.homebrew.casks' --apply 'c: if builtins.any (x: builtins.elem x ["bambu-studio" "blender" "docker-desktop" "gimp" "krita" "obs" "reaper" "surge-xt"]) c then abort "dropped cask still present" else "OK"'`
- [x] `nix eval --no-warn-dirty --raw '.#darwinConfigurations.bakodo.config.homebrew.casks' --apply 'c: if builtins.length c == 27 then "OK" else abort "expected 27 casks"'`

## Manual checks

- [ ] On kodo: fresh clone, then `sudo darwin-rebuild switch --flake .#kodo` completes — user: "…" (waivable if kodo isn't at hand this session)

## Summary

Flake builds a darwinConfiguration per host from `vars/<host>.nix` (bakodo + kodo); kodo skips 8 casks via `caskExclude`; single vars.nix retired, docs updated.

## Review

Diff matches plan: two per-host vars files (kodo = bakodo + `caskExclude` of the 8 agreed drops), `vars.nix` deleted with no remaining importer (grep-verified), example rewritten, flake iterates `hosts` via `nixpkgs.lib.genAttrs` (first draft wrongly used `builtins.genAttrs` — doesn't exist, caught by the acceptance eval), `hosts/macbook.nix` filters the untouched shared cask list, docs updated (overview stack/tree/flow/decisions/hostname-binding, AGENTS table row + gotcha). Eval-level regression proof: bakodo still resolves 27 casks with the same primaryUser — restructuring changed nothing for this machine. kodo activation is the outstanding Manual check.

## Context

- kodo = second MacBook, same user `alexch`, also `aarch64-darwin`.
- Drops on kodo: creative suite (blender, gimp, krita, reaper, obs) + special-purpose (bambu-studio, surge-xt, docker-desktop). Everything else — brews, fonts, home-manager, dots — identical.
- Apply command unchanged: `.#$(scutil --get LocalHostName)` resolves per machine. `flake.lock` is gitignored → each machine resolves fresh.
- Only `flake.nix` imports `vars.nix` today (verify with grep before deleting); `home/` modules receive vars via `specialArgs`/`extraSpecialArgs` and don't change.

## Log

- 2026-10-27 created: multihost kodo
- 2026-10-27 set source session 2026-10-27: run the same stack on second MacBook 'kodo' (alexch, Apple Silicon) — per-host vars, genAttrs flake, lighter cask set (drops: blender, gimp, krita, reaper, obs, bambu-studio, surge-xt, docker-desktop)
- 2026-10-27 scope add flake.nix — multi-host flake + per-host vars (vars/ = bakodo + kodo) + caskExclude filtering in the shared host module + AGENTS.md vars table row; specs/overview.md rides along as spec update (always in scope)
- 2026-10-27 scope add vars/ — multi-host flake + per-host vars (vars/ = bakodo + kodo) + caskExclude filtering in the shared host module + AGENTS.md vars table row; specs/overview.md rides along as spec update (always in scope)
- 2026-10-27 scope add vars.nix — multi-host flake + per-host vars (vars/ = bakodo + kodo) + caskExclude filtering in the shared host module + AGENTS.md vars table row; specs/overview.md rides along as spec update (always in scope)
- 2026-10-27 scope add vars.nix.example — multi-host flake + per-host vars (vars/ = bakodo + kodo) + caskExclude filtering in the shared host module + AGENTS.md vars table row; specs/overview.md rides along as spec update (always in scope)
- 2026-10-27 scope add hosts/macbook.nix — multi-host flake + per-host vars (vars/ = bakodo + kodo) + caskExclude filtering in the shared host module + AGENTS.md vars table row; specs/overview.md rides along as spec update (always in scope)
- 2026-10-27 scope add AGENTS.md — multi-host flake + per-host vars (vars/ = bakodo + kodo) + caskExclude filtering in the shared host module + AGENTS.md vars table row; specs/overview.md rides along as spec update (always in scope)
- 2026-10-27 draft approved: let's do another one in same batch
- 2026-10-27 advance draft → ready
- 2026-10-27 scope approved: flake.nix, vars/, vars.nix, vars.nix.example, hosts/macbook.nix, AGENTS.md
- 2026-10-27 advance ready → in-progress/implement
- 2026-10-27 baseline: .agents/skills/specdev/SKILL.md@3ff2681be1ba, .agents/skills/specdev/references/config.md@33f7670d82ea, .agents/skills/specdev/references/examples.md@51bf9e0996b0, .agents/skills/specdev/specdev.meta@8f50d99580b2, dots/.condarc@deleted, dots/.p10k.zsh@deleted, dots/.spacemacs@deleted, dots/.zshrc@deleted, dots/fish/functions/tmuxp-init.fish@0d48aad2959d, dots/init.vim@deleted, dots/tmuxp/rust.yaml@419e04dc46c8, home/dotfiles.nix@be141c7ea389, install-linux.sh@deleted, install-osx.sh@deleted, pi_setup.md@deleted, specdev.toml@0232d0e35b01
- 2026-10-27 advance in-progress/implement → in-progress/verify
- 2026-10-27 advance in-progress/verify → in-progress/review
- 2026-10-27 advance in-progress/review → approval
