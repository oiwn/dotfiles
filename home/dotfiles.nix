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

  # =====================
  # zellij — ~/.config/zellij/
  # =====================
  xdg.configFile."zellij/config.kdl".source = "${dotsDir}/zellij.kdl";

  # =====================
  # pi agent — ~/.pi/agent/
  # Config files only; state (auth.json, trust.json, sessions/, npm/,
  # mcp-cache.json) stays live in ~/.pi/agent. settings.json is NOT managed:
  # /settings and pi install write to it at runtime.
  # =====================
  home.file.".pi/agent/extensions/modes.ts".source = "${dotsDir}/pi/agent/extensions/modes.ts";
  home.file.".pi/agent/keybindings.json".source = "${dotsDir}/pi/agent/keybindings.json";
}
