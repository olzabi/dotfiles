-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- HYPRLAND CONFIG (split into modules)                  --
-- Docs: https://wiki.hypr.land/Configuring/Start/       --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Each file lives next to this one in ~/.config/hypr/
-- Order matters a little: shared modules (colors, programs) are
-- loaded on demand by the files that need them.

require("monitors")
require("env")
require("permissions")
require("autostart")
require("appearance")
require("animations")
require("layouts")
require("misc")
require("input")
require("keybinds")
require("rules")
