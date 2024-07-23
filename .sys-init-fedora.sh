#!/bin/bash

# initial programs
sudo dnf -y install stow cargo

# dotfiles
cd
git clone https://gitlab.kradev.net/krane/dotfiles.git .dotfiles
cd ~/.dotfiles
stow .
cd

# important repositories and keys for rebos
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

# rebos for remaining programs
cargo install rebos
rebos gen current build
