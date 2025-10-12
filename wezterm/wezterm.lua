---@class Config: Wezterm
local wezterm = require("wezterm")

local act = wezterm.action
local config = wezterm.config_builder()

local launch_menu = {
	{ args = { "top" } },
	{ label = "Bash", args = { "bash", "-l" } },
}
local opacity_lvl = 0.949

local Grey = "#0f1419"
local LightGrey = "#191f26"
local Dark = "#222"
local Light = "#EEE"
local PrimaryColor = "LightBlue"
local TAB_BAR_BG = Dark
local ACTIVE_TAB_BG = PrimaryColor
local ACTIVE_TAB_FG = Dark
local HOVER_TAB_BG = Grey
local HOVER_TAB_FG = Light
local NORMAL_TAB_BG = LightGrey
local NORMAL_TAB_FG = Light
local SOLID_RIGHT_ARROW = utf8.char(0xe0b0)

config = {
	color_scheme = "Kasugano (terminal.sexy)",

	-- WSL
	default_domain = "WSL:Ubuntu",
	default_cwd = "$HOME",
	default_prog = { "wsl.exe", "--cd", "~" },
	launch_menu = launch_menu,

	-- General Configuration
	automatically_reload_config = true,
	check_for_updates = true,
	check_for_updates_interval_seconds = 86400,
	audible_bell = "Disabled",

	--
	adjust_window_size_when_changing_font_size = false,
	hide_mouse_cursor_when_typing = false,
	window_decorations = "RESIZE",
	-- term = "xterm-256color",
	term = "xterm-256color",
	cell_width = 0.9,
	use_ime = true,

	-- Font Configuration
	font = wezterm.font({
		family = "FiraMono Nerd Font",
		weight = "Regular",
		harfbuzz_features = {
			"calt=0",
			"clig=0",
			"liga=0",
			"zero",
		},
	}),
	font_size = 12.0,

	-- Graphical Settings
	-- animation_fps = 120,
	max_fps = 120,
	front_end = "OpenGL",
	webgpu_power_preference = "HighPerformance",
	enable_wayland = true, -- X11
	enable_kitty_graphics = true,
	prefer_egl = true,

	-- Cursor
	default_cursor_style = "SteadyUnderline",
	cursor_blink_ease_in = "Constant",
	cursor_blink_ease_out = "Constant",
	cursor_blink_rate = 800,
	force_reverse_video_cursor = true,
	underline_thickness = 3,
	cursor_thickness = 4,
	underline_position = -6,

	-- Window-
	initial_cols = 120,
	initial_rows = 25,

	-- Tab Bar
	hide_tab_bar_if_only_one_tab = false,
	show_tab_index_in_tab_bar = false,
	tab_bar_at_bottom = true,
	tab_max_width = 30,
	use_fancy_tab_bar = false,

	window_padding = {
		left = "9px",
		right = "9px",
		top = "3px",
		bottom = "3px",
	},
	window_frame = {
		font = wezterm.font({ family = "FiraMono Nerd Font", weight = "Regular" }),
		active_titlebar_bg = "#0c0b0f",
		border_left_width = "5px",
		border_right_width = "5px",
		border_bottom_height = "5px",
		border_top_height = "5px",
		border_left_color = "#333",
		border_right_color = "#333",
		border_bottom_color = "#333",
		border_top_color = "#333",
	},
	inactive_pane_hsb = {
		saturation = 0.6,
		brightness = 0.4,
	},
	colors = { tab_bar = { background = TAB_BAR_BG } },
	tab_bar_style = {
		new_tab = wezterm.format({
			{ Background = { Color = TAB_BAR_BG } },
			{ Foreground = { Color = TAB_BAR_BG } },
			{ Text = SOLID_RIGHT_ARROW },
			{ Background = { Color = ACTIVE_TAB_BG } },
			{ Foreground = { Color = NORMAL_TAB_BG } },
			{ Text = " + " },
			{ Background = { Color = TAB_BAR_BG } },
			{ Foreground = { Color = ACTIVE_TAB_BG } },
			{ Text = SOLID_RIGHT_ARROW },
		}),
		new_tab_hover = wezterm.format({
			{ Attribute = { Italic = false } },
			{ Attribute = { Intensity = "Bold" } },
			{ Background = { Color = NORMAL_TAB_BG } },
			{ Foreground = { Color = TAB_BAR_BG } },
			{ Text = SOLID_RIGHT_ARROW },
			{ Background = { Color = NORMAL_TAB_BG } },
			{ Foreground = { Color = NORMAL_TAB_FG } },
			{ Text = " + " },
			{ Background = { Color = TAB_BAR_BG } },
			{ Foreground = { Color = NORMAL_TAB_BG } },
			{ Text = SOLID_RIGHT_ARROW },
		}),
	},
}

