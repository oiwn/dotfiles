-- ~/.wezterm.lua
local wezterm = require 'wezterm'

return {
  font = wezterm.font_with_fallback({
    "Hack Nerd Font Mono",
    "Noto Sans Mono CJK JP",
    "Symbols Nerd Font Mono",
  }),
  font_size = 13.0,
  front_end = "WebGpu",
  max_fps = 120,

  default_cwd = wezterm.home_dir,

  color_scheme = "Catppuccin Mocha",

  window_decorations = "RESIZE",
  native_macos_fullscreen_mode = false,

  keys = {
    {
      key = "t",
      mods = "CMD",
      action = wezterm.action.SpawnCommandInNewTab {
        cwd = wezterm.home_dir,
      },
    },
  },
}
