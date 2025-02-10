rclone mount \
	ProtonDrive:/ \
	/@protondrive/ \
	--daemon \
	--vfs-cache-mode full \
	--poll-interval 10m \
	--exclude "clips_$(hostname)"

rclone mount \
	ProtonDrive:/clips_$(hostname) \
	~/Videos/clips/ \
	--daemon \
	--vfs-cache-mode full \
	--poll-interval 10m

