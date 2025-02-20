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
CLEAR_5_LINES="\033[5A${CLEAR_LINE%K}J"
CLEAR_7_LINES="\033[7A${CLEAR_LINE%K}J"

# Function to display help message
show_help() {
	echo -e "${BLUE}Usage: $0 [options]${NC}"
	echo -e "${BLUE}Options:${NC}"
	echo -e "  -d, --dry-run   Perform a dry run, showing commands without executing them."
	echo -e "  -h, --help      Display this help message."
}

# Check for dry-run / help options
dry_run=false
while [[ $# -gt 0 ]]; do
	case "$1" in
	-d | --dry-run)
		dry_run=true
		shift
		;;
	-h | --help)
		show_help
		exit 0
		;;
	*)
		# Unknown option
		echo -e "${RED}Unknown option: $1${NC}"
		show_help
		exit 1
		;;
	esac
done

# Trap the SIGINT signal (CTRL+C)
trap cleanup INT

# Cleanup function to restore terminal settings
cleanup() {
	stty "$OLD_SETTINGS"
	tput cnorm
	echo -e "\n\n${RED}Script interrupted.${NC}"
	exit 1
}

# Function to display a menu and get user selection
choose_installation_mode() {
	local prompt="Choose installation mode:\n"
	local options=("Partial (default: YES)" "Partial (default: NO)" "Full (do everything)")
	local selected=0
	local num_options=${#options[@]}

	# Hide cursor
	tput civis

	while true; do
		echo -e "${BLUE}$prompt${NC}"
		for i in $(seq 0 $((num_options - 1))); do
			if [ "$i" -eq "$selected" ]; then
				echo -e "${GREEN}> ${options[$i]}${NC}"
			else
				echo "  ${options[$i]}"
			fi
		done

		read -s -n 1 key
		case "$key" in
		A) # Up arrow
			selected=$(((selected - 1 + num_options) % num_options))
			;;
		B) # Down arrow
			selected=$(((selected + 1) % num_options))
			;;
		"") # Enter
			printf $CLEAR_7_LINES
			# Show cursor
			tput cnorm
			echo -e "${BLUE}Chosen installation mode: ${options[$selected]}${NC}"
			echo
			return $selected
			;;
		q) # Quit
			cleanup
			exit 1
			;;
		esac

		printf $CLEAR_5_LINES
	done
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
	[resKeymapp]="Download latest Keymapp version?"
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
	resKeymapp
	resFinishOutput
)

# --------------------------------------------------------------------------------------------------
# //////////////////////////////////////////////////////////////////////////////////////////////////
# ////////////////////////////////////// *** Selection *** /////////////////////////////////////////
# //////////////////////////////////////////////////////////////////////////////////////////////////
# --------------------------------------------------------------------------------------------------

if $dry_run; then
	echo -e "${RED}!!! THIS IS JUST A DRY RUN, NOTHING WILL ACTUALLY HAPPEN ON THE MACHINE !!!${NC}"
	echo
	echo
fi

# Save current terminal settings
OLD_SETTINGS=$(stty -g)

echo -e "${BLUE}Always clone the dotfiles repository as ~/.dotfiles"
echo -e "Run this script without sudo. Rebos won't work if this script is run as sudo.${NC}"
echo

echo -e "${BLUE}Press ${GREEN}Enter${BLUE} to confirm or ${GREEN}q${BLUE} to quit:${NC}"
echo

# Choose the installation mode
choose_installation_mode

case "$?" in
0) # partial install with default toggled
	default_checkbox_value="x"
	full_install="n"
	;;
1) # partial install with default untoggled
	default_checkbox_value=" "
	full_install="n"
	;;
2) # full install
	default_checkbox_value="x"
	full_install="y"
	;;
*) # Quit
	cleanup
	exit 1
	;;
esac

# Hide cursor
tput civis
# Disable canonical mode (line buffering) and echoing
stty raw -echo

echo -e "${BLUE}Press ${GREEN}Space${BLUE} to toggle, ${GREEN}Enter${BLUE} to confirm and ${GREEN}q${BLUE} to quit:${NC}"
echo
# Collect user inputs and assign to variables directly
for var in "${ordered_keys[@]}"; do
	if [[ "$full_install" == "y" ]]; then
		eval "$var=y" # Assign 'y' to all variables
	else
		if choose_single_checkbox "${prompts[$var]}" "$default_checkbox_value"; then
			eval "$var=y" # Assign 'y' to the variable
		else
			eval "$var=n" # Assign 'n' to the variable
		fi
		echo
	fi
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

# Function to execute commands, respecting dry_run
execute() {
	local command="$1"
	echo -n -e " ${GREEN}>${NC} "
	echo "$command"
	if ! $dry_run; then
		eval "$command"
	fi
}

execute_non_verbose() {
	local command="$1"
	if ! $dry_run; then
		eval "$command"
	fi
}

