
th.git = th.git or {}
th.git.modified_sign = "M"
th.git.deleted_sign = "D"
th.git.untracked_sign = "U"
th.git.ignored_sign = "I"

require("git"):setup({
	order = 500,
})

require("relative-motions"):setup({
	show_numbers = "relative_absolute",
	show_motion = false,
})
