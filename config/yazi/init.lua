require("motions"):setup({
	show_numbers = "relative",
	show_motion = true,
})

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

require("bookmarks"):setup({
	last_directory = { enable = false, persist = true, mode = "dir" },
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

require("starship"):setup({
	hide_flags = true,
	flags_after_prompt = true,
	show_right_prompt = false,
	hide_count = false,
	count_separator = " ",
})
