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

  # =====================
  # WezTerm — stub, replace with dots/wezterm.lua later
  # =====================
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      return {}
    '';
  };
}
