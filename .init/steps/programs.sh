#!/bin/bash

install_initial_programs() {
	echo -e "${BLUE}Installing initial programs needed for system setup:${NC}"
	if $PKG_IS_DNF; then
		execute "sudo dnf -y install stow cargo plymouth-plugin-script"
	elif $PKG_IS_PACMAN; then
		execute "sudo pacman -S --noconfirm stow cargo"
	fi
}

