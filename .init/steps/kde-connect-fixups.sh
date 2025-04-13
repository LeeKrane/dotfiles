#!/bin/bash

kde_connect_fixups() {
	echo -e "${BLUE}Opening ports for KDE Connect...${NC}"
	execute "sudo ufw allow 1714:1764/tcp"
	execute "sudo ufw allow 1714:1764/udp"
	execute "sudo ufw reload"
	echo
}
