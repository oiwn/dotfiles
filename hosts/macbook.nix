{ config, pkgs, vars, ... }:

{
  # =====================
  # System defaults
  # =====================
  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "Nlsv";
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
  };

  # =====================
  # Nix settings
  # =====================
  nix = {
    enable = false;  # Lix manages this, not nix-darwin
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  # =====================
  # Homebrew integration
  # =====================
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
    };

    # Fast-moving agents & tools not in nixpkgs
    brews = [
      "opencode"
      "claude-code"
      "gemini-cli"
      "crush"
      "prek"
    ];

    # GUI apps
    casks = [
      "wezterm"
      "firefox@developer-edition"
      "zed"
      "obsidian"
      "hammerspoon"
      "blender"
      "gimp"
      "krita"
      "reaper"
      "obs"
      "onlyoffice"
      "transmission"
      "bambu-studio"
      "mattermost"
      "slack"
      "docker-desktop"
      "mactex-no-gui"
      "jupyterlab"
      "cocoarestclient"
      "codex"
      "sage"
      "surge-xt"

      # Fonts
      "font-hack-nerd-font"
      "font-meslo-lg-nerd-font"
      "font-source-code-pro"
      "font-symbols-only-nerd-font"
      "font-noto-sans-mono-cjk-jp"
    ];
  };

  # =====================
  # Shell — set fish as default
  # =====================
  users.users.${vars.systemUser}.shell = pkgs.fish;

  # =====================
  # System-level packages
  # =====================
  environment.systemPackages = [
    pkgs.coreutils
    pkgs.mosh
    pkgs.nmap
  ];
}
