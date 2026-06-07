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
# 1. Install Homebrew (nix-darwin manages it but does not install it)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Lix
curl -sSf -L https://install.lix.systems/lix | sh -s install

# 3. Close terminal and reopen (Lix adds itself to PATH)

# 4. Clone
mkdir -p ~/code
git clone https://github.com/oiwn/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles

# 5. Create personal vars file (gitignored — fill in hostName, name, email).
#    hostName must match `scutil --get LocalHostName`.
cp vars.nix.example vars.nix
$EDITOR vars.nix

# 6. Make vars.nix visible to the flake without staging its content.
#    Flakes only see git-tracked paths; intent-to-add registers the path
#    while keeping content out of any commit. -f overrides .gitignore.
git add -f --intent-to-add vars.nix

# 7. Apply
nix run nix-darwin/master#darwin-rebuild -- switch --flake .

# 8. Initialize Rust toolchain (rustup itself was installed by step 7)
rustup default stable
rustup component add rust-analyzer clippy rustfmt

# 9. Add Fish to /etc/shells and set as default
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

- **Rust toolchain**: `rustup` installed via Nix; toolchains/components managed by rustup (flexible targets/nightly). Rust CLI tools (ripgrep, bat, fd, eza, etc.) come from Nix as prebuilt binaries.
- **Shell**: fish + starship (zsh + oh-my-zsh removed)
- **Python**: uv instead of conda
- **Terminal**: WezTerm (Warp removed)
- **Multiplexer**: tmux only (zellij out of scope)
- **Fast-moving tools** (opencode, claude-code, gemini-cli): Homebrew brews for daily freshness
- **GUI apps**: Homebrew casks managed by nix-darwin
- **Dotfiles**: raw files in `dots/`, symlinked by home-manager — no inline Nix configs
