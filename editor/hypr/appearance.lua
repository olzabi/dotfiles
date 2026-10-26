-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
local c = require("colors")

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 20,
		border_size = 2,
		col = {
			active_border = c.focus,
			inactive_border = c.line,
			nogroup_border = c.line,
			nogroup_border_active = c.warning,
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "scrolling",
	},

	scrolling = {
		direction = "right",
		column_width = 0.5,
		follow_focus = true,
	},

	group = {
		col = {
			border_active = c.focus,
			border_inactive = c.line,
			border_locked_active = c.warning,
			border_locked_inactive = c.border,
		},
		groupbar = {
			col = {
				active = c.focus,
				inactive = c.visual,
				locked_active = c.warning,
				locked_inactive = c.border,
			},
			text_color = c.bg,
			text_color_inactive = c.comment,
		},
	},

	decoration = {
		rounding = 10,
		rounding_power = 2,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(0000009a)",
			color_inactive = "rgba(00000060)",
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},
})
