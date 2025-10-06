#!/bin/bash
# Disable job control
set +m

# Parse command line arguments
DRY_RUN=false
VERBOSE=false
EXTRA_VERBOSE=false

for arg in "$@"; do
    case $arg in
        -h|--help)
            echo "Proton Drive Rclone Mount Script"
            echo "Automatically mounts Proton Drive using rclone with 2FA handling"
            echo ""
            echo "Usage: $0 [-h|--help] [-d|--dry-run] [-v|--verbose] [-vv|--extra-verbose]"
            echo ""
            echo "Options:"
            echo "  -h, --help           Show this help message"
            echo "  -d, --dry-run        Show what would be executed without actually running commands"
            echo "  -v, --verbose        Enable detailed logging and output"
            echo "  -vv, --extra-verbose Enable extra verbose mode with all executed commands"
            echo ""
            echo "Features:"
            echo "  - Mounts Proton Drive to /@protondrive/"
            echo "  - Handles 2FA authentication with GUI prompts"
            echo "  - Automatic retry on mount failures"
            echo "  - Desktop notifications for status updates"
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            ;;
        -vv|--extra-verbose)
            VERBOSE=true
            EXTRA_VERBOSE=true
            ;;
        -v|--verbose)
            VERBOSE=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

RCLONE_REMOTE="ProtonDrive"
MOUNT_PATH="/@protondrive/"

# Color definitions
if [ -t 1 ]; then  # Only use colors if output is to a terminal
    COLOR_RESET='\033[0m'
    COLOR_VERBOSE='\033[0;36m'    # Cyan
    COLOR_COMMAND='\033[0;33m'    # Yellow
    COLOR_DRY_RUN='\033[0;35m'    # Magenta
else
    COLOR_RESET=''
    COLOR_VERBOSE=''
    COLOR_COMMAND=''
    COLOR_DRY_RUN=''
fi

# Show mode announcements with colors
if [ "$DRY_RUN" = true ]; then
    echo -e "${COLOR_DRY_RUN}DRY RUN MODE:${COLOR_RESET} Commands will be shown but not executed"
fi

if [ "$EXTRA_VERBOSE" = true ]; then
    echo -e "${COLOR_VERBOSE}EXTRA VERBOSE MODE:${COLOR_RESET} Detailed logging and command tracing enabled"
elif [ "$VERBOSE" = true ]; then
    echo -e "${COLOR_VERBOSE}VERBOSE MODE:${COLOR_RESET} Detailed logging enabled"
fi

# Verbose logging function
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${COLOR_VERBOSE}[VERBOSE]${COLOR_RESET} $1"
    fi
}

# Extra verbose logging function for commands
log_command() {
    if [ "$EXTRA_VERBOSE" = true ]; then
        echo -e "${COLOR_COMMAND}[COMMAND]${COLOR_RESET} $1"
    fi
}

# Function to get 2FA code via GUI
get_2fa_code() {
	log_verbose "Prompting user for 2FA code"
	
	if [ "$DRY_RUN" = true ]; then
		echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would show 2FA input dialog"
		echo "123456" # Mock 2FA code for dry run
		echo "0" # Mock successful exit code
		return
	fi
	
	log_verbose "Launching YAD dialog for 2FA input"
	log_command "yad --center --title=\"2FA Required\" --text=\"Please enter your new 2FA code for Proton Drive:\" --entry --hide-text --undecorated --width=400 --height=100"
	yad --center --title="2FA Required" --text="Please enter your new 2FA code for Proton Drive:" --entry --hide-text --undecorated --width=400 --height=100
	local yad_exit=$?
	log_verbose "YAD dialog closed with exit code: $yad_exit"
	echo $yad_exit # Return exit status of yad for cancel detection
}

