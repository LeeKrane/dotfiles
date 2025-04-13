#!/bin/bash

PKG_IS_DNF=false
PKG_IS_PACMAN=false

if command -v dnf &> /dev/null; then
	PKG_IS_DNF=true
elif command -v pacman &> /dev/null; then
	PKG_IS_PACMAN=true
fi

# Load function libraries
source ./.init/functions/colors.sh
source ./.init/functions/utils.sh
source ./.init/functions/menus.sh

# Load install steps
source ./.init/steps/btrfs.sh
source ./.init/steps/dotfiles.sh
source ./.init/steps/programs.sh
source ./.init/steps/repos.sh
source ./.init/steps/grub.sh
source ./.init/steps/plymouth.sh
source ./.init/steps/all_packages_pacman.sh
source ./.init/steps/rebos.sh
source ./.init/steps/zsh.sh
source ./.init/steps/kde_connect_fixups.sh
source ./.init/steps/rclone.sh
source ./.init/steps/zsa.sh
source ./.init/steps/keymapp.sh
source ./.init/steps/finish.sh

# Parse arguments
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
		echo -e "${RED}Unknown option: $1${NC}"
		show_help
		exit 1
		;;
	esac
done

# Trap
trap cleanup INT
OLD_SETTINGS=$(stty -g)

# Introduction
echo -e "${BLUE}Always clone the dotfiles repository as ~/.dotfiles"
echo -e "Run this script without sudo.${NC}"
echo
echo -e "${BLUE}Press ${GREEN}Enter${BLUE} to confirm or ${GREEN}q${BLUE} to quit:${NC}"
echo

# Run menu
choose_installation_mode
mode=$?

case "$mode" in
0) default_checkbox_value="x"; full_install="n" ;;
1) default_checkbox_value=" "; full_install="n" ;;
2) default_checkbox_value="x"; full_install="y" ;;
*) cleanup; exit 1 ;;
esac

# Begin selections
tput civis
stty raw -echo

echo -e "${BLUE}Press ${GREEN}Space${BLUE} to toggle, ${GREEN}Enter${BLUE} to confirm and ${GREEN}q${BLUE} to quit:${NC}"
echo

# Declare associative array and order

if $PKG_IS_DNF; then
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

	ordered_keys=(
		resBtrfsRoot resBtrfsHome resInitPrograms resLinkDotfiles resRepositories
		resGrubTheme resPlymouthTheme resRebosSetup resRebosInstall
		resZshInstall resZshPlugins resRclone resZsa resKeymapp resFinishOutput
	)
elif $PKG_IS_PACMAN; then
	declare -A prompts=(
		[resBtrfsRoot]="Create BTRFS snap @?"
		[resBtrfsHome]="Create BTRFS snap @home?"
		[resInitPrograms]="Install initial programs?"
		[resLinkDotfiles]="Link dotfiles?"
		[resAllInstall]="Install all packages?"
		[resZshInstall]="Install ZSH?"
		[resZshPlugins]="Install ZSH plugins?"
		[resKdeConnectFixups]="Open ports for KDE Connect?"
		[resRclone]="Setup rclone for ProtonDrive?"
		[resZsa]="Setup ZSA keyboard udev rules?"
		[resKeymapp]="Download latest Keymapp version?"
		[resFinishOutput]="Show final finish message?"
	)

	ordered_keys=(
		resBtrfsRoot resBtrfsHome resInitPrograms resLinkDotfiles resAllInstall
		resZshInstall resZshPlugins resKdeConnectFixups resRclone resZsa resKeymapp resFinishOutput
	)
fi

for var in "${ordered_keys[@]}"; do
	if [[ "$full_install" == "y" ]]; then
		eval "$var=y"
	else
		if choose_single_checkbox "${prompts[$var]}" "$default_checkbox_value"; then
			eval "$var=y"
		else
			eval "$var=n"
		fi
		echo
	fi
done

stty "$OLD_SETTINGS"
tput cnorm
echo
echo

# Step Execution
[[ "$resBtrfsRoot" == "y" || "$resBtrfsHome" == "y" ]] && run_btrfs
[[ "$resInitPrograms" == "y" ]] && install_initial_programs
[[ "$resLinkDotfiles" == "y" ]] && link_dotfiles
[[ "$resRepositories" == "y" ]] && enable_repositories
[[ "$resGrubTheme" == "y" ]] && configure_grub
[[ "$resPlymouthTheme" == "y" ]] && configure_plymouth
[[ "$resRebosSetup" == "y" || "$resRebosInstall" == "y" ]] && run_rebos
[[ "$resAllInstall" == "y" ]] && install_all_packages
[[ "$resZshInstall" == "y" || "$resZshPlugins" == "y" ]] && configure_zsh
[[ "$resKdeConnectFixups" == "y" ]] && kde_connect_fixups
[[ "$resRclone" == "y" ]] && configure_rclone
[[ "$resZsa" == "y" ]] && configure_zsa
[[ "$resKeymapp" == "y" ]] && install_keymapp
[[ "$resFinishOutput" == "y" ]] && final_message

echo -e "Exiting...${NC}"

