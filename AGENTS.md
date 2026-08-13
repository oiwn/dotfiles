# AGENTS.md

## Specs first

This repo uses spec-driven development. Read `specs/overview.md` (durable
architecture + gotchas — canonical source of detail) and `specs/ctx.md` (current
task) before acting. Full workflow: the `specdev` skill. Do not duplicate
specs/ content here.

## Common actions

### Apply changes (default — every edit)

```sh
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)
```

Reuses the existing `flake.lock`. Fast — do this for every edit. Do **not** run
`nix flake update` for normal edits; that bumps the channel and re-downloads the
whole closure.

### Bump inputs (deliberate, ~1 GB one-time download)

```sh
nix flake update
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)
```

Only when you actually want newer nixpkgs/nix-darwin/home-manager. Inputs are
pinned to `nixos-26.05` / `nix-darwin-26.05` / `home-manager release-26.05`
stable branches, so even this is cheap (frozen channel → mostly cache hits).

### Fixes / changes

Edit the file for the layer you're changing, then re-run the switch command above:

| Change               | File                                    |
|----------------------|-----------------------------------------|
| Nix CLI tool         | `home/packages.nix`                     |
| Homebrew brew/cask   | `hosts/macbook.nix` (`brews`/`casks`)   |
| System default       | `hosts/macbook.nix` (`system.defaults`) |
| Dotfile content      | `dots/<file>`                           |
| Git identity/host    | `vars.nix` (gitignored, per-machine)    |

Remove a package: delete the line, re-run switch.

## Gotchas

- `flake.lock` is gitignored — fresh resolve per machine; no lock to commit.
- `vars.nix` must be `git add -f --intent-to-add` for the flake to see it.
- Never run bare `git add .` — it stages `vars.nix`'s content. Stage with `just stage` (i.e. `git add -A -- . ':(exclude)vars.nix'`).
- `git pull` needs `--rebase --autostash`.
- `darwin-rebuild` requires sudo.
