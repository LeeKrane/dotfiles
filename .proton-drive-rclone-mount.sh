#!/bin/bash
# Disable job control
set +m

RCLONE_REMOTE="ProtonDrive"
MOUNT_PATH="/@protondrive/"

# Function to get 2FA code via GUI
get_2fa_code() {
	yad --center --title="2FA Required" --text="Please enter your new 2FA code for Proton Drive:" --entry --hide-text --undecorated --width=400 --height=100
	echo $? # Return exit status of yad for cancel detection
}

# Function to update Rclone configuration with new 2FA
update_rclone_config() {
	local new_2fa_code="$1"
	local config_file

	# Get the path to the rclone config file
	config_file=$(rclone config file | grep "rclone.conf" | awk '{print $NF}')

	if [ -z "$config_file" ]; then
		notify-send "Rclone Error" "Could not find Rclone configuration file." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
		return 1 # Indicate failure
	fi

	echo "Updating Rclone configuration file: $config_file"
	echo "Searching for '2fa = ' below section '[${RCLONE_REMOTE}]' to update."

	# Use sed to update the '2fa' line within the specified remote's section
	sed -i "/^\[${RCLONE_REMOTE}\]/,/^\[.*\]/{s/^[[:space:]]*2fa[[:space:]]*=[[:space:]]*.*/2fa = ${new_2fa_code}/}" "$config_file"

	if [ $? -ne 0 ]; then
		notify-send "Rclone Error" "Failed to update Rclone configuration file. Check permissions or file format." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
		return 1 # Indicate failure
	fi

	# Verify the change
	if grep -q -E "^[[:space:]]*2fa[[:space:]]*=[[:space:]]*${new_2fa_code}" "$config_file"; then
		echo "2FA line successfully updated in $config_file."
		return 0 # Indicate success
	else
		notify-send "Rclone Warning" "2FA line might not have been updated correctly in config file." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=normal
		return 1 # Indicate failure (even if sed returned 0, verify the change)
	fi
}

# --- Main Mount Loop ---
while true; do
	echo "Attempting to mount $RCLONE_REMOTE..."
	output=$(rclone mount \
		"$RCLONE_REMOTE":/ \
		"$MOUNT_PATH" \
		--daemon \
		--vfs-cache-mode full \
		--poll-interval 10m 2>&1)

	exit_status=$?

	# Check exit status and send notification
	if [ $exit_status -eq 0 ]; then
		notify-send "$RCLONE_REMOTE Mount" "Mounting was successful!" -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png"
		break # Exit loop on success
	else
		local_message="Mounting failed!"
		local_detail=""
		local_action_taken=false

		# Check for 2FA specific error
		if [[ "$output" == *"2fa: Incorrect login credentials."* ]] ||
			[[ "$output" == *"Auth error: 2FA required."* ]]; then

			local_detail="2FA expired or incorrect."
			notify-send "$RCLONE_REMOTE Mount" "$local_message $local_detail -- Prompting for new 2FA." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical

			# Get 2FA code via GUI
			read -r new_2fa_code_entered yad_exit_code < <(get_2fa_code)

			if [ "$yad_exit_code" -ne 0 ]; then # YAD's exit code 1 is typically Cancel/No
				notify-send "$RCLONE_REMOTE Mount" "2FA code input cancelled. Aborting." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
				exit 1
			fi

			if [ -z "$new_2fa_code_entered" ]; then
				notify-send "$RCLONE_REMOTE Mount" "2FA code not provided. Aborting." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
				exit 1
			fi

			# Update 2FA in config file
			if update_rclone_config "$new_2fa_code_entered"; then
				local_action_taken=true
				notify-send "$RCLONE_REMOTE Mount" "2FA updated. Retrying mount." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png"
				# Loop will naturally re-attempt
			else
				notify-send "$RCLONE_REMOTE Mount" "Failed to update 2FA configuration. Please check manually." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png" --urgency=critical
				# Fall through to the retry/cancel dialog for manual intervention
			fi
		else
			# Other types of mount failures
			local_detail="An unexpected error occurred."
			echo "Failed output: $output" # Log the full output for debugging
		fi

		# If an action was taken (like 2FA update), then the loop will retry automatically.
		# If no specific action was taken or it failed, ask the user what to do.
		if ! $local_action_taken; then
			# Use yad for a notification with Retry/Cancel buttons
			yad_response=$(yad --center --title="$RCLONE_REMOTE Mount Failed" \
				--text="<b>$local_message</b>\n\n$local_detail\n\nWould you like to retry the mount?" \
				--button="Retry!gtk-refresh:0" \
				--button="Cancel!gtk-cancel:1" \
				--undecorated --width=450 --height=150)

			yad_exit_code=$? # Capture yad's exit code for button pressed

			if [ "$yad_exit_code" -eq 1 ]; then # YAD's exit code for the second button (Cancel)
				notify-send "$RCLONE_REMOTE Mount" "Mount attempt cancelled by user." -a "Proton Drive" -i "/home/krane/.dotfiles/proton-drive-logo.png"
				exit 1 # Exit the script
			fi
			# If yad_exit_code is 0 (Retry), the loop will continue
		fi
	fi
done

exit 0 # Script successfully completed
