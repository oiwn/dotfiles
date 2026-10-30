{ config, pkgs, vars, ... }:

{
  # =====================
  # nix-darwin baseline
  # =====================
  system.stateVersion = 7;
  system.primaryUser = vars.systemUser;
  programs.fish.enable = true;

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
      upgrade = false;
      cleanup = "none";
    };

    taps = [
      "charmbracelet/tap"   # for crush
      "anomalyco/tap"       # for opencode-v2
      "nklmilojevic/sofka"  # for sofka
      "rustfs/tap"          # for rc
    ];

    # Fast-moving agents & tools not in nixpkgs
    brews = [
      "anomalyco/tap/opencode-v2"  # v2 replaced the plain `opencode` formula — same binary name, they'd fight over the symlink
      "charmbracelet/tap/crush"
      "prek"
      "tmuxp"
      "zellij"
      "ripgrep"
      "starship"
      "tabiew"
      "marksman"
      "mosh"  # via brew, not nixpkgs: nix mosh bundles an openssh that rejects ~/.ssh/config UseKeychain; brew mosh uses PATH ssh (Apple)
      "rclone"   # fast-moving (backends) — brew freshness; nixpkgs pin lags
      "zola"     # fast-moving — brew freshness
      "herdr"
      "libomp"   # OpenMP runtime for local ML builds (llama.cpp/whisper.cpp/ComfyUI nodes)
      "nklmilojevic/sofka/sofka"
      "rustfs/tap/rc"
    ];

    # GUI apps — full shared list; a host drops entries via vars.caskExclude
    casks = builtins.filter (c: !builtins.elem c vars.caskExclude) [
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
      "bambu-studio"
      "mattermost"
      "slack"
      "docker-desktop"
      "mactex-no-gui"
      "jupyterlab-app"
      "cocoarestclient"
      "claude-code"
      "codex"
      "sage"
      "surge-xt"

      # bakodo-only apps (kodo excludes via vars/kodo.nix caskExclude)
      "comfy"
      "headlamp"
      "openvpn-connect"
      "raspberry-pi-imager"
      "ungoogled-chromium"
      "yandex"

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
  users.users.${vars.systemUser} = {
    shell = pkgs.fish;
    home = "/Users/${vars.systemUser}";
  };

  # =====================
  # System-level packages
  # =====================
  environment.systemPackages = [
    pkgs.coreutils
    pkgs.nmap
    # mosh deliberately NOT here — see brews list (nix build bundles a broken-for-UseKeychain ssh)
  ];
}
