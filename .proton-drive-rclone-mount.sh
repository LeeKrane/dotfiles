#!/bin/bash
# Disable job control
set +m

# Mount ProtonDrive
output=$(rclone mount \
	ProtonDrive:/ \
	/@protondrive/ \
	--daemon \
	--vfs-cache-mode full \
	--poll-interval 10m 2>&1)

# Check exit status and send notification
if [ $? -eq 0 ]; then
	notify-send "Proton Drive Mount" "Mounting was successful!"
else
	if [[ "$output" == *"2fa: Incorrect login credentials."* ]]; then
		extra_message=" (2fa expired)"
	else
		extra_message=""
	fi

	notify-send "Proton Drive Mount" "Mounting failed!$extra_message" --urgency=critical
fi
