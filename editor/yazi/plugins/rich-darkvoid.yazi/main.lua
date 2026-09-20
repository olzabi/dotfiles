-- Rich previewer with the repository's Darkvoid palette.
-- Based on rich-preview.yazi, but intentionally borderless and unwrapped.
-- Yazi injects `Command` and `rt` at runtime.
---@diagnostic disable: undefined-global

local M = {}

local function rich_theme_path()
	local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
	return config_home .. "/dotfiles/tools/rich"
end

local function rich_pythonpath()
	local path = rich_theme_path()
	local current = os.getenv("PYTHONPATH")
	return current and path .. ":" .. current or path
end

local function is_markdown(path)
	return path:match("%.md$") or path:match("%.markdown$") or path:match("%.mdx$")
end

function M:peek(job)
	local path = tostring(job.file.url.path)
	-- Keep Rich's virtual canvas as wide as Yazi permits, then let Yazi clip it.
	-- This prevents Rich from pre-wrapping a line to the terminal's default 80 columns.
	local width = tostring(rt.preview.max_width)
	local args = {
		"-j",
		"--left",
		"--line-numbers",
		"--force-terminal",
		"--panel=none",
		"--padding",
		"0",
		"--guides",
		"--theme=darkvoid",
		"--no-wrap",
		"--max-width",
		width,
		path,
	}

	-- Rich renders Markdown itself; all other text is syntax-highlighted with line numbers.
	if not is_markdown(path) then
		table.insert(args, #args, "--syntax")
	end

	local child = Command("rich")
		:env("COLUMNS", width)
		:env("PYTHONPATH", rich_pythonpath())
		:arg(args)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return require("code"):peek(job)
	end

	local limit = job.area.h
	local i, lines, errs = 0, "", 0
	repeat
		local next, event = child:read_line()
		if event == 1 then
			errs = errs + 1
		elseif event ~= 0 then
			break
		else
			i = i + 1
			if i > job.skip then
				lines = lines .. next
			end
		end
	until i >= job.skip + limit

	child:start_kill()
	if i == 0 and errs > 0 then
		return require("code"):peek(job)
	elseif job.skip > 0 and i < job.skip + limit then
		ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
	else
		lines = lines:gsub("\t", string.rep(" ", rt.preview.tab_size))
		ya.preview_widget(
			job,
			ui.Text.parse(lines):area(job.area):wrap(ui.Wrap.NO)
		)
	end
end

function M:seek(job)
	require("code"):seek(job)
end

return M
