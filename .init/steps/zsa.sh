#!/bin/bash

configure_zsa() {
	if [[ "$resZsa" == "y" ]]; then
		echo -e "${BLUE}Linking ZSA keyboard udev rules...${NC}"
		execute "sudo ln -s $HOME/.dotfiles/.udev/50-zsa.rules /etc/udev/rules.d/"

		echo -e "${BLUE}Syncing required group...${NC}"
		CURRENT_USER=$(logname)
		ZSA_GROUP=plugdev
		execute "sudo groupadd $ZSA_GROUP"
		execute "sudo usermod -aG $ZSA_GROUP $CURRENT_USER"
	fi
}

