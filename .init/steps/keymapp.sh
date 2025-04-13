#!/bin/bash

install_keymapp() {
	if [[ "$resKeymapp" == "y" ]]; then
		echo -e "${BLUE}Downloading and setting up Keymapp...${NC}"
		KEYMAPP_URL="https://oryx.nyc3.cdn.digitaloceanspaces.com/keymapp/keymapp-latest.tar.gz"
		KEYMAPP_DIR="/opt/keymapp-latest"

		echo -e "${BLUE}Removing old Keymapp installation...${NC}"
		execute "sudo rm -rf ${KEYMAPP_DIR}"
		execute "sudo rm -f /usr/share/applications/keymapp.desktop"
		execute "sudo update-desktop-database"

		execute "sudo mkdir -p ${KEYMAPP_DIR}"
		execute "sudo curl -L ${KEYMAPP_URL} -o /tmp/keymapp.tar.gz"
		execute "sudo tar xfz /tmp/keymapp.tar.gz -C ${KEYMAPP_DIR}"

		DESKTOP_ENTRY=\"[Desktop Entry]
Name=Keymapp
Comment=ZSA Keyboard Configuration Tool
Exec=${KEYMAPP_DIR}/keymapp
Icon=${KEYMAPP_DIR}/icon.png
Terminal=false
Type=Application
Categories=Utility;\"

		echo -e "${BLUE}Creating desktop entry...${NC}"
		execute "echo \"$DESKTOP_ENTRY\" | sudo tee /usr/share/applications/keymapp.desktop"
		execute "sudo chmod +x ${KEYMAPP_DIR}/keymapp"
		execute "sudo update-desktop-database"
	fi
}

