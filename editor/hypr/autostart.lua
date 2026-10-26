-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
local p = require("programs")

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
hl.on("hyprland.start", function()
	hl.exec_cmd(p.terminal)
	hl.exec_cmd("mako")
	hl.exec_cmd("waybar")
	hl.exec_cmd("chromium")
	hl.exec_cmd("hyprpaper")
end)
