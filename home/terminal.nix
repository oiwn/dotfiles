{ pkgs, ... }:

{
  # =====================
  # Fish (needed so home-manager wires Starship into ~/.config/fish/conf.d)
  # =====================
  programs.fish = {
    enable = true;
    # Homebrew on Apple Silicon — set PATH/MANPATH/etc. for fish
    # (the brew installer only patches zsh's profile, not fish's).
    interactiveShellInit = ''
      if test -x /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv | source
      end
    '';
  };

  # =====================
  # Starship prompt
  # =====================
  programs.starship.enable = true;

  # WezTerm: GUI from brew cask; config symlinked via home/dotfiles.nix.
}
