#!/bin/bash

NC="\033[0m"
BLUE="\033[1;34m"

echo "${BLUE}Always clone the dotfiles repository as ~/.dotfiles"
echo "Run this script without sudo. Rebos won't work if this script is run as sudo.${NC}"
echo
echo

# initial programs
echo "${BLUE}Installing initial programs needed for system setup:${NC}"
sudo dnf -y install stow cargo
echo
echo

# dotfiles
echo "${BLUE}Linking your dotfiles via stow...${NC}"
cd ~/.dotfiles
stow --adopt .
git reset --hard
source ~/.bashrc
cd
echo
echo

# important repositories and keys for rebos
echo "${BLUE}Adding needed dnf repositories and rpm keys:${NC}"
# terra
sudo dnf -y config-manager --add-repo https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo
sudo dnf -y --refresh upgrade
sudo dnf -y install terra-release

# docker
sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf -y --refresh upgrade
#sudo usermod -a -G docker krane

# vs code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
dnf -y check-update

echo
echo

# rebos for remaining programs
echo "${BLUE}Installing Rebos for the remaining system packages:${NC}"
cargo install rebos
echo "export PATH='/home/$USER/.cargo/bin/:$PATH'" > .krane-rc/local-paths
source ~/.bashrc
echo
echo "${BLUE}Installing the remaining system packages via Rebos:${NC}"
rebos setup
rebos gen commit "[sys-init] automatic initial base system configuration"
rebos gen current build
echo
echo "${BLUE}System initialization is complete! Please manually install the following programs:"
echo
echo " - JetBrains IntelliJ"
echo " - JetBrains WebStorm"
echo
echo "(If using Nobara, remember to only update via the 'Update System' program provided by Glorious Egroll)"
echo "Exiting...${NC}"
