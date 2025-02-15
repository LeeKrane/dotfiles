#!/bin/bash

# -------------------------------------------------------------------------------------------------
# /////////////////////////////////////////////////////////////////////////////////////////////////
# ///////////////////////////////////// *** Definitions *** ///////////////////////////////////////
# /////////////////////////////////////////////////////////////////////////////////////////////////
# -------------------------------------------------------------------------------------------------

NC="\033[0m" # no color
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
CLEAR_LINE="\r\033[K"

# Cleanup function to restore terminal settings
cleanup() {
	stty "$OLD_SETTINGS"
	tput cnorm
	echo -e "\n\n${RED}Script interrupted.${NC}"
	exit 1
}

# Function to display a single checkbox menu and get user selection
choose_single_checkbox() {
	local prompt="$1"
	local checked="$2"

	while true; do
		printf $CLEAR_LINE
		echo -n -e "${GREEN}> [${checked}] $prompt${NC}"

		# Read a single character
		key=$(dd bs=1 count=1 2>/dev/null)

		case "$key" in
		" ") # Space
			if [ "$checked" == " " ]; then
				checked="x"
			else
				checked=" "
			fi
			continue
			;;
		$'\r') # Enter
			printf $CLEAR_LINE
			echo -n "  [${checked}] $prompt"
			if [ "$checked" == "x" ]; then
				return 0
			else
				return 1
			fi
			break
			;;
		q) # Quit
			cleanup
			exit 1
			;;
		esac
	done
}

# Declare an associative array to map variables to prompts
declare -A prompts=(
	[resBtrfsRoot]="Create BTRFS snap @?"
	[resBtrfsHome]="Create BTRFS snap @home?"
	[resInitPrograms]="Install initial programs?"
	[resLinkDotfiles]="Link dotfiles?"
	[resRepositories]="Enable dnf repos?"
	[resGrubTheme]="Enable GRUB theme?"
	[resPlymouthTheme]="Enable Plymouth theme?"
	[resRebosSetup]="Run Rebos setup?"
	[resRebosInstall]="Install all programs using Rebos?"
	[resZshInstall]="Install ZSH?"
	[resZshPlugins]="Install ZSH plugins?"
	[resRclone]="Setup rclone for ProtonDrive?"
	[resZsa]="Setup ZSA keyboard udev rules?"
	[resFinishOutput]="Show final finish message?"
)

# Define an ordered list of keys
ordered_keys=(
	resBtrfsRoot
	resBtrfsHome
	resInitPrograms
	resLinkDotfiles
	resRepositories
	resGrubTheme
	resPlymouthTheme
	resRebosSetup
	resRebosInstall
	resZshInstall
	resZshPlugins
	resRclone
	resZsa
	resFinishOutput
)

# --------------------------------------------------------------------------------------------------
# //////////////////////////////////////////////////////////////////////////////////////////////////
# ////////////////////////////////////// *** Selection *** /////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////////////////////////////////
# --------------------------------------------------------------------------------------------------

echo -e "${BLUE}Always clone the dotfiles repository as ~/.dotfiles"
echo -e "Run this script without sudo. Rebos won't work if this script is run as sudo.${NC}"
echo
echo
echo -e "${BLUE}Press ${GREEN}Space${BLUE} to toggle, ${GREEN}Enter${BLUE} to confirm and ${GREEN}q${BLUE} to quit:${NC}"
echo

# Hide cursor
tput civis
# Save current terminal settings
OLD_SETTINGS=$(stty -g)
# Disable canonical mode (line buffering) and echoing
stty raw -echo

# Collect user inputs in the defined order
default_checkbox_value="x"
if choose_single_checkbox "Checkboxes by default toggled?" "x"; then
	default_checkbox_value="x"
else
	default_checkbox_value=" "
fi
echo
echo

