#!/bin/bash

link_dotfiles() {
	echo -e "${BLUE}Linking your dotfiles via stow...${NC}"
	execute "mkdir -p $HOME/.config/nvim"
	execute "mkdir -p $HOME/.local/share/nvim"
	execute "mkdir -p $HOME/.config/systemd/user"
	execute "cd ~/.dotfiles"
	execute "stow --adopt ."
	execute "git reset --hard"
	execute "cd"
}

