#!/bin/bash
# Disable job control
set +m

RCLONE_REMOTE="ProtonDrive"
MOUNT_PATH="/@protondrive/"

# Function to get 2FA code via GUI
get_2fa_code() {
	yad --center --title="2FA Required" --text="Please enter your new 2FA code for Proton Drive:" --entry --hide-text --undecorated --width=400 --height=100
}

# Function to update Rclone configuration with new 2FA
update_rclone_config() {
	local new_2fa_code="$1"
	local config_file

	# Get the path to the rclone config file
	config_file=$(rclone config file | grep "rclone.conf" | awk '{print $NF}')

	if [ -z "$config_file" ]; then
		notify-send "Rclone Error" "Could not find Rclone configuration file." --urgency=critical
		exit 1
	fi

	echo "Updating Rclone configuration file: $config_file"
	echo "Searching for '2fa = ' below section '[${RCLONE_REMOTE}]' to update."

	# Use sed to update the '2fa' line within the specified remote's section
	sed -i "/^\[${RCLONE_REMOTE}\]/,/^\[.*\]/{s/^[[:space:]]*2fa[[:space:]]*=[[:space:]]*.*/2fa = ${new_2fa_code}/}" "$config_file"

	if [ $? -ne 0 ]; then
		notify-send "Rclone Error" "Failed to update Rclone configuration file. Check permissions or file format." --urgency=critical
		exit 1
	fi

	# Verify the change
	if grep -q -E "^[[:space:]]*2fa[[:space:]]*=[[:space:]]*${new_2fa_code}" "$config_file"; then
		echo "2FA line successfully updated in $config_file."
	else
		notify-send "Rclone Warning" "2FA line might not have been updated correctly in config file." --urgency=normal
	fi
}

# Initial mount attempt
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
	notify-send "$RCLONE_REMOTE Mount" "Mounting was successful!"
else
	# Check for 2FA expiration message
	if [[ "$output" == *"2fa: Incorrect login credentials."* ]] ||
		[[ "$output" == *"Auth error: 2FA required."* ]]; then
		extra_message=" (2fa expired or incorrect)"
		notify-send "$RCLONE_REMOTE Mount" "Mounting failed!$extra_message -- Prompting for new 2FA." --urgency=critical

		new_2fa=$(get_2fa_code)

		if [ -z "$new_2fa" ]; then
			notify-send "$RCLONE_REMOTE Mount" "2FA code not provided. Aborting." --urgency=critical
			exit 1
		fi

		# Update 2FA in config file
		update_rclone_config "$new_2fa"

		# Re-attempt mount after updating 2FA
		echo "Re-attempting to mount $RCLONE_REMOTE after 2FA update..."
		output=$(rclone mount \
			"$RCLONE_REMOTE":/ \
			"$MOUNT_PATH" \
			--daemon \
			--vfs-cache-mode full \
			--poll-interval 10m 2>&1)
		exit_status=$?

		if [ $exit_status -eq 0 ]; then
			notify-send "$RCLONE_REMOTE Mount" "Mounting successful after 2FA update!"
		else
			notify-send "$RCLONE_REMOTE Mount" "Mounting failed even after 2FA update! Check logs for details." --urgency=critical
			echo "Failed output after 2FA update:"
			echo "$output"
		fi

	else
		# Other types of mount failures
		extra_message=""
		notify-send "$RCLONE_REMOTE Mount" "Mounting failed!$extra_message" --urgency=critical
		echo "Failed output:"
		echo "$output"
	fi
fi