for var in "${ordered_keys[@]}"; do
	if choose_single_checkbox "${prompts[$var]}" "$default_checkbox_value"; then
		eval "$var=y" # Assign 'y' to the variable
	else
		eval "$var=n" # Assign 'n' to the variable
	fi
	echo
done

# Restore original terminal settings
stty "$OLD_SETTINGS"
# Show cursor
tput cnorm
echo
echo

# --------------------------------------------------------------------------------------------------
# //////////////////////////////////////////////////////////////////////////////////////////////////
# ///////////////////////////////////// *** Installation *** ///////////////////////////////////////
# //////////////////////////////////////////////////////////////////////////////////////////////////
# --------------------------------------------------------------------------------------------------

# btrfs snapshot /
if [[ "$resBtrfsRoot" == "y" ]]; then
	echo
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
	echo
else
	echo -e "${GREEN}Skipped ROOT BTRFS snapshot creation.${NC}"
fi

# btrfs snapshot /home
if [[ "$resBtrfsHome" == "y" ]]; then
	echo
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
	echo
else
	echo -e "${GREEN}Skipped HOME BTRFS snapshot creation.${NC}"
fi

# initial programs
if [[ "$resInitPrograms" == "y" ]]; then
	echo
	echo -e "${BLUE}Installing initial programs needed for system setup:${NC}"
	sudo dnf -y install stow cargo plymouth-plugin-script
	echo
else
	echo -e "${GREEN}Skipped initial program installation.${NC}"
fi

# dotfiles
if [[ "$resLinkDotfiles" == "y" ]]; then
	echo
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
	echo
else
	echo -e "${GREEN}Skipped dotfiles linking.${NC}"
fi

# important repositories and keys for rebos
if [[ "$resRepositories" == "y" ]]; then
	echo
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
	echo
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi

# grub 2 theme
if [[ "$resGrubTheme" == "y" ]]; then
	echo
	echo -e "${BLUE}Generating custom grub2 theme...${NC}"
	sudo mkdir /boot/grub2/themes
	sudo cp -r ~/.dotfiles/.grub-themes/CyberEXS/ /boot/grub2/themes/
	sudo cp ~/.dotfiles/.grub /etc/default/grub
	sudo grub2-mkconfig -o /boot/grub2/grub.cfg
	echo
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi

# plymouth theme
if [[ "$resPlymouthTheme" == "y" ]]; then
	echo
	echo -e "${BLUE}Generating custom plymouth boot screen theme...${NC}"
	sudo cp -r ~/.dotfiles/.plymouth-themes/lone /usr/share/plymouth/themes/
	sudo plymouth-set-default-theme lone
	echo
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi

# rebos setup for remaining programs
if [[ "$resRebosSetup" == "y" ]]; then
	echo
	echo -e "${BLUE}Installing Rebos for the remaining system packages:${NC}"
	cargo install rebos
	echo "export PATH='/home/$USER/.cargo/bin/:$PATH'" >.krane-rc/bash/local-paths
	echo
	echo -e "${BLUE}Running initial Rebos setup:${NC}"
	rebos setup
	rebos config init
	rebos gen commit "[sys-init] automatic initial base system configuration"
	echo
else
	echo -e "${GREEN}Skipped Rebos setup.${NC}"
fi

# remaining program install via rebos
if [[ "$resRebosInstall" == "y" ]]; then
	echo
	echo -e "${BLUE}Installing the remaining system packages via Rebos:${NC}"
	rebos gen current build
	echo
else
	echo -e "${GREEN}Skipped Rebos system package install.${NC}"
fi

if [[ "$resZshInstall" == "y" ]]; then
	echo
	echo -e "${BLUE}Changing default shell to zsh and installing oh-my-zsh...${NC}"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	echo
else
	echo -e "${GREEN}Skipped ZSH install.${NC}"
fi

