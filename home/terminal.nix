{ pkgs, ... }:

{
  # =====================
  # Fish (needed so home-manager wires Starship into ~/.config/fish/conf.d)
  # =====================
  programs.fish.enable = true;

  # =====================
  # Starship prompt
  # =====================
  programs.starship.enable = true;

  # WezTerm: GUI from brew cask; config symlinked via home/dotfiles.nix.
}
