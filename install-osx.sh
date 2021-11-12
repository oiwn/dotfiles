#!/bin/bash

# constants
MINICONDA_FILE="Miniconda3-py39_4.9.2-Linux-x86_64.sh"

# create folders
cd ~ && mkdir code && mkdir code/tmp

# install fonts
cd ~/code/tmp && git clone git clone https://github.com/powerline/fonts
cd ~/code/tmp/fonts && ./install.sh

# install ohmyzsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install necessary utils
brew install fzf exa htop nmap mosh tmux ripgrep midnight-commander

# install mongodb
brew tap mongodb/brew
brew install mongodb-community

# install redis
brew install redis

# docker
brew install docker

# install neovim and plug
brew install neovim
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# install software
brew install --cask iterm2
brew install --cask dash
brew install --cask cocoarestclient
