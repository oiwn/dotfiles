# dotfiles

Declarative macOS setup using Nix (Lix) + nix-darwin + home-manager + flakes.

## Stack

| Layer | Tool | What |
|---|---|---|
| Package manager | **Lix** | Nix implementation, flakes on by default, clean uninstall |
| macOS config | **nix-darwin** | System defaults, Homebrew integration, fonts |
| User packages + dotfiles | **home-manager** | Declarative packages, symlinked configs from `dots/` |
| Per-machine values | **`vars.nix`** | Committed; holds `hostName`, `systemUser`, `gitName`, `gitEmail` |

`flake.lock` is gitignored — each machine resolves fresh inputs on switch. Trade-off: similar (not bit-identical) environments across machines.

## Bootstrap (fresh machine)

```sh
# 1. Install Homebrew (nix-darwin manages it but does not install it)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Lix
curl -sSf -L https://install.lix.systems/lix | sh -s install

# 3. Close terminal and reopen (Lix adds itself to PATH)

# 4. Clone
mkdir -p ~/code
git clone https://github.com/oiwn/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles

# 5. Set your machine values in vars.nix (committed with the repo). Fields must be exact:
#    - hostName   must match `scutil --get LocalHostName`
#    - systemUser must match `whoami`
#    - gitName / gitEmail are your git author identity
$EDITOR vars.nix

# 6. Apply (needs sudo; nix-darwin activation runs as root).
#    --flake .#<host> resolves darwinConfigurations.<your-hostName>.
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)

# 7. Initialize Rust toolchain (rustup itself was installed by step 6).
#    clippy + rustfmt are bundled with the stable channel; rust-analyzer is separate.
rustup default stable
rustup component add rust-analyzer

# 8. Make fish the login shell
echo "$(which fish)" | sudo tee -a /etc/shells
chsh -s "$(which fish)"

# 9. Converge pi runtime packages (installs pi extensions via `pi install`)
just pi-setup
```

After step 6, `darwin-rebuild` is on PATH for subsequent switches (no `nix run` wrapper needed).

### Pre-existing dotfiles

If files like `~/.config/fish/config.fish` already exist from manual setup, home-manager renames them to `<file>.hm-bak` instead of clobbering (via `backupFileExtension = "hm-bak"` in `flake.nix`). Diff and merge anything you want to keep:

```sh
diff ~/.config/fish/config.fish.hm-bak ~/.config/fish/config.fish
```

## Daily updates

```sh
nix flake update                                          # bump flake inputs
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)
```

Bumps nixpkgs/nix-darwin/home-manager, installs any *new* Homebrew brews/casks, then activates. Existing brews/casks are **not** upgraded (see `upgrade = false` below) — run `brew upgrade` manually when you want them refreshed.

If your index is dirty, `git pull --rebase --autostash` (or set
`git config --global rebase.autoStash true` once and for all).

## Managing packages

| Change | File | Then |
|---|---|---|
| Nix CLI tool | `home/packages.nix` | `sudo darwin-rebuild switch …` |
| Homebrew brew (CLI) | `hosts/macbook.nix` → `brews` | same |
| Homebrew cask (GUI) | `hosts/macbook.nix` → `casks` | same |
| System default (Dock, Finder, …) | `hosts/macbook.nix` → `system.defaults` | same |
| Dotfile content | `dots/<file>` | same (symlinks repoint to nix store) |
| pi runtime package | `Justfile` → `pi-setup` recipe (catalog in `pi_setup.md`) | `just pi-setup` (no switch) |
| Git identity / hostname | `vars.nix` (per-machine) | same |

Remove a package: delete the line, re-run switch.

## Architecture

```
dotfiles/
  flake.nix           # inputs + darwinConfigurations + home-manager wiring
  vars.nix.example    # template for fresh values, committed
  vars.nix            # committed, per machine (hostName/systemUser/gitName/gitEmail)
  hosts/
    macbook.nix       # nix-darwin: system.defaults, homebrew brews/casks/fonts
  home/
    default.nix       # home-manager entry; derives username/homeDirectory from vars
    packages.nix      # home.packages — Nix CLI tools
    dotfiles.nix      # home.file / xdg.configFile — symlinks from dots/ to $HOME
    terminal.nix      # programs.fish, programs.starship
    dev.nix           # programs.git (consumes vars), programs.gh, programs.gpg
    apps.nix          # placeholder (brews/casks live in hosts/macbook.nix)
  dots/               # raw dotfiles, source of truth, symlinked by home-manager
```

## Where stuff lives at runtime

| Path | Source |
|---|---|
| `/opt/homebrew/bin/*` | brews + cask CLI shims (`brew`, `codex`, `mosh`, `opencode`, …) |
| `/Applications/*.app` | casks (WezTerm, Slack, GIMP, …) |
| `~/.nix-profile/bin/*` | `home.packages` (fd, bat, helix, neovim, …) |
| `/run/current-system/sw/bin/*` | `environment.systemPackages` (coreutils, nmap) |

Fish picks up `/opt/homebrew/bin` because `home/terminal.nix` sources `brew shellenv` in `interactiveShellInit`.

## Design decisions

- **Rust toolchain**: `rustup` installed via Nix; toolchains/components managed by rustup (flexible targets/nightly). Rust CLI tools (bat, fd, eza, …) come from Nix as prebuilt binaries. Exception: `ripgrep` is Homebrew-managed because it's a shared runtime dependency of the brew-managed agents (`codex`, `opencode`).
- **Shell**: fish + starship (zsh + oh-my-zsh removed).
- **Python**: uv instead of conda.
- **Terminal**: WezTerm (Warp removed).
- **Multiplexer**: tmux primary; zellij via brew (nixpkgs dropped zellij; brew tracks releases).
- **mosh via brew, not nixpkgs**: the nix mosh bundle ships its own OpenSSH, which rejects `UseKeychain` from `~/.ssh/config`; brew mosh invokes `ssh` from PATH (Apple's `/usr/bin/ssh`), which parses the config fine.
- **Fast-moving CLIs** (`opencode-v2` from `anomalyco/tap` — replaced the plain `opencode` formula, same binary name, `gemini-cli`, `crush`, `prek`): Homebrew brews for daily freshness; `claude-code` and `codex` are casks (that's how Homebrew ships them).
- **GUI apps**: Homebrew casks managed by nix-darwin; Gatekeeper left enabled.
- **`homebrew.onActivation.cleanup = "none"`**: ad-hoc `brew install` survives switches; remove a line from this repo and run `brew uninstall` manually when you really want it gone.
- **`homebrew.onActivation.upgrade = false`**: switches install only *missing* brews/casks — no multi-GB cask re-downloads on every `switch`. Update packages explicitly with `brew upgrade`.
- **Dotfiles**: raw files in `dots/`, symlinked by home-manager — no inline Nix-generated configs.
- **Personal values in `vars.nix` are committed** (de-secreted 2026-09-20): the values are machine/git identity, already public in history and commit metadata, so the old gitignored + `git add -f --intent-to-add` ceremony — and its recurring flake-eval breakage — was retired. `vars.nix.example` stays as a template; forks edit `vars.nix` to their own values.
