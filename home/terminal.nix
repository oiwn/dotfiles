{ pkgs, ... }:

{
  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "$HOME/.cargo/bin"
  ];

  home.sessionVariables = {
    CC = "/usr/bin/cc";
    CXX = "/usr/bin/c++";
  };

  # =====================
  # Fish (needed so home-manager wires Starship into ~/.config/fish/conf.d)
  # =====================
  programs.fish = {
    enable = true;
    shellInit = ''
      fish_add_path --global --move /opt/homebrew/bin /opt/homebrew/sbin
    '';
    # Homebrew on Apple Silicon — set PATH/MANPATH/etc. for fish
    # (the brew installer only patches zsh's profile, not fish's).
    interactiveShellInit = ''
      if test -x /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv | source
      end

      if test (uname) = Darwin; and test -x /usr/bin/xcrun
        set -gx SDKROOT (/usr/bin/xcrun --show-sdk-path)
        set -gx CC /usr/bin/cc
        set -gx CXX /usr/bin/c++
      end
    '';
  };

  # =====================
  # Starship prompt
  # =====================
  programs.starship.enable = true;

  # WezTerm: GUI from brew cask; config symlinked via home/dotfiles.nix.
}
