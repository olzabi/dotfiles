# shellcheck shell=bash
# Machine tuning kept in the repo (files/ mirrors /). Install once by hand with
# `sudo install -Dm644 system/aconfmgr/files/<path> /<path>`; aconfmgr save/apply then tracks them.

# zram swap: compressed RAM is cheap to swap to, so swap early and read single pages (Arch wiki values)
CopyFile /etc/systemd/zram-generator.conf
CopyFile /etc/sysctl.d/99-zram.conf

# NVIDIA keeps freed buffers in a pool per process; for niri that pool grew past 1 GiB of VRAM.
# Profile from the niri wiki (Nvidia page); takes effect when niri restarts.
CopyFile /etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json