if [[ "$resZshPlugins" == "y" ]]; then
	echo
	echo -e "${BLUE}Installing oh-my-zsh plugins...${NC}"
	cd
	sudo rm -rf $ZSH_CUSTOM/plugins/zsh-autosuggestions && sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
	sudo rm -rf $ZSH_CUSTOM/plugins/zsh-syntax-highlighting && sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
	sudo rm -rf $ZSH_CUSTOM/themes/powerlevel10k && sudo git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
	echo
else
	echo -e "${GREEN}Skipped ZSH install.${NC}"
fi

if [[ "$resZshInstall" == "y" ]] || [[ "$resZshPlugins" == "y" ]]; then
	echo
	echo -e "${BLUE}Replacing automatically overwritten .zshrc file with that from dotfiles...${NC}"
	touch $HOME/.dotfiles/.krane-rc/bash/local-paths
	touch $HOME/.dotfiles/.krane-rc/zsh/local-paths
	rm $HOME/.zshrc
	cd $HOME/.dotfiles/
	stow .
	echo
else
	echo -e "${GREEN}Skipped .zshrc fixup.${NC}"
fi

if [[ "$resRclone" == "y" ]]; then
	echo
	echo -e "${BLUE}Creating btrfs subvolume for ProtonDrive...${NC}"
	CURRENT_USER=$(logname)
	CURRENT_GROUP=$(id -gn "$CURRENT_USER")
	sudo btrfs sub create /@protondrive
	sudo chown -R "$CURRENT_USER:$CURRENT_GROUP" /@protondrive

	echo -e "${BLUE}Enabling rclone ProtonDrive sync service...${NC}"
	chmod +x $HOME/.dotfiles/.proton-drive-rclone-mount.sh
	systemctl --user daemon-reload
	systemctl --user enable proton-drive-mount.service
	echo
else
	echo -e "${GREEN}Skipped rclone ProtonDrive sync enabling.${NC}"
fi

if [[ "$resZsa" == "y" ]]; then
	echo
	echo -e "${BLUE}Linking ZSA keyboard udev rules...${NC}"
	sudo ln -s $HOME/.dotfiles/.udev/50-zsa.rules /etc/udev/rules.d/

	echo -e "${BLUE}Syncing required group...${NC}"
	CURRENT_USER=$(logname)
	ZSA_GROUP=plugdev
	sudo groupadd $ZSA_GROUP
	sudo usermod -aG $ZSA_GROUP $CURRENT_USER
	echo
else
	echo -e "${GREEN}Skipped ZSA keyboard udev rules setup.${NC}"
fi

if [[ "$resFinishOutput" == "y" ]]; then
	echo
	echo -e "${RED}------=============================================================================------"
	echo "------======                            FINISHED                             ======------"
	echo "------=============================================================================------"
	echo
	echo -e "${BLUE}System initialization is complete! Please install the following programs manually:${GREEN}"
	echo
	echo " - JetBrains IntelliJ                 (https://www.jetbrains.com/idea/download/?section=linux)"
	echo " - JetBrains WebStorm                 (https://www.jetbrains.com/webstorm/download/#section=linux)"
	echo " - Super Productivity                 (https://github.com/johannesjo/super-productivity/releases)"
	echo " - ProtonMail                         (https://account.proton.me/u/0/mail/get-the-apps)"
	echo " - Rclone (manual for ProtonDrive)    (https://rclone.org/downloads/)"
	echo
	echo -e "${BLUE}Also configure the following (or install if not using Nobara):${GREEN}"
	echo
	echo " - Proton GE"
	echo " - Heroic game launcher (for Epic Games, GOG, Prime Gaming)"
	echo " - Rclone (rclone config) (for ProtonDrive sync)"
	echo
	echo
	echo -e "${BLUE}(If using Nobara, remember to only update via the 'Update System' program provided by Glorious Eggroll)"
else
	echo -e "${GREEN}Skipped finish output.${NC}"
fi
echo
echo -e "Exiting...${NC}"
