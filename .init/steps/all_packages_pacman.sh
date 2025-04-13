#!/bin/bash

install_all_packages() {
	echo -e "${BLUE}Installing all packages:${NC}"
	sudo pacman -S --needed \
		ungoogled-chromium-bin \
		zen-browser \
		gvfs-onedrive \
		openjdk21-src \
		openjdk21-doc \
		python-pip \
		docker \
		docker-buildx \
		docker-compose \
		ttf-jetbrains-mono \
		ttf-jetbrains-mono-nerd \
		neovim \
		code \
		zed \
		git \
		lazygit \
		gitleaks \
		git-delta \
		alacritty \
		cargo \
		flatpak \
		stow \
		zsh \
		nodejs \
		snapper \
		fzf \
		ncdu \
		exa \
		bat \
		ripgrep \
		zoxide \
		mc \
		btop \
		tealdeer \
		thefuck \
		fastfetch \
		jpegoptim \
		optipng \
		wireguard-tools \
		obs-studio \
		flameshot \
		vlc \
		virt-manager \
		audacity \
		pre-commit \
		python-toml \
		bunjs-bin \
		yarn \
		pnpm

	cargo install du-dust toipe

	flatpak install -y \
		bottles \
		com.spotify.Client \
		dev.vencord.Vesktop \
		page.kramo.Cartridges \
		com.jeffser.Alpaca \
		dev.bragefuglseth.Keypunch \
		com.dec05eba.gpu_screen_recorder \
		io.missioncenter.MissionCenter \
		com.notesnook.Notesnook \
		io.gitlab.theevilskeleton.Upscaler \
		no.mifi.losslesscut \
		com.heroicgameslauncher.hgl
}
