#!/bin/bash

echo "Always clone the dotfiles repository as ~/.dotfiles"
echo "Run this script without sudo. Rebos won't work if this script is run as sudo."
echo
echo

# initial programs
echo "Installing initial programs needed for system setup:"
sudo dnf -y install stow cargo
echo
echo

# dotfiles
echo "Linking your dotfiles via stow..."
cd ~/.dotfiles
stow --adopt .
git reset --hard
source ~/.bashrc
cd
echo
echo

# important repositories and keys for rebos
echo "Adding needed dnf repositories and rpm keys:"
# terra
sudo dnf config-manager --add-repo https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo
sudo dnf --refresh upgrade
sudo dnf -y install terra-release

# docker
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf --refresh upgrade
sudo usermod -a -G docker krane

# vs code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
dnf check-update

echo
echo

# rebos for remaining programs
echo "Installing Rebos for the remaining system packages:"
cargo install rebos
echo "export \$PATH='/home/krane/.cargo/bin:\$PATH'" > .krane-rc/local-paths
source ~/.bashrc
echo
echo "Installing the remaining system packages via Rebos:"
rebos gen current build
echo
echo "System initialization is complete! Please manually install the following programs:"
echo
echo " - JetBrains IntelliJ"
echo " - JetBrains WebStorm"
echo
echo "(If using Nobara, remember to only update via the 'Update System' program provided by Glorious Egroll)"
echo "Exiting..."
