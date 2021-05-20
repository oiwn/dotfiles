#!/bin/bash

# constants
MINICONDA_FILE="Miniconda3-py39_4.9.2-Linux-x86_64.sh"


# install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install necessary utils
brew install fzf exa htop nmap mosh

# install neovim
brew install neovim
