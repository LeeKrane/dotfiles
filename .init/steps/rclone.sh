#!/bin/bash

configure_rclone() {
	if [[ "$resRclone" == "y" ]]; then
		echo -e "${BLUE}Creating BTRFS subvolume for ProtonDrive...${NC}"
		CURRENT_USER=$(logname)
		CURRENT_GROUP=$(id -gn "$CURRENT_USER")
		execute "sudo btrfs sub create /@protondrive"
		execute "sudo chown -R \"$CURRENT_USER:$CURRENT_GROUP\" /@protondrive"

		echo -e "${BLUE}Enabling rclone ProtonDrive sync service...${NC}"
		execute "chmod +x $HOME/.dotfiles/.proton-drive-rclone-mount.sh"
		execute "systemctl --user daemon-reload"
		execute "systemctl --user enable proton-drive-mount.service"
	fi
}

