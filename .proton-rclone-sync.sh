rclone mount \
	ProtonDrive:/ \
	/@protondrive/ \
	--daemon \
	--vfs-cache-mode full \
	--poll-interval 10m
