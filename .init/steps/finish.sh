#!/bin/bash

final_message() {
	if [[ "$resFinishOutput" == "y" ]]; then
		echo
		echo -e "${RED}------=============================================================================------"
		echo "------======                            FINISHED                             ======------"
		echo "------=============================================================================------"

		if $dry_run; then
			echo
			echo -e "${RED}!!! THIS WAS JUST A DRY RUN, NOTHING ACTUALLY HAPPENED ON THE MACHINE !!!${NC}"
			echo
		fi

		echo -e "${BLUE}System initialization is complete! Please install the following programs manually:${GREEN}"
		echo
		echo " - JetBrains IntelliJ"
		echo " - JetBrains WebStorm"
		echo " - Super Productivity"
		echo " - Rclone (manual setup for ProtonDrive)"
		echo
		echo -e "${BLUE}Also configure the following if needed:${GREEN}"
		echo
		echo " - Proton GE"
		echo " - Heroic game launcher"
		echo " - Rclone config"
		echo
		echo -e "${BLUE}(If using Nobara, remember to only update via 'Update System' from Glorious Eggroll)${NC}"
	fi

	echo
	echo -e "Exiting...${NC}"
}

