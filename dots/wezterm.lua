-- ~/.wezterm.lua
local wezterm = require 'wezterm'
local act = wezterm.action

-- Font rotation: each entry is a primary family; CJK + symbol fallbacks are
-- appended to every stack. The first entry is the startup default; the picked
-- font lasts for this WezTerm run and resets on a full restart. Edit `fonts`
-- to change the rotation (families must be installed: Hack/MesloLGS ship with
-- the managed casks, JetBrainsMono/FiraCode via ad-hoc
-- `brew install --cask font-jetbrains-mono-nerd-font font-fira-code-nerd-font`).
local fonts = {
  { name = 'JetBrains Mono', family = 'JetBrainsMono Nerd Font Mono' },
  { name = 'Hack',           family = 'Hack Nerd Font Mono' },
  { name = 'MesloLGS',       family = 'MesloLGS Nerd Font Mono' },
  { name = 'FiraCode',       family = 'FiraCode Nerd Font Mono' },
}
local fallbacks = { 'Noto Sans Mono CJK JP', 'Symbols Nerd Font Mono' }

local font_idx = 1
local function font_stack(i)
  return wezterm.font_with_fallback({ fonts[i].family, fallbacks[1], fallbacks[2] })
end

local function apply_font(window)
  window:set_config_overrides({ font = font_stack(font_idx) })
  window:toast_notification('wezterm', 'Font: ' .. fonts[font_idx].name, nil, 4000)
end

return {
  font = font_stack(font_idx),
  font_size = 13.0,
  front_end = 'WebGpu',
  max_fps = 120,

  default_cwd = wezterm.home_dir,

  color_scheme = 'Catppuccin Mocha',

  window_decorations = 'RESIZE',
  native_macos_fullscreen_mode = false,

  keys = {
    {
      key = 't',
      mods = 'CMD',
      action = act.SpawnCommandInNewTab {
        cwd = wezterm.home_dir,
      },
    },
    { key = 'LeftArrow',  mods = 'CMD|SHIFT', action = act.MoveTabRelative(-1) },
    { key = 'RightArrow', mods = 'CMD|SHIFT', action = act.MoveTabRelative(1) },

    -- Font picker (CMD+ALT+F) and cycle-next (CMD+ALT+SHIFT+F)
    {
      key = 'f',
      mods = 'CMD|ALT',
      action = act.InputSelector {
        title = 'Font',
        choices = (function()
          local choices = {}
          for i, f in ipairs(fonts) do
            table.insert(choices, { id = tostring(i), label = f.name })
          end
          return choices
        end)(),
        action = wezterm.action_callback(function(window, _pane, id, _label)
          if id then
            font_idx = tonumber(id)
            apply_font(window)
          end
        end),
      },
    },
    {
      key = 'f',
      mods = 'CMD|ALT|SHIFT',
      action = wezterm.action_callback(function(window, _pane)
        font_idx = (font_idx % #fonts) + 1
        apply_font(window)
      end),
    },
  },
}
