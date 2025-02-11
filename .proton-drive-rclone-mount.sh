#!/bin/bash
# Disable job control
set +m

# Mount ProtonDrive
rclone mount \
	ProtonDrive:/ \
	/@protondrive/ \
	--daemon \
	--vfs-cache-mode full \
	--poll-interval 10m

# Check exit status and send notification
if [ $? -eq 0 ]; then
	notify-send "Proton Drive Mount" "Mounting was successful!"
else
	notify-send "Proton Drive Mount" "Mounting failed!" --urgency=critical
fi
