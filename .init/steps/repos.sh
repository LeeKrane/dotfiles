#!/bin/bash

enable_repositories() {
	if $PKG_IS_DNF; then
		execute "sudo dnf -y config-manager addrepo --from-repofile=https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo"
		execute "sudo dnf -y --refresh upgrade"
		execute "sudo dnf -y install terra-release"
		execute "sudo dnf -y config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo"
		execute "sudo dnf -y copr enable atim/lazygit"
		execute "sudo dnf -y copr enable sneexy/zen-browser"
		execute "sudo dnf -y copr enable wojnilowicz/ungoogled-chromium"
		execute "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
		execute "echo -e \"[code]\nname=VS Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null"
	fi
}

