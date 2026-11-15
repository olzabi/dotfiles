# shellcheck shell=bash
# aconfmgr already skips /dev /home /media /mnt /proc /root /run /sys /tmp /var/cache.
# $HOME is owned by the rest of this repo; this config tracks only system state.

# generated state, rebuilt by the system
IgnorePath '/boot/*'                 # kernels, initramfs, grub.cfg (sources live in /etc)
IgnorePath '/lost+found'
IgnorePath '/swapfile'
IgnorePath '/etc/.updated'
IgnorePath '/var/.updated'
IgnorePath '/etc/machine-id'
IgnorePath '/etc/ld.so.cache'
IgnorePath '/etc/adjtime'
IgnorePath '/etc/pacman.d/gnupg/*'
IgnorePath '/etc/ca-certificates/extracted/*'
IgnorePath '/etc/ssl/certs/*'
IgnorePath '/etc/os-release'
IgnorePath '/usr/lib/locale/locale-archive'
IgnorePath '/usr/lib/modules/*'      # dkms-built modules (v4l2loopback, nvidia)
IgnorePath '/usr/share/info/dir'
IgnorePath '/usr/share/mime/*'
IgnorePath '/usr/share/glib-2.0/schemas/gschemas.compiled'
IgnorePath '/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache'
IgnorePath '/usr/lib/gio/modules/giomodule.cache'
IgnorePath '/usr/share/icons/*/icon-theme.cache'
IgnorePath '/usr/share/applications/mimeinfo.cache'
IgnorePath '/usr/lib/udev/hwdb.bin'
IgnorePath '/etc/udev/hwdb.bin'
IgnorePath '*/__pycache__/*'
IgnorePath '/var/log/*'
IgnorePath '/var/tmp/*'
IgnorePath '/var/spool/*'
IgnorePath '/var/db/*'
IgnorePath '/var/lib/*'              # service databases (pacman, systemd, dkms, NetworkManager, ...)

# secrets: never commit
IgnorePath '/etc/shadow*'
IgnorePath '/etc/gshadow*'
IgnorePath '/etc/passwd-'
IgnorePath '/etc/group-'
IgnorePath '/etc/ssh/ssh_host_*'
IgnorePath '/etc/NetworkManager/system-connections/*'
IgnorePath '/etc/openvpn/*'
IgnorePath '/etc/iwd/*'
IgnorePath '/etc/tailscale/*'

# large binaries: reinstall from source instead of storing them in git
IgnorePath '/nix/*'                  # nix store
IgnorePath '/opt/cuda/*'             # package-owned, but huge if anything drifts
IgnorePath '/usr/local/lib/ollama/*' # ollama install script; see /usr/local/bin/ollama
IgnorePath '/usr/local/bin/ollama'
IgnorePath '/usr/local/go/*'
