{ pkgs, ... }:

let
  dotsDir = ../dots;
in
{
  # =====================
  # tmux — ~/.tmux.conf
  # =====================
  home.file.".tmux.conf".source = "${dotsDir}/.tmux.conf";

  # =====================
  # helix — ~/.config/helix/
  # =====================
  xdg.configFile."helix/config.toml".source = "${dotsDir}/helix.toml";
  xdg.configFile."helix/languages.toml".source = "${dotsDir}/languages.toml";

  # =====================
  # neovim — ~/.config/nvim/
  # =====================
  xdg.configFile."nvim/init.lua".source = "${dotsDir}/init.lua";
  xdg.configFile."nvim/init.vim".source = "${dotsDir}/init.vim";

  # =====================
  # editorconfig — ~/.editorconfig
  # =====================
  home.file.".editorconfig".source = "${dotsDir}/.editorconfig";

  # =====================
  # hammerspoon — ~/.hammerspoon/init.lua
  # =====================
  home.file.".hammerspoon/init.lua".source = "${dotsDir}/hammerspoon.lua";

  # =====================
  # wezterm — ~/.wezterm.lua
  # =====================
  home.file.".wezterm.lua".source = "${dotsDir}/wezterm.lua";
}
