-- Mounts ~/.ssh/config hosts under /mnt/ssh (M s); goes through ssh, so VPN-tagged hosts bring their VPN up.
-- /mnt/ssh is owned by the user (FUSE mounts need that; system/aconfmgr/files/etc/tmpfiles.d/mnt-ssh.conf).
-- Host lists stay in yazi's own menu up to its 36-key limit; past that sshfs falls back to fzf (it can't call tv).
require("sshfs"):setup({ mount_dir = "/mnt/ssh", ui = { picker = "menu", menu_max = 36 } })

-- Vim counts (5j, 3yy, 2gt) with hybrid relative numbers; replaces the unmaintained relative-motions.yazi.
require("motions"):setup({ show_numbers = true, show_motion = true })

local top_level = os.getenv("YAZI_RESTORE_PROJECT") == "1"
	and os.getenv("NVIM") == nil
	and (tonumber(os.getenv("YAZI_LEVEL")) or 1) <= 1

require("projects"):setup({
	save = { method = "lua" },
	last = {
		update_after_save = true,
		update_after_load = top_level,
		update_before_quit = top_level,
		load_after_start = top_level,
	},
	notify = { enable = true },
})

require("git"):setup({
	order = 500,
})

-- Bookmarks live outside plugins/, which `ya pkg` replaces on upgrade.
require("whoosh"):setup({
	bookmarks_path = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/yazi/whoosh-bookmarks",
	jump_notify = false,
	-- fuzzy search is tv (`b /`, config/television/cable/yazi-bookmarks.toml), not whoosh's built-in fzf
	special_keys = { fuzzy_search = false },
})

-- Keep zoxide's database in sync with directories visited in yazi, so `cd`/`z` in the shell and tv's zoxide channel know them.
require("zoxide"):setup({ update_db = true })
