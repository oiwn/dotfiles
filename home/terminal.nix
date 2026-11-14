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
  # Fish
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

      # rmux tmux-shim — shadow `tmux` with rmux during the tmux→rmux trial.
      # MUST run after brew shellenv: /opt/homebrew/bin/tmux (brew tmux 3.8,
      # a tmuxp-formula dependency) would otherwise win the PATH race.
      # Real tmux stays reachable by full path (/opt/homebrew/bin/tmux,
      # /etc/profiles/per-user/$USER/bin/tmux).
      fish_add_path --global --move --prepend $HOME/.config/rmux/shim

      if test (uname) = Darwin; and test -x /usr/bin/xcrun
        set -gx SDKROOT (/usr/bin/xcrun --show-sdk-path)
        set -gx CC /usr/bin/cc
        set -gx CXX /usr/bin/c++
      end

      # Starship prompt — brew bottle (see hosts/macbook.nix brews)
      if type -q starship
        starship init fish | source
      end
    '';
  };

  # WezTerm: GUI from brew cask; config symlinked via home/dotfiles.nix.
}
