# shellcheck shell=bash
# Machine tuning kept in the repo (files/ mirrors /). Install once by hand with
# `sudo install -Dm644 system/aconfmgr/files/<path> /<path>`; aconfmgr save/apply then tracks them.

# zram swap: compressed RAM is cheap to swap to, so swap early and read single pages (Arch wiki values)
CopyFile /etc/systemd/zram-generator.conf
CopyFile /etc/sysctl.d/99-zram.conf

# NVIDIA keeps freed buffers in a pool per process; for niri that pool grew past 1 GiB of VRAM.
# Profile from the niri wiki (Nvidia page); takes effect when niri restarts.
CopyFile /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json

# CJK glyphs (Chinese/Japanese/Korean) render as empty boxes without a font that covers them
AddPackage noto-fonts-cjk

# MediaTek MT7921 Bluetooth hangs and falls off USB (error -71/-110) after autosuspend; keep it awake
CopyFile /etc/modprobe.d/btusb.conf

# watchman and editors ran out of inotify watches at the 524288 default
CopyFile /etc/sysctl.d/99-inotify.conf

# systemd-oomd kills a runaway cgroup before the kernel OOM stalls the desktop; Arch ships it with no policy
CopyFile /etc/systemd/system/user@.service.d/10-oomd.conf
CopyFile /etc/systemd/system/-.slice.d/10-oomd.conf
CreateLink /etc/systemd/system/multi-user.target.wants/systemd-oomd.service /usr/lib/systemd/system/systemd-oomd.service
CreateLink /etc/systemd/system/sockets.target.wants/systemd-oomd.socket /usr/lib/systemd/system/systemd-oomd.socket

# gamemode: `gamemoderun %command%` in Steam launch options switches the CPU to performance while a game runs
AddPackage gamemode
AddPackage lib32-gamemode
# ddcutil: noctalia sets the monitors' real backlight over DDC/CI; the i2c-dev nodes it talks to load at boot
AddPackage ddcutil
CopyFile /etc/modules-load.d/i2c-dev.conf
# Tablet display (noctalia tablet-display plugin): Sunshine runs the plugin's hook with PATH=/usr/bin, where mise's jq isn't
AddPackage sunshine
AddPackage jq
# Sunshine's virtual pen registers a tap at light pressure (libinput quirk)
CopyFile /etc/libinput/local-overrides.quirks

# sshfs mounts (yazi sshfs.yazi, M s) go under /mnt/ssh; FUSE needs the mountpoint owned by the user, and aconfmgr skips /mnt
CopyFile /etc/tmpfiles.d/mnt-ssh.conf