local function format_title(tab, title)
	return string.format(" %d: %s", (tab.tab_index + 1), title)
end

wezterm.on("format-tab-title", function(tab, tabs, pane, config, hover, max_width)
	local background = NORMAL_TAB_BG
	local foreground = NORMAL_TAB_FG
	local leading_fg = NORMAL_TAB_FG
	local leading_bg = background
	local trailing_fg = background
	local trailing_bg = NORMAL_TAB_BG

	if tab.is_active then
		background = ACTIVE_TAB_BG
		foreground = ACTIVE_TAB_FG
	elseif hover then
		background = HOVER_TAB_BG
		foreground = HOVER_TAB_FG
	end

	local is_first = tab.tab_id == tabs[1].tab_id
	local is_last = tab.tab_id == tabs[#tabs].tab_id
	if is_first or is_last then
		leading_fg = TAB_BAR_BG
		trailing_bg = TAB_BAR_BG
	else
		leading_fg = NORMAL_TAB_BG
		trailing_bg = NORMAL_TAB_BG
	end

	local title
	title = tab.active_pane.title

	local max = config.tab_max_width - 9
	if #title > max then
		title = wezterm.truncate_right(title, max) .. "…"
	end

	return {
		{ Attribute = { Italic = false } },
		{ Attribute = { Intensity = hover and "Bold" or "Normal" } },
		{ Background = { Color = leading_bg } },
		{ Foreground = { Color = leading_fg } },
		{ Text = SOLID_RIGHT_ARROW },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = format_title(tab, title) },
		{ Background = { Color = trailing_bg } },
		{ Foreground = { Color = trailing_fg } },
		{ Text = SOLID_RIGHT_ARROW },
	}
end)

--
wezterm.on("update-right-status", function(win, pane)
	-- local date = wezterm.strftime("%a %b %-d %H:%M ")
	local workspace = win:active_workspace()

	win:set_left_status(wezterm.format({
		{ Text = " " },
	}))

	win:set_right_status(wezterm.format({
		-- { Foreground = { Color = "#c0c0c0" } },
		-- { Background = { Color = "#282833" } },
		-- { Text = date },
		{ Foreground = { Color = "#c0c0c0" } },
		{ Background = { Color = "#282833" } },
		{ Text = " " .. "[" .. workspace .. "]" },
	}))
end)

local function switch_opacity(window)
	local overrides = window:get_config_overrides() or {}
	if overrides.window_background_opacity == 1 then
		overrides.window_background_opacity = opacity_lvl
	else
		overrides.window_background_opacity = 1
	end
	window:set_config_overrides(overrides)
end

config.mouse_bindings = {
	-- Ctrl-click will open the link under the mouse cursor
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

config.keys = {
	{ key = "A", mods = "CTRL|SHIFT", action = act({ PaneSelect = { mode = "SwapWithActive" } }) },
	{ key = "O", mods = "ALT", action = wezterm.action_callback(switch_opacity) },
	{ key = "_", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "R", mods = "CTRL|SHIFT", action = act({ RotatePanes = "CounterClockwise" }) },
	{ key = "r", mods = "CTRL|SHIFT", action = act({ RotatePanes = "Clockwise" }) },
	{
		key = ",",
		mods = "CTRL|ALT",
		action = act.PromptInputLine({
			description = "Tab name:",
			action = wezterm.action_callback(function(win, pane, line)
				if line then
					win:active_tab():set_title(line)
				end
			end),
		}),
	},
	{
		key = "u",
		mods = "ALT|SHIFT",
		action = act.QuickSelectArgs({
			label = "open url",
			patterns = { "https?://[a-zA-Z0-9.]+[-a-zA-Z0-9()@:%_\\+.~#?&//=]*" },
			action = wezterm.action_callback(function(win, pane)
				wezterm.open_with(win:get_selection_text_for_pane(pane))
			end),
		}),
	},
}

return config