# btrfs snapshot /
if [[ "$resBtrfsRoot" == "y" ]]; then
	echo
	MOUNT_POINT="/"
	SNAPSHOT_NAME="root_snapshot_$(date +%Y%m%d%H%M%S)" # Snapshot name with current timestamp

	# Check if BTRFS is mounted at the specified mount point
	if mount | grep -q "$MOUNT_POINT"; then
		# Create needed directories if needed
		execute "sudo mkdir -p \"$MOUNT_POINT/.snapshots/\""
		# Create the snapshot
		execute "sudo btrfs subvolume snapshot \"$MOUNT_POINT\" \"$MOUNT_POINT/.snapshots/$SNAPSHOT_NAME\""
		execute_non_verbose "echo -e \"${GREEN}Snapshot '$SNAPSHOT_NAME' created successfully!${NC}\""
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
		execute "sudo mkdir -p \"$MOUNT_POINT/.snapshots/\""
		# Create the snapshot
		execute "sudo btrfs subvolume snapshot \"$MOUNT_POINT\" \"$MOUNT_POINT/.snapshots/$SNAPSHOT_NAME\""
		execute_non_verbose "echo -e \"${GREEN}Snapshot '$SNAPSHOT_NAME' created successfully!${NC}\""
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
	execute "sudo dnf -y install stow cargo plymouth-plugin-script"
	echo
else
	echo -e "${GREEN}Skipped initial program installation.${NC}"
fi

# dotfiles
if [[ "$resLinkDotfiles" == "y" ]]; then
	echo
	echo -e "${BLUE}Creating folders for your dotfiles...${NC}"
	execute "mkdir -p $HOME/.config/nvim"
	execute "mkdir -p $HOME/.local/share/nvim"
	execute "mkdir -p $HOME/.config/systemd/user"
	echo
	echo
	echo -e "${BLUE}Linking your dotfiles via stow...${NC}"
	execute "cd ~/.dotfiles"
	execute "stow --adopt ."
	execute "git reset --hard"
	execute "cd"
	echo
else
	echo -e "${GREEN}Skipped dotfiles linking.${NC}"
fi

# important repositories and keys for rebos
if [[ "$resRepositories" == "y" ]]; then
	echo
	echo -e "${BLUE}Adding needed dnf repositories, copr repositories and rpm keys:${NC}"
	# terra
	execute "sudo dnf -y config-manager addrepo --from-repofile=https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo"
	execute "sudo dnf -y --refresh upgrade"
	execute "sudo dnf -y install terra-release"

	# docker
	execute "sudo dnf -y config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo"
	execute "sudo dnf -y --refresh upgrade"
	#sudo usermod -a -G docker krane

	# lazygit
	execute "sudo dnf -y copr enable atim/lazygit"

	# zen-browser
	execute "sudo dnf -y copr enable sneexy/zen-browser"

	# vs code
	execute "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
	execute "echo -e \"[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null"
	execute "dnf -y check-update"
	echo
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi

# grub 2 theme
if [[ "$resGrubTheme" == "y" ]]; then
	echo
	echo -e "${BLUE}Generating custom grub2 theme...${NC}"
	execute "sudo mkdir /boot/grub2/themes"
	execute "sudo cp -r ~/.dotfiles/.grub-themes/CyberEXS/ /boot/grub2/themes/"
	execute "sudo cp ~/.dotfiles/.grub /etc/default/grub"
	execute "sudo grub2-mkconfig -o /boot/grub2/grub.cfg"
	echo
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi

# plymouth theme
if [[ "$resPlymouthTheme" == "y" ]]; then
	echo
	echo -e "${BLUE}Generating custom plymouth boot screen theme...${NC}"
	execute "sudo cp -r ~/.dotfiles/.plymouth-themes/lone /usr/share/plymouth/themes/"
	execute "sudo plymouth-set-default-theme lone"
	echo
else
	echo -e "${GREEN}Skipped repository enabling.${NC}"
fi

# rebos setup for remaining programs
if [[ "$resRebosSetup" == "y" ]]; then
	echo
	echo -e "${BLUE}Installing Rebos for the remaining system packages:${NC}"
	execute "cargo install rebos"
	execute "echo \"export PATH='/home/$USER/.cargo/bin/:$PATH'\" >.krane-rc/bash/local-paths"
	echo
	echo -e "${BLUE}Running initial Rebos setup:${NC}"
	execute "rebos setup"
	execute "rebos config init"
	execute "rebos gen commit \"[sys-init] automatic initial base system configuration\""
	echo
else
	echo -e "${GREEN}Skipped Rebos setup.${NC}"
fi

# remaining program install via rebos
if [[ "$resRebosInstall" == "y" ]]; then
	echo
	echo -e "${BLUE}Installing the remaining system packages via Rebos:${NC}"
	execute "rebos gen current build"
	echo
else
	echo -e "${GREEN}Skipped Rebos system package install.${NC}"
fi

if [[ "$resZshInstall" == "y" ]]; then
	echo
	echo -e "${BLUE}Changing default shell to zsh and installing oh-my-zsh...${NC}"
	execute "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
	echo
