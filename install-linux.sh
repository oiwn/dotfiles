#!/bin/bash

# constants
MINICONDA_FILE="Miniconda3-py39_4.9.2-Linux-x86_64.sh"

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y gnupg apt-transport-https ca-certificates curl lsb-release libjemalloc2 libjemalloc-dev gcc make

# ================================
# install docker
# ================================

# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get install docker-ce docker-ce-cli containerd.io

# install zsh & oh-my-zsh
sudo apt-get -y install zsh
chsh -s $(which zsh)
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --skip-chsh

# install configs and soft
sudo apt-get install -y tmux fzf
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt-get update
sudo apt-get install -y neovim

sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# theme for zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

git clone https://github.com/oiwn/dotfiles.git
cd dotfiles
make install

# install conda
MINICONDA_FILE="Miniconda3-py311_23.11.0-2-MacOSX-x86_64.sh"
MINICONDA_DIR="~/miniconda3"

cd ~
if [ -d "$MINICONDA_DIR" ]; then rm -Rf $MINICONDA_DIR; fi
wget https://repo.anaconda.com/miniconda/$MINICONDA_FILE
chmod 755 $MINICONDA_FILE
exec ~/$MINICONDA_FILE -b -p
rm $MINICONDA_FILE


