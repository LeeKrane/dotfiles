#!/bin/bash

NC="\033[0m" # no color
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"

echo -e "${BLUE}Always clone the dotfiles repository as ~/.dotfiles"
echo -e "Run this script without sudo. Rebos won't work if this script is run as sudo.${NC}"
echo
echo

# input validation function
validate_input() {
	local input="$1"
	case "$input" in
	y | Y | yes | Yes | YES | n | N | no | No | NO | "")
		return 0 # Valid input
		;;
	*)
		return 1 # Invalid input
		;;
	esac
}

# input meaning function
get_input() {
	local input="$1"
	case "$input" in
	y | Y | yes | Yes | YES | "")
		return 0 # Execute script part
		;;
	*)
		return 1 # Skip script part
		;;
	esac
}

# Declare an associative array to map variables to prompts
declare -A prompts=(
	[resBtrfsRoot]="Do you want to create a BTRFS snapshot of '/' (@) before running the install script?"
	[resBtrfsHome]="Do you want to create a BTRFS snapshot of '/home' (@home) before running the install script?"
	[resLinkDotfiles]="Do you want to link your dotfiles?"
	[resRepositories]="Do you want to enable all dnf repositories?"
	[resGrubTheme]="Do you want to enable the custom GRUB theme?"
	[resPlymouthTheme]="Do you want to enable the custom Plymouth theme?"
	[resRebosSetup]="Do you want to run the Rebos setup?"
	[resRebosInstall]="Do you want to install all programs using Rebos?"
	[resZshInstall]="Do you want to install ZSH?"
	[resZshPlugins]="Do you want to install Zsh plugins?"
	[resRclone]="Do you want to setup rclone for ProtonDrive?"
	[resFinishOutput]="Do you want the final finish message?"
)

# Define an ordered list of keys
ordered_keys=(
	resBtrfsRoot
	resBtrfsHome
	resLinkDotfiles
	resRepositories
	resGrubTheme
	resPlymouthTheme
	resRebosSetup
	resRebosInstall
	resZshInstall
	resZshPlugins
	resRclone
	resFinishOutput
)

# Collect user inputs in the defined order
for var in "${ordered_keys[@]}"; do
	while true; do
		read -p "${prompts[$var]} (y/n or empty for yes): " response
		if validate_input "$response"; then
			eval "$var=\"$response\"" # Assign response to the corresponding variable
			break
		else
			echo "Invalid input. Please enter y/Y/yes/Yes/YES or n/N/no/No/NO (empty counts as no)."
		fi
	done
done
echo
echo

# btrfs snapshot /
if get_input "$resBtrfsRoot"; then
	MOUNT_POINT="/"
	SNAPSHOT_NAME="root_snapshot_$(date +%Y%m%d%H%M%S)" # Snapshot name with current timestamp

	# Check if BTRFS is mounted at the specified mount point
	if mount | grep -q "$MOUNT_POINT"; then
		# Create needed directories if needed
		sudo mkdir -p "$MOUNT_POINT/.snapshots/"
		# Create the snapshot
		sudo btrfs subvolume snapshot "$MOUNT_POINT" "$MOUNT_POINT/.snapshots/$SNAPSHOT_NAME"
		echo -e "${GREEN}Snapshot '$SNAPSHOT_NAME' created successfully!${NC}"
	else
		echo -e "${RED}Error: BTRFS is not mounted at $MOUNT_POINT.${NC}"
	fi
else
	echo -e "${GREEN}Skipped ROOT BTRFS snapshot creation.${NC}"
fi
echo
echo

# btrfs snapshot /home
if get_input "$resBtrfsHome"; then
	MOUNT_POINT="/home"
	SNAPSHOT_NAME="home_snapshot_$(date +%Y%m%d%H%M%S)" # Snapshot name with current timestamp

	# Check if BTRFS is mounted at the specified mount point
	if mount | grep -q "$MOUNT_POINT"; then
		# Create needed directories if needed
		sudo mkdir -p "$MOUNT_POINT/.snapshots/"
		# Create the snapshot
		sudo btrfs subvolume snapshot "$MOUNT_POINT" "$MOUNT_POINT/.snapshots/$SNAPSHOT_NAME"
		echo -e "${GREEN}Snapshot '$SNAPSHOT_NAME' created successfully!${NC}"
	else
		echo -e "${RED}Error: BTRFS is not mounted at $MOUNT_POINT.${NC}"
	fi
else
	echo -e "${GREEN}Skipped HOME BTRFS snapshot creation.${NC}"
fi
echo
echo

# initial programs
echo -e "${BLUE}Installing initial programs needed for system setup:${NC}"
sudo dnf -y install stow cargo plymouth-plugin-script
echo
echo

# dotfiles
if get_input "$resLinkDotfiles"; then
	echo -e "${BLUE}Creating folders for your dotfiles...${NC}"
	mkdir -p $HOME/.config/nvim
	mkdir -p $HOME/.local/share/nvim
	mkdir -p $HOME/.config/systemd/user
	echo
	echo
	echo -e "${BLUE}Linking your dotfiles via stow...${NC}"
	cd ~/.dotfiles
	stow --adopt .
	git reset --hard
	cd
else
	echo -e "${GREEN}Skipped dotfiles linking.${NC}"
fi
echo
echo

