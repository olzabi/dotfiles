
require("projects"):setup({
	save = { method = "yazi" },
	last = {
		update_after_save = true,
		update_after_load = true,
		update_before_quit = true,
		load_after_start = true,
	},
	notify = {
		enable = true,
	},
})

th.git = th.git or {}
th.git.modified_sign = "M"
th.git.deleted_sign = "D"
th.git.untracked_sign = "U"
th.git.ignored_sign = "I"

require("git"):setup({
	order = 500,
})

require("bookmarks"):setup({
	last_directory = { enable = false, persist = true, mode="dir" },
	persist = "vim",
	desc_format = "full",
	file_pick_mode = "hover",
	show_keys = true,
	notify = {
		enable = true,
		timeout = 1,
		message = {
			new = "New bookmark '<key>' -> '<folder>'",
			delete = "Deleted bookmark in '<key>'",
			delete_all = "Deleted all bookmarks",
		},
	},
})
