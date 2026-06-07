# dotfiles

Declarative macOS setup using Nix (Lix) + nix-darwin + home-manager + flakes.

## Stack

| Layer | Tool | What |
|---|---|---|
| Package manager | **Lix** | Nix implementation, flakes on by default, clean uninstall |
| macOS config | **nix-darwin** | System defaults, Homebrew, fonts |
| User packages + dotfiles | **home-manager** | Declarative packages, symlinked configs from `dots/` |
| Pinning | **Nix Flakes** | `flake.nix` + `flake.lock` — reproducible |

## Bootstrap (fresh machine)

```sh
# 1. Install Lix
curl -sSf -L https://install.lix.systems/lix | sh -s install

# 2. Close terminal and reopen (Lix adds itself to PATH)

# 3. Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 4. Clone and apply
mkdir -p ~/code
git clone https://github.com/oiwn/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
nix run nix-darwin/master#darwin-rebuild -- switch --flake .

# 5. Add Fish to /etc/shells and set as default
echo "$(which fish)" | sudo tee -a /etc/shells
chsh -s $(which fish)
```

After the first run, `darwin-rebuild` is in PATH.

## Daily updates

```sh
nix flake update && darwin-rebuild switch
```

Updates nixpkgs, flake inputs, and Homebrew — then applies everything.

## Managing packages

```sh
# Add: edit home/packages.nix (Nix) or hosts/macbook.nix (brew), then:
darwin-rebuild switch

# Remove: delete the line, re-run switch
```

## Architecture

```
dotfiles/
  flake.nix           # inputs (nixpkgs, nix-darwin, home-manager) + darwinConfigurations
  flake.lock          # pinned versions (commit this)
  hosts/
    macbook.nix       # nix-darwin: system.defaults, homebrew brews/casks/fonts
  home/
    default.nix       # home-manager entry point
    packages.nix      # home.packages — Nix CLI tools
    dotfiles.nix      # home.file/xdg.configFile — symlinks from dots/ to ~
    terminal.nix      # fish, starship, wezterm
    dev.nix           # git, gh, gpg
    apps.nix          # placeholder (brew agents in hosts/macbook.nix)
  dots/               # raw dotfiles — source of truth, kept as plain files
```

## Design decisions

- **Rust toolchain** via `rustup` (flexible targets/nightly). Rust CLI tools via Nix prebuilt binaries.
- **Shell**: fish + starship (zsh + oh-my-zsh removed)
- **Python**: uv instead of conda
- **Terminal**: WezTerm (Warp removed)
- **Multiplexer**: tmux only (zellij out of scope)
- **Fast-moving tools** (opencode, claude-code, gemini-cli): Homebrew brews for daily freshness
- **GUI apps**: Homebrew casks managed by nix-darwin
- **Dotfiles**: raw files in `dots/`, symlinked by home-manager — no inline Nix configs
