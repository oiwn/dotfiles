#!/bin/bash

# constants
MINICONDA_FILE="Miniconda3-py311_23.11.0-2-MacOSX-x86_64.sh"

# create folders
cd ~ && mkdir code && mkdir code/tmp

# install fonts
cd ~/code/tmp && git clone git clone https://github.com/powerline/fonts
cd ~/code/tmp/fonts && ./install.sh

# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install necessary utils
brew install htop nmap mosh tmux ripgrep fd midnight-commander git
# required for python library shapely
brew install geos universal-ctags

# install mongodb
brew tap mongodb/brew
brew install mongodb-community

# docker
brew install docker

# install neovim
brew install neovim

# install software
brew install --cask warp
brew install --cask dash
brew install --cask cocoarestclient
