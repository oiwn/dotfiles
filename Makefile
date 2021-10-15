.PHONY: install scan

current_dir = $(shell pwd)

install:
	mkdir -p ~/.config/nvim/ && \
	ln -sf $(current_dir)/dots/init.vim ~/.config/nvim/init.vim && \
	ln -sf $(current_dir)/dots/.tmux.conf ~/.tmux.conf && \
	ln -sf $(current_dir)/dots/.editorconfig ~/.editorconfig && \
	ln -sf $(current_dir)/dots/.condarc ~/.condarc && \
	ln -sf $(current_dir)/dots/.zshrc ~/.zshrc && \
	ln -sf $(current_dir)/dots/.p10k.zsh ~/.p10k.zsh

scan:
	detect-secrets scan --use-all-plugins --all-files dots/ > .secrets.baseline
