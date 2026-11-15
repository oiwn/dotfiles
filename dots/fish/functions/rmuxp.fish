function rmuxp --description "tmuxp load -d + native rmux attach (rmuxp load <file>, e.g. rmuxp load .)"
    # tmuxp's own attach pipes stdio — rmux draws UI to stdout and hangs
    # (real tmux opens /dev/tty). Build detached, then attach natively with
    # an explicit target — bare `rmux attach` would target the most-
    # recently-used session, not the just-created one. Session name is read
    # from ./.tmuxp.yaml in the current dir. Missing tail (rmuxp load) or
    # workspace → tmuxp errors and `and` skips the attach.
    # Details: specs/ctx.md "rmux tmux-replacement trial".
    command tmuxp load -d $argv[2..-1]
    and rmux attach -t (string match -r '^session_name:\s*(.+)$' <.tmuxp.yaml)[-1]
end
