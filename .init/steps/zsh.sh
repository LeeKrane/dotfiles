#!/bin/bash

configure_zsh() {
	if [[ "$resZshInstall" == "y" ]]; then
		echo -e "${BLUE}Changing default shell to zsh and installing oh-my-zsh...${NC}"
		execute "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
	fi

	if [[ "$resZshPlugins" == "y" ]]; then
		echo -e "${BLUE}Installing oh-my-zsh plugins...${NC}"
		execute "cd"
		execute "sudo rm -rf \$ZSH_CUSTOM/plugins/zsh-autosuggestions && sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git \$ZSH_CUSTOM/plugins/zsh-autosuggestions"
		execute "sudo rm -rf \$ZSH_CUSTOM/plugins/zsh-syntax-highlighting && sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
		execute "sudo rm -rf \$ZSH_CUSTOM/themes/powerlevel10k && sudo git clone https://github.com/romkatv/powerlevel10k.git \$ZSH_CUSTOM/themes/powerlevel10k"
	fi

	if [[ "$resZshInstall" == "y" || "$resZshPlugins" == "y" ]]; then
		echo -e "${BLUE}Replacing automatically overwritten .zshrc file with that from dotfiles...${NC}"
		execute "touch $HOME/.dotfiles/.krane-rc/bash/local-paths"
		execute "touch $HOME/.dotfiles/.krane-rc/zsh/local-paths"
		execute "rm $HOME/.zshrc"
		execute "cd $HOME/.dotfiles/"
		execute "stow ."
	fi
}