# Function to update Rclone configuration with new 2FA
update_rclone_config() {
	local new_2fa_code="$1"
	local config_file

	log_verbose "Starting 2FA configuration update with code: ${new_2fa_code:0:3}***"

	if [ "$DRY_RUN" = true ]; then
		echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would get rclone config file path"
		echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would update 2FA code to: $new_2fa_code"
		echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would run: sed -i \"/^\[${RCLONE_REMOTE}\]/,/^\[.*\]/{s/^[[:space:]]*2fa[[:space:]]*=[[:space:]]*.*/2fa = ${new_2fa_code}/}\" <config_file>"
		return 0 # Mock success
	fi

	log_verbose "Getting rclone config file path"
	log_command "rclone config file | grep \"rclone.conf\" | awk '{print \$NF}'"
	# Get the path to the rclone config file
	config_file=$(rclone config file | grep "rclone.conf" | awk '{print $NF}')

	if [ -z "$config_file" ]; then
		log_verbose "ERROR: Could not find rclone config file"
		log_command "notify-send \"Rclone Error\" \"Could not find Rclone configuration file.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\" --urgency=critical"
		notify-send "Rclone Error" "Could not find Rclone configuration file." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
		return 1 # Indicate failure
	fi

	log_verbose "Found rclone config file: $config_file"
	echo "Updating Rclone configuration file: $config_file"
	echo "Searching for '2fa = ' below section '[${RCLONE_REMOTE}]' to update."

	log_verbose "Executing sed command to update 2FA line"
	log_command "sed -i \"/^\\[${RCLONE_REMOTE}\\]/,/^\\[.*\\]/{s/^[[:space:]]*2fa[[:space:]]*=[[:space:]]*.*/2fa = ${new_2fa_code}/}\" \"$config_file\""
	# Use sed to update the '2fa' line within the specified remote's section
	sed -i "/^\[${RCLONE_REMOTE}\]/,/^\[.*\]/{s/^[[:space:]]*2fa[[:space:]]*=[[:space:]]*.*/2fa = ${new_2fa_code}/}" "$config_file"
	local sed_exit=$?

	if [ $sed_exit -ne 0 ]; then
		log_verbose "ERROR: sed command failed with exit code: $sed_exit"
		log_command "notify-send \"Rclone Error\" \"Failed to update Rclone configuration file. Check permissions or file format.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\" --urgency=critical"
		notify-send "Rclone Error" "Failed to update Rclone configuration file. Check permissions or file format." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
		return 1 # Indicate failure
	fi

	log_verbose "Verifying 2FA update in config file"
	log_command "grep -q -E \"^[[:space:]]*2fa[[:space:]]*=[[:space:]]*${new_2fa_code}\" \"$config_file\""
	# Verify the change
	if grep -q -E "^[[:space:]]*2fa[[:space:]]*=[[:space:]]*${new_2fa_code}" "$config_file"; then
		log_verbose "2FA update verification successful"
		echo "2FA line successfully updated in $config_file."
		return 0 # Indicate success
	else
		log_verbose "WARNING: 2FA update verification failed"
		log_command "notify-send \"Rclone Warning\" \"2FA line might not have been updated correctly in config file.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\" --urgency=normal"
		notify-send "Rclone Warning" "2FA line might not have been updated correctly in config file." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=normal
		return 1 # Indicate failure (even if sed returned 0, verify the change)
	fi
}

# --- Main Mount Loop ---
log_verbose "Starting main mount loop"
log_verbose "Remote: $RCLONE_REMOTE, Mount path: $MOUNT_PATH"