# important repositories and keys for rebos
if get_input "$resRepositories"; then
	echo -e "${BLUE}Adding needed dnf repositories, copr repositories and rpm keys:${NC}"
	# terra
	sudo dnf -y config-manager addrepo --from-repofile=https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo
	sudo dnf -y --refresh upgrade
	sudo dnf -y install terra-release

	# docker
	sudo dnf -y config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
	sudo dnf -y --refresh upgrade
	#sudo usermod -a -G docker krane

	# lazygit
	sudo dnf -y copr enable atim/lazygit

	# zen-browser
	sudo dnf -y copr enable sneexy/zen-browser

	# vs code
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
	dnf -y check-update
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi
echo
echo

# grub 2 theme
if get_input "$resGrubTheme"; then
	echo -e "${BLUE}Generating custom grub2 theme...${NC}"
	sudo mkdir /boot/grub2/themes
	sudo cp -r ~/.dotfiles/.grub-themes/CyberEXS/ /boot/grub2/themes/
	sudo cp ~/.dotfiles/.grub /etc/default/grub
	sudo grub2-mkconfig -o /boot/grub2/grub.cfg
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi
echo
echo

# plymouth theme
if get_input "$resPlymouthTheme"; then
	echo -e "${BLUE}Generating custom plymouth boot screen theme...${NC}"
	sudo cp -r ~/.dotfiles/.plymouth-themes/lone /usr/share/plymouth/themes/
	sudo plymouth-set-default-theme lone
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi
echo
echo

# rebos setup for remaining programs
if get_input "$resRebosSetup"; then
	echo -e "${BLUE}Installing Rebos for the remaining system packages:${NC}"
	cargo install rebos
	echo "export PATH='/home/$USER/.cargo/bin/:$PATH'" >.krane-rc/bash/local-paths
	echo
	echo -e "${BLUE}Running initial Rebos setup:${NC}"
	rebos setup
	rebos config init
	rebos gen commit "[sys-init] automatic initial base system configuration"
else
	echo -e "${GREEN}Skipped Rebos setup.${NC}"
fi
echo
echo

# remaining program install via rebos
if get_input "$resRebosInstall"; then
	echo -e "${BLUE}Installing the remaining system packages via Rebos:${NC}"
	rebos gen current build
else
	echo -e "${GREEN}Skipped Rebos system package install.${NC}"
fi
echo
echo

if get_input "$resZshInstall"; then
	echo -e "${BLUE}Changing default shell to zsh and installing oh-my-zsh...${NC}"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	echo -e "${GREEN}Skipped ZSH install.${NC}"
fi
echo
echo

if get_input "$resZshPlugins"; then
	echo -e "${BLUE}Installing oh-my-zsh plugins...${NC}"
	cd
	sudo rm -rf $ZSH_CUSTOM/plugins/zsh-autosuggestions && sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
	sudo rm -rf $ZSH_CUSTOM/plugins/zsh-syntax-highlighting && sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
	sudo rm -rf $ZSH_CUSTOM/themes/powerlevel10k && sudo git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
else
	echo -e "${GREEN}Skipped ZSH install.${NC}"
fi
echo
echo

if get_input "$resZshInstall" || get_input "$resZshPlugins"; then
	echo -e "${BLUE}Replacing automatically overwritten .zshrc file with that from dotfiles...${NC}"
	touch $HOME/.dotfiles/.krane-rc/bash/local-paths
	touch $HOME/.dotfiles/.krane-rc/zsh/local-paths
	rm $HOME/.zshrc
	cd $HOME/.dotfiles/
	stow .
else
	echo -e "${GREEN}Skipped .zshrc fixup.${NC}"
fi
echo
echo

if get_input "$resRclone"; then
	echo -e "${BLUE}Creating btrfs subvolume for ProtonDrive...${NC}"
	CURRENT_USER=$(logname)
	CURRENT_GROUP=$(id -gn "$CURRENT_USER")
	sudo btrfs sub create /@protondrive
	sudo chown -R "$CURRENT_USER:$CURRENT_GROUP" /@protondrive

	echo -e "${BLUE}Enabling rclone ProtonDrive sync service...${NC}"
	chmod +x $HOME/.dotfiles/.proton-drive-rclone-mount.sh
	systemctl --user daemon-reload
	systemctl --user enable proton-drive-mount.service
else
	echo -e "${GREEN}Skipped rclone ProtonDrive sync enabling.${NC}"
fi
echo
echo

if get_input "$resFinishOutput"; then
	echo -e "${RED}------=============================================================================------"
	echo "------======                            FINISHED                             ======------"
	echo "------=============================================================================------"
	echo
	echo -e "${BLUE}System initialization is complete! Please install the following programs manually:${GREEN}"
	echo
	echo " - JetBrains IntelliJ					(https://www.jetbrains.com/idea/download/?section=linux)"
	echo " - JetBrains WebStorm					(https://www.jetbrains.com/webstorm/download/#section=linux)"
	echo " - Super Productivity					(https://github.com/johannesjo/super-productivity/releases)"
	echo " - ProtonMail							(https://account.proton.me/u/0/mail/get-the-apps)"
	echo " - Rclone (manual for ProtonDrive)	(https://rclone.org/downloads/)"
	echo
	echo -e "${BLUE}Also configure the following (or install if not using Nobara):${GREEN}"
	echo
	echo " - Proton GE"
	echo " - Lutris game launcher (for EA, Ubisoft, Battle.net)"
	echo " - Heroic game launcher (for Epic Games, GOG, Prime Gaming)"
	echo " - Rclone (rclone config) (for ProtonDrive sync)"
	echo
	echo
	echo -e "${BLUE}(If using Nobara, remember to only update via the 'Update System' program provided by Glorious Eggroll)"
else
	echo -e "${GREEN}Skipped finish output.${NC}"
fi
echo
echo
echo -e "Exiting...${NC}"
