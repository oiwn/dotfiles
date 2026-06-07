{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # -------------------------------
    # Rust CLI tools (prebuilt bins)
    # -------------------------------
    bat
    eza
    ripgrep
    fd
    bottom
    duf
    tokei
    cargo-binstall
    rust-analyzer
    typos
    dprint
    just
    yazi
    jless
    csvlens
    tabiew
    television
    gitleaks
    marksman

    # -------------------------------
    # Shell & prompt
    # -------------------------------
    fish
    starship

    # -------------------------------
    # Editors
    # -------------------------------
    helix
    neovim

    # -------------------------------
    # Terminal multiplexer
    # -------------------------------
    tmux

    # -------------------------------
    # Dev tools
    # -------------------------------
    gh
    nodejs
    uv
    cmake
    gcc
    jq
    asciinema
    netlify-cli
    ansible
    opentofu

    # -------------------------------
    # Media / docs
    # -------------------------------
    tesseract
    graphviz
    pandoc
    imagemagick
    ffmpeg
    gifsicle

    # -------------------------------
    # Security
    # -------------------------------
    gnupg
    pinentry_mac

    # -------------------------------
    # System / misc
    # -------------------------------
    htop

    # -------------------------------
    # Languages (for neovim LuaJIT, Python, Sage)
    # -------------------------------
    luajit
    python314
    pkgconf
    sqlite

    # sage  # NOTE: sagemath does not build on aarch64-darwin; use the brew cask "sage" instead
  ];
}
