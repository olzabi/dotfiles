@echo off
:: Define user name (WSL)
set /p uName=enter wsl user name:

mklink "%UserProfile%/.wezterm.lua" "\\wsl$\home\%uName%\.config\dotfiles\wezterm\wezterm.lua