while true; do
	echo "Attempting to mount $RCLONE_REMOTE..."
	log_verbose "Mount attempt started"
	
	if [ "$DRY_RUN" = true ]; then
		echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would execute: rclone mount \"$RCLONE_REMOTE\":/ \"$MOUNT_PATH\" --daemon --vfs-cache-mode full --poll-interval 10m"
		echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would send notification: Mounting was successful!"
		break # Exit loop in dry run mode
	fi
	
	log_verbose "Executing rclone mount command"
	log_command "rclone mount \"$RCLONE_REMOTE\":/ \"$MOUNT_PATH\" --daemon --vfs-cache-mode full --poll-interval 10m"
	output=$(rclone mount \
		"$RCLONE_REMOTE":/ \
		"$MOUNT_PATH" \
		--daemon \
		--vfs-cache-mode full \
		--poll-interval 10m 2>&1)

	exit_status=$?
	log_verbose "Rclone mount command completed with exit status: $exit_status"

	# Check exit status and send notification
	if [ $exit_status -eq 0 ]; then
		log_verbose "Mount successful, sending success notification"
		log_command "notify-send \"$RCLONE_REMOTE Mount\" \"Mounting was successful!\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\""
		notify-send "$RCLONE_REMOTE Mount" "Mounting was successful!" -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png"
		break # Exit loop on success
	else
		log_verbose "Mount failed with exit status: $exit_status"
		log_verbose "Rclone output: $output"
		
		local_message="Mounting failed!"
		local_detail=""
		local_action_taken=false

		# Check for 2FA specific error
		if [[ "$output" == *"2fa: Incorrect login credentials."* ]] ||
			[[ "$output" == *"Auth error: 2FA required."* ]]; then

			log_verbose "Detected 2FA authentication error"
			local_detail="2FA expired or incorrect."
			
			if [ "$DRY_RUN" = true ]; then
				echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would send notification: $local_message $local_detail -- Prompting for new 2FA."
				echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would prompt for 2FA code and update configuration"
				local_action_taken=true
			else
				log_verbose "Sending 2FA error notification"
				log_command "notify-send \"$RCLONE_REMOTE Mount\" \"$local_message $local_detail -- Prompting for new 2FA.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\" --urgency=critical"
				notify-send "$RCLONE_REMOTE Mount" "$local_message $local_detail -- Prompting for new 2FA." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical

				# Get 2FA code via GUI
				read -r new_2fa_code_entered yad_exit_code < <(get_2fa_code)

				if [ "$yad_exit_code" -ne 0 ]; then # YAD's exit code 1 is typically Cancel/No
					log_verbose "User cancelled 2FA input"
					log_command "notify-send \"$RCLONE_REMOTE Mount\" \"2FA code input cancelled. Aborting.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\" --urgency=critical"
					notify-send "$RCLONE_REMOTE Mount" "2FA code input cancelled. Aborting." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
					exit 1
				fi

				if [ -z "$new_2fa_code_entered" ]; then
					log_verbose "No 2FA code provided by user"
					log_command "notify-send \"$RCLONE_REMOTE Mount\" \"2FA code not provided. Aborting.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\" --urgency=critical"
					notify-send "$RCLONE_REMOTE Mount" "2FA code not provided. Aborting." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
					exit 1
				fi

				log_verbose "Received 2FA code from user, updating configuration"
				# Update 2FA in config file
				if update_rclone_config "$new_2fa_code_entered"; then
					local_action_taken=true
					log_verbose "2FA configuration updated successfully"
					log_command "notify-send \"$RCLONE_REMOTE Mount\" \"2FA updated. Retrying mount.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\""
					notify-send "$RCLONE_REMOTE Mount" "2FA updated. Retrying mount." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png"
					# Loop will naturally re-attempt
				else
					log_verbose "Failed to update 2FA configuration"
					log_command "notify-send \"$RCLONE_REMOTE Mount\" \"Failed to update 2FA configuration. Please check manually.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\" --urgency=critical"
					notify-send "$RCLONE_REMOTE Mount" "Failed to update 2FA configuration. Please check manually." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
					# Fall through to the retry/cancel dialog for manual intervention
				fi
			fi
		else
			# Other types of mount failures
			log_verbose "Non-2FA mount error detected"
			local_detail="An unexpected error occurred."
			echo "Failed output: $output" # Log the full output for debugging
		fi

		# If an action was taken (like 2FA update), then the loop will retry automatically.
		# If no specific action was taken or it failed, ask the user what to do.
		if ! $local_action_taken; then
			log_verbose "No automatic action taken, prompting user for next step"
			
			if [ "$DRY_RUN" = true ]; then
				echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would show retry/cancel dialog for mount failure"
				echo -e "${COLOR_DRY_RUN}[DRY RUN]${COLOR_RESET} Would assume user selects 'Cancel' and exit"
				exit 1
			else
				log_verbose "Showing retry/cancel dialog to user"
				log_command "yad --center --title=\"$RCLONE_REMOTE Mount Failed\" --text=\"<b>$local_message</b>\\n\\n$local_detail\\n\\nWould you like to retry the mount?\" --button=\"Retry!gtk-refresh:0\" --button=\"Cancel!gtk-cancel:1\" --undecorated --width=450 --height=150"
				# Use yad for a notification with Retry/Cancel buttons
				yad_response=$(yad --center --title="$RCLONE_REMOTE Mount Failed" \
					--text="<b>$local_message</b>\n\n$local_detail\n\nWould you like to retry the mount?" \
					--button="Retry!gtk-refresh:0" \
					--button="Cancel!gtk-cancel:1" \
					--undecorated --width=450 --height=150)

				yad_exit_code=$? # Capture yad's exit code for button pressed
				log_verbose "User dialog response: exit code $yad_exit_code"

				if [ "$yad_exit_code" -eq 1 ]; then # YAD's exit code for the second button (Cancel)
					log_verbose "User selected Cancel, exiting script"
					log_command "notify-send \"$RCLONE_REMOTE Mount\" \"Mount attempt cancelled by user.\" -a \"Proton Drive\" -i \"/home/krane/.dotfiles/proton-drive-logo.png\""
					notify-send "$RCLONE_REMOTE Mount" "Mount attempt cancelled by user." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png"
					exit 1 # Exit the script
				fi
				log_verbose "User selected Retry, continuing mount loop"
				# If yad_exit_code is 0 (Retry), the loop will continue
			fi
		fi
	fi
done

log_verbose "Script completed successfully"
exit 0 # Script successfully completed
