# Current Task Context: dotfiles CLI — rmux workspace loader

Active track: specs/tracks/dotfiles-cli.md — all agent work done through unit 3 (rebuilt after the filter-repo incident); waiting on the user's apply steps.

## Next

User applies: `git add -A && git commit` **first**, then `git push --force origin master nix` (history was rewritten), then on kodo `git fetch && git reset --hard origin/<branch>`. Then `just install-tool`, `sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)`, `brew uninstall tmux tmuxp`. Post-switch checks: `command -v tmux` empty, `dotfiles ws load` in a real project attaches fullscreen, `dotfiles ws init` uses `~/.config/dotfiles/ws.ron`. Open decision: report the rmux attach bug upstream (repro in the track's unit Notes).
