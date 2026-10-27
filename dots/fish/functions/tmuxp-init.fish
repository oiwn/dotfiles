function tmuxp-init --description "Bootstrap ./.tmuxp.yaml from the rust template"
    if test -e .tmuxp.yaml
        echo "tmuxp-init: ./.tmuxp.yaml already exists — leaving it alone" >&2
        return 1
    end
    if not test -r ~/.config/tmuxp/rust.yaml
        echo "tmuxp-init: template ~/.config/tmuxp/rust.yaml not found (darwin-rebuild switch installs it)" >&2
        return 1
    end

    set -l name (basename $PWD)
    if set -q argv[1]
        set name $argv[1]
    end

    string replace -r '^session_name: pick-a-name$' "session_name: $name" \
        < ~/.config/tmuxp/rust.yaml > .tmuxp.yaml
    echo "tmuxp-init: wrote .tmuxp.yaml (session_name: $name)"
end
