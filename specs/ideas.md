# Ideas

## Vision

Tooling to bootstrap a working dev environment on a fresh machine in minutes — clone the repo, fill in a vars file, run one command, get back to work.

Today: macOS only (aarch64).
Later: NixOS / Linux laptops sharing the same `home/` modules.

## Principles

- **Declarative** — every package, every system default, every dotfile lives in Nix or in `dots/`. No `brew install` instructions in a README; the config IS the spec.
- **Reproducible** — `flake.lock` pins everything. Two machines on the same lock = the same environment.
- **Reversible** — Lix uninstalls cleanly. `darwin-rebuild rollback` undoes a bad switch. Nothing leaks into `/usr/local` or `~/Library` without a way back.
- **Personal values isolated** — name/email/secrets live in `vars.nix` (gitignored), so the repo is forkable without leaking identity.
- **Fast-moving tools escape** — LLM CLIs (`claude-code`, `opencode`, etc.) and a few GUI apps go via Homebrew brews/casks for daily freshness; everything else is Nix-pinned.

## Open ideas / future

- A second host module for a Linux laptop (`hosts/<name>.nix` + NixOS module).
- Per-project `nix develop` shells once a project needs one.
- Secrets management via agenix or sops-nix when the first real secret appears (currently none — git email is the only personal value).
- A `just bootstrap` recipe wrapping the curl+clone+switch dance from the README.
