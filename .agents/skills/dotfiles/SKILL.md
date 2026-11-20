---
name: dotfiles
description: >
  Working in this nix-darwin + home-manager dotfiles repo: the user-run
  darwin-rebuild apply loop, git-visibility of new dots/ files before a
  switch (git add -N), when to bump flake inputs, and Nix store garbage
  collection. Use when editing anything in this repo or when asked to
  apply, rebuild, update inputs, or reclaim disk space.
---

# Dotfiles repo workflow

## Golden rules

- The agent edits files; **the user runs every state-changing command**
  (darwin-rebuild, flake update, brew install/upgrade, nix GC, git commit/push,
  tmux kill-server). Print the command, don't run it.
- Staging is plain git (`git add -A`); `vars.nix` is tracked like everything
  else (de-secreted 2026-09-20 — the gitignore + intent-to-add ceremony is
  gone).
- **New files under `dots/` must be git-visible before a switch**
  (`git add -N <path>`): flake eval reads the repo through git, so untracked
  files are invisible → home-manager installs dangling symlinks with no
  build error.

## Apply changes (user runs)

```sh
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)
```

Reuses `flake.lock` — fast. New files under `dots/` must be git-visible
first: `git add -N <path>` (untracked files are invisible to flake eval).

## Bump inputs (deliberate, ~1 GB one-time)

```sh
nix flake update
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)
```

Only when newer nixpkgs/nix-darwin/home-manager are actually wanted. Inputs
are pinned to the stable `26.05` branches, so even this is mostly cache hits.

## Nix garbage collection (user runs)

Every switch keeps the previous generations for rollback — the store only
grows. Inspect: `du -sh /nix/store`, `df -h /`. Reclaim:

```sh
nix-collect-garbage --delete-older-than 14d   # keeps the last 14 days of rollbacks
nix-collect-garbage -d                        # maximum reclaim, no old rollbacks
```

Tradeoff: collected generations can no longer be rolled back to. Never run
these from an agent session; print them for the user.

## Layer map

| Change                | File                                       |
|-----------------------|--------------------------------------------|
| Nix CLI tool          | `home/packages.nix`                        |
| Homebrew brew/cask    | `hosts/macbook.nix` (`brews`/`casks`)      |
| System default        | `hosts/macbook.nix` (`system.defaults`)    |
| Dotfile content       | `dots/<file>`                              |
| pi extension/config   | `dots/pi/agent/**`                         |
| Local skill           | `.agents/skills/**`                        |
| Git identity/host     | `vars.nix` (tracked, per-machine)          |

Remove a package: delete the line, re-run switch (brew leftovers need a
manual `brew uninstall` — `homebrew.onActivation.cleanup = "none"`).
