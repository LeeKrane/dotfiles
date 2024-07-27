#!/bin/bash

NC="\033[0m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"

echo -e "${BLUE}Always clone the dotfiles repository as ~/.dotfiles"
echo -e "Run this script without sudo. Rebos won't work if this script is run as sudo.${NC}"
echo
echo

# initial programs
echo -e "${BLUE}Installing initial programs needed for system setup:${NC}"
sudo dnf -y install stow cargo plymouth-plugin-script
echo
echo

# dotfiles
echo -e "${BLUE}Linking your dotfiles via stow...${NC}"
cd ~/.dotfiles
stow --adopt .
git reset --hard
source ~/.bashrc
cd
echo
echo

# important repositories and keys for rebos
echo -e "${BLUE}Adding needed dnf repositories, copr repositories and rpm keys:${NC}"
# terra
sudo dnf -y config-manager --add-repo https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo
sudo dnf -y --refresh upgrade
sudo dnf -y install terra-release

# docker
sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf -y --refresh upgrade
#sudo usermod -a -G docker krane

# heroic game launcher
sudo dnf -y copr enable atim/heroic-games-launcher

# vs code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
dnf -y check-update

echo
echo

# grub 2 theme
echo -e "${BLUE}Generating custom grub2 theme...${NC}"
sudo mkdir /boot/grub2/themes
sudo cp -r ~/.dotfiles/.grub-themes/CyberEXS/ /boot/grub2/themes/
sudo cp ~/.dotfiles/.grub /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
echo
echo

# plymouth theme
echo -e "${BLUE}Generating custom plymouth boot screen theme...${NC}"
sudo cp -r ~/.dotfiles/.plymouth-themes/lone /usr/share/plymouth/themes/
sudo plymouth-set-default-theme lone
echo
echo

# rebos for remaining programs
echo -e "${BLUE}Installing Rebos for the remaining system packages:${NC}"
cargo install rebos
echo "export PATH='/home/$USER/.cargo/bin/:$PATH'" >.krane-rc/bash/local-paths
echo "path=('/home/$USER/.cargo/bin/' $path)" >.krane-rc/zsh/local-paths
echo "export PATH" >.krane-rc/zsh/local-paths
source ~/.bashrc
echo
echo -e "${BLUE}Installing the remaining system packages via Rebos:${NC}"
rebos setup
rebos config init
rebos gen commit "[sys-init] automatic initial base system configuration"
rebos gen current build
echo
echo
echo -e "${BLUE}Changing default shell to zsh and installing oh-my-zsh...${NC}"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
rm $HOME/.zshrc
cd $HOME/.dotfiles/
stow .
echo
echo
echo -e "${BLUE}Installing oh-my-zsh plugins...${NC}"
cd
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
echo
echo
echo -e "${BLUE}System initialization is complete! Please install the following programs manually:${GREEN}"
echo
echo " - JetBrains IntelliJ					(https://www.jetbrains.com/idea/download/?section=linux)"
echo " - JetBrains WebStorm					(https://www.jetbrains.com/webstorm/download/#section=linux)"
echo " - [optional due to web ui] VIA		(https://github.com/the-via/releases/releases)"
echo
echo -e "${BLUE}Also configure the following (or install if not using Nobara):${GREEN}"
echo
echo " - Proton GE"
echo " - Lutris game launcher (for EA, Ubisoft, Battle.net)"
echo " - Heroic game launcher (for Epic Games, GOG, Prime Gaming)"
echo
echo
echo -e "${BLUE}(If using Nobara, remember to only update via the 'Update System' program provided by Glorious Eggroll)"
echo -e "Exiting...${NC}"
