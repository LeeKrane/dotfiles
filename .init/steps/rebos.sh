#!/bin/bash

run_rebos() {
	if [[ "$resRebosSetup" == "y" ]]; then
		echo -e "${BLUE}Installing Rebos for the remaining system packages:${NC}"
		execute "cargo install rebos"
		execute "echo \"export PATH='/home/$USER/.cargo/bin/:$PATH'\" > ~/.dotfiles/.krane-rc/bash/local-paths"
		echo -e "${BLUE}Running initial Rebos setup:${NC}"
		execute "rebos setup"
		execute "rebos config init"
		execute "rebos gen commit \"[sys-init] automatic initial base system configuration\""
	fi

	if [[ "$resRebosInstall" == "y" ]]; then
		echo -e "${BLUE}Installing the remaining system packages via Rebos:${NC}"
		execute "rebos gen current build"
	fi
}

