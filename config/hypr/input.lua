hl.config({
	input = {
		kb_layout = "us,ua",
		kb_variant = "",
		kb_model = "",
		-- kb_options = "grp:alt_shift_toggle",
		kb_options = "grp:win_space_toggle",
		kb_rules = "",
		follow_mouse = 1,
		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
		touchpad = {
			natural_scroll = false,
		},
	},
})

for _, name in ipairs({
	"steelseries-steelseries-aerox-9-wireless",
	"steelseries-steelseries-aerox-9-wireless-3",
}) do
	hl.device({ name = name, sensitivity = -0.3 })
end

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
