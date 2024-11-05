current_dir := `pwd`

install:
    mkdir -p ~/.config/nvim/
    mkdir -p ~/.config/alacritty/
    mkdir -p ~/.config/helix/
    mkdir -p ~/.config/zellij
    ln -sf {{current_dir}}/dots/init.lua ~/.config/nvim/init.lua
    ln -sf {{current_dir}}/dots/.tmux.conf ~/.tmux.conf
    ln -sf {{current_dir}}/dots/.editorconfig ~/.editorconfig
    ln -sf {{current_dir}}/dots/.condarc ~/.condarc
    ln -sf {{current_dir}}/dots/alacritty.yml ~/.config/alacritty/alacritty.yml
    ln -sf {{current_dir}}/dots/helix.toml ~/.config/helix/config.toml
    ln -sf {{current_dir}}/dots/languages.toml ~/.config/helix/languages.toml
    ln -sf {{current_dir}}/dots/zellij.kdl ~/.config/zellij/config.kdl

scan:
	detect-secrets scan --use-all-plugins --all-files dots/ > .secrets.baseline
