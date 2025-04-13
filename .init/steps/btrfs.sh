#!/bin/bash

run_btrfs() {
	if [[ "$resBtrfsRoot" == "y" ]]; then
		MOUNT_POINT="/"
		SNAPSHOT_NAME="root_snapshot_$(date +%Y%m%d%H%M%S)"
		if mount | grep -q "$MOUNT_POINT"; then
			execute "sudo mkdir -p \"$MOUNT_POINT/.snapshots/\""
			execute "sudo btrfs subvolume snapshot \"$MOUNT_POINT\" \"$MOUNT_POINT/.snapshots/$SNAPSHOT_NAME\""
			execute_non_verbose "echo -e \"${GREEN}Snapshot '$SNAPSHOT_NAME' created successfully!${NC}\""
		else
			echo -e "${RED}Error: BTRFS is not mounted at $MOUNT_POINT.${NC}"
		fi
	fi

	if [[ "$resBtrfsHome" == "y" ]]; then
		MOUNT_POINT="/home"
		SNAPSHOT_NAME="home_snapshot_$(date +%Y%m%d%H%M%S)"
		if mount | grep -q "$MOUNT_POINT"; then
			execute "sudo mkdir -p \"$MOUNT_POINT/.snapshots/\""
			execute "sudo btrfs subvolume snapshot \"$MOUNT_POINT\" \"$MOUNT_POINT/.snapshots/$SNAPSHOT_NAME\""
			execute_non_verbose "echo -e \"${GREEN}Snapshot '$SNAPSHOT_NAME' created successfully!${NC}\""
		else
			echo -e "${RED}Error: BTRFS is not mounted at $MOUNT_POINT.${NC}"
		fi
	fi
}