else
	echo -e "${GREEN}Skipped ZSH install.${NC}"
fi

if [[ "$resZshPlugins" == "y" ]]; then
	echo
	echo -e "${BLUE}Installing oh-my-zsh plugins...${NC}"
	execute "cd"
	execute "sudo rm -rf $ZSH_CUSTOM/plugins/zsh-autosuggestions && sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions"
	execute "sudo rm -rf $ZSH_CUSTOM/plugins/zsh-syntax-highlighting && sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
	execute "sudo rm -rf $ZSH_CUSTOM/themes/powerlevel10k && sudo git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k"
	echo
else
	echo -e "${GREEN}Skipped ZSH install.${NC}"
fi

if [[ "$resZshInstall" == "y" ]] || [[ "$resZshPlugins" == "y" ]]; then
	echo
	echo -e "${BLUE}Replacing automatically overwritten .zshrc file with that from dotfiles...${NC}"
	execute "touch $HOME/.dotfiles/.krane-rc/bash/local-paths"
	execute "touch $HOME/.dotfiles/.krane-rc/zsh/local-paths"
	execute "rm $HOME/.zshrc"
	execute "cd $HOME/.dotfiles/"
	execute "stow ."
	echo
else
	echo -e "${GREEN}Skipped .zshrc fixup.${NC}"
fi

if [[ "$resRclone" == "y" ]]; then
	echo
	echo -e "${BLUE}Creating btrfs subvolume for ProtonDrive...${NC}"
	CURRENT_USER=$(logname)
	CURRENT_GROUP=$(id -gn "$CURRENT_USER")
	execute "sudo btrfs sub create /@protondrive"
	execute "sudo chown -R \"$CURRENT_USER:$CURRENT_GROUP\" /@protondrive"

	echo
	echo -e "${BLUE}Enabling rclone ProtonDrive sync service...${NC}"
	execute "chmod +x $HOME/.dotfiles/.proton-drive-rclone-mount.sh"
	execute "systemctl --user daemon-reload"
	execute "systemctl --user enable proton-drive-mount.service"
	echo
else
	echo -e "${GREEN}Skipped rclone ProtonDrive sync enabling.${NC}"
fi

if [[ "$resZsa" == "y" ]]; then
	echo
	echo -e "${BLUE}Linking ZSA keyboard udev rules...${NC}"
	execute "sudo ln -s $HOME/.dotfiles/.udev/50-zsa.rules /etc/udev/rules.d/"

	echo
	echo -e "${BLUE}Syncing required group...${NC}"
	CURRENT_USER=$(logname)
	ZSA_GROUP=plugdev
	execute "sudo groupadd $ZSA_GROUP"
	execute "sudo usermod -aG $ZSA_GROUP $CURRENT_USER"
	echo
else
	echo -e "${GREEN}Skipped ZSA keyboard udev rules setup.${NC}"
fi

if [[ "$resKeymapp" == "y" ]]; then
	echo
	echo -e "${BLUE}Downloading and setting up Keymapp...${NC}"
	KEYMAPP_URL="https://oryx.nyc3.cdn.digitaloceanspaces.com/keymapp/keymapp-latest.tar.gz"
	KEYMAPP_DIR="/opt/keymapp-latest"

	# Remove old installation
	echo -e "${BLUE}Removing old Keymapp installation...${NC}"
	execute "sudo rm -rf ${KEYMAPP_DIR}"
	execute "sudo rm -f /usr/share/applications/keymapp.desktop"
	execute "sudo update-desktop-database"

	execute "sudo mkdir -p ${KEYMAPP_DIR}"
	execute "sudo curl -L ${KEYMAPP_URL} -o /tmp/keymapp.tar.gz"
	execute "sudo tar xfz /tmp/keymapp.tar.gz -C ${KEYMAPP_DIR}"

	# Create desktop entry
	DESKTOP_ENTRY="[Desktop Entry]
Name=Keymapp
Comment=ZSA Keyboard Configuration Tool
Exec=${KEYMAPP_DIR}/keymapp
Icon=${KEYMAPP_DIR}/icon.png
Terminal=false
Type=Application
Categories=Utility;"

	echo -e "${BLUE}Creating desktop entry...${NC}"
	execute "echo \"${DESKTOP_ENTRY}\" | sudo tee /usr/share/applications/keymapp.desktop"
	execute "sudo chmod +x ${KEYMAPP_DIR}/keymapp"
	execute "sudo update-desktop-database"
	echo
else
	echo -e "${GREEN}Skipped Keymapp Installation and Setup.${NC}"
fi

if [[ "$resFinishOutput" == "y" ]]; then
	echo
	echo -e "${RED}------=============================================================================------"
	echo "------======                            FINISHED                             ======------"
	echo "------=============================================================================------"
	if $dry_run; then
		echo
		echo
		echo -e "${RED}!!! THIS WAS JUST A DRY RUN, NOTHING ACTUALLY HAPPENED ON THE MACHINE !!!${NC}"
		echo
		echo
	fi
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
