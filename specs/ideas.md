# Ideas

## Vision

Tooling to bootstrap a working dev environment on a fresh machine quickly — install Homebrew + Lix, clone the repo, fill in `vars.nix`, run one command, get back to work.

Today: macOS only (aarch64-darwin).
Later: NixOS / Linux laptops sharing the same `home/` modules where possible.

## Principles

- **Declarative** — every package, every system default, every dotfile lives in Nix or in `dots/`. No `brew install` instructions buried in shell history; the config IS the spec.
- **Similar, not identical** — `flake.lock` is gitignored. Each machine resolves nixpkgs-unstable fresh, so machines drift slightly over time. Avoids the "shared lock file" maintenance tax in exchange for losing bit-identical reproducibility (acceptable trade for personal machines).
- **Reversible** — Lix uninstalls cleanly. `darwin-rebuild --list-generations` + `--rollback` undoes a bad switch. Nothing leaks into `/usr/local` or `~/Library` without a way back.
- **Personal values isolated** — name/email/hostname/username live in `vars.nix` (gitignored, intent-to-add). Repo is forkable without leaking identity; per-machine values don't pollute git history.
- **Fast-moving tools escape** — vendor CLIs (`claude-code`, `codex`, `opencode`, `gemini-cli`, `crush`, `prek`) go via Homebrew so updates land daily without a flake bump. Everything else is Nix-pinned per machine.
- **Raw dotfiles** — files in `dots/` stay plain text, symlinked into place. Means the same files work on machines that don't have Nix at all (useful for SSHing into a server with the same tmux/helix/neovim config).

## Open ideas / future

- **Linux host** — add `hosts/<name>.nix` for a NixOS laptop, reuse `home/` modules. Test which `programs.*` settings are darwin-specific vs cross-platform.
- **`just bootstrap` recipe** — single `just bootstrap` that runs the curl + clone + `git add -f -N` + first switch, picking up `vars.nix` interactively.
- **Per-project `nix develop`** — start once a project needs a pinned toolchain (e.g., a Rust crate locked to a specific MSRV).
- **Secrets management** — agenix or sops-nix when the first real secret (API token, signing key) needs to live in the repo. `vars.nix` is fine for identity but not for credentials.
- **Multi-host flake** — if/when a third machine appears, refactor `flake.nix` to `mkSystem { hostName; … }` once, declared in a `hosts` attrset, instead of relying solely on per-machine `vars.nix`. Keeps the option open of bit-identical reproduction if `flake.lock` ever gets committed back.
- **Starship + fish config in `dots/`** — currently using home-manager defaults; move to symlinked configs once there's anything worth customizing.
