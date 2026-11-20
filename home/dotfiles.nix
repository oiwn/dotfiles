{ ... }:

let
  dotsDir = ../dots;
in
{
  # =====================
  # rmux — ~/.config/rmux/rmux.conf (brew rmux)
  # Formerly .tmux.conf (tmux retired 2026-11-20): every directive verified
  # supported on rmux 0.10.0 (incl. extended-keys csi-u, terminal-overrides
  # RGB/sitm, set-clipboard OSC52). Sessions load via `dotfiles ws load`
  # (tools/dotfiles cargo bin, rmux-sdk daemon IPC).
  # =====================
  xdg.configFile."rmux/rmux.conf".source = "${dotsDir}/rmux.conf";

  # =====================
  # dotfiles CLI — ~/.config/dotfiles/
  # Template for `dotfiles ws init` (tools/dotfiles cargo bin).
  # =====================
  xdg.configFile."dotfiles/ws.ron".source = "${dotsDir}/dotfiles/ws.ron";

  # =====================
  # helix — ~/.config/helix/
  # =====================
  xdg.configFile."helix/config.toml".source = "${dotsDir}/helix.toml";
  xdg.configFile."helix/languages.toml".source = "${dotsDir}/languages.toml";

  # =====================
  # neovim — ~/.config/nvim/
  # =====================
  xdg.configFile."nvim/init.lua".source = "${dotsDir}/init.lua";

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
  # /settings and pi install write to it at runtime. mcp.json is managed:
  # pi-mcp-adapter reads it but never rewrites the source file → symlink-safe.
  # Server auth uses "!jq …" command secrets — the API key lives ONLY in
  # ~/.pi/agent/auth.json (never in this repo/store). jq must be on PATH
  # (it is: home.packages, and /etc/profiles is in pi's inherited PATH).
  # Extensions are directory layouts (extensions/<name>/index.ts) — pi
  # auto-loads *.ts files AND */index.ts; helper modules (readonly.ts) are
  # only reachable via relative import. modes.test.ts stays repo-only.
  # NOTE: after the first switch to this layout, remove the stale pre-layout
  # symlink: rm ~/.pi/agent/extensions/modes.ts (it would double-register /mode).
  # =====================
  home.file.".pi/agent/extensions/modes/index.ts".source = "${dotsDir}/pi/agent/extensions/modes/index.ts";
  home.file.".pi/agent/extensions/modes/readonly.ts".source = "${dotsDir}/pi/agent/extensions/modes/readonly.ts";
  home.file.".pi/agent/extensions/healthcheck/index.ts".source = "${dotsDir}/pi/agent/extensions/healthcheck/index.ts";
  home.file.".pi/agent/extensions/footer/index.ts".source = "${dotsDir}/pi/agent/extensions/footer/index.ts";
  home.file.".pi/agent/keybindings.json".source = "${dotsDir}/pi/agent/keybindings.json";
  home.file.".pi/agent/mcp.json".source = "${dotsDir}/pi/agent/mcp.json";
}
