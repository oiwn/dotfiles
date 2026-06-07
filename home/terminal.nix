{ pkgs, ... }:

{
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
