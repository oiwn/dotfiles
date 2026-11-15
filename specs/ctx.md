# Current Task Context

## rmux tmux-replacement trial

State: rmux 0.10.0 (brew) shadows tmux in fish via `~/.config/rmux/shim/tmux` + `fish_add_path` (`home/terminal.nix`); `~/.config/rmux/rmux.conf` → `dots/.tmux.conf` (all directives supported, incl. `extended-keys csi-u`). Workspaces load via the `rmuxp` wrapper below.

- **Problem** — interactive `tmuxp load` hangs invisibly: libtmux's `session.attach()` spawns `attach-session` as a subprocess with piped stdio (auto `-t $0` = session id). Real tmux opens `/dev/tty` and renders anyway; rmux draws to stdout (the pipe) and blocks forever — no UI, tmuxp waits, daemon keeps a stale `(attached)` client.
- **Workaround (landed)** — fish `rmuxp` (`dots/fish/functions/rmuxp.fish`): `rmuxp load <file>` → `tmuxp load -d` on the tail, then native `rmux attach -t <name>` with the name read from `./.tmuxp.yaml` in the current dir. Missing tail/workspace → tmuxp errors, `and` skips attach. Bare `rmux attach` would be wrong — it targets the most-recently-*used* session, not the just-created one. A native non-Python loader is parked in `specs/ideas.md` ("Tiny native tmuxp loader").
- **To report upstream (rmux)** — `attach-session` should open `/dev/tty` when stdin/stdout aren't TTYs (tmux behavior), or fail fast instead of blocking. Repro: `script -q /dev/null sh -c 'timeout 3 tmux attach -t <session> > /dev/null 2>&1; echo $?'` → rmux: no output, exit 124; real tmux: UI renders to the pty. Env: rmux 0.10.0, macOS, fish, tmuxp 1.76/libtmux 0.62. Side note: `rmux doctor tmux-dropin` is argv[0]-based — run it as `tmux doctor tmux-dropin` (reports detected); its `~/.local/bin` suggestion loses to `/opt/homebrew/bin/tmux` on this setup.
- **If trial sticks** — update `specs/overview.md` multiplexer row; consider splitting `dots/rmux.conf` from `.tmux.conf` and retiring brew tmux (kept as tmuxp-formula dependency either way).
