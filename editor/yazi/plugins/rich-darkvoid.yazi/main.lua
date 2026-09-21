--@diagnostic disable: undefined-global
local M = {}
local ESC = string.char(27)
local RESET = ESC .. "[0m"
local SIGNS = {
	["+"] = { glyph = "▎", color = "#baffc9" }, -- added
	["~"] = { glyph = "┆", color = "#ffffba" }, -- modified
	["-"] = { glyph = "╴", color = "#ffb3ba" }, -- deleted
}

local function ansi_fg(hex)
	local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
	if not r then
		return ""
	end
	return string.format("%s[38;2;%d;%d;%dm", ESC, tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

for _, def in pairs(SIGNS) do
	def.marker = ansi_fg(def.color) .. def.glyph .. RESET
end

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function count_lines(content)
	if content == "" then
		return 0
	end
	local n = select(2, content:gsub("\n", "\n"))
	if content:sub(-1) ~= "\n" then
		n = n + 1
	end
	return n
end

local function parse_range(range)
	local start, count = range:match("^(%d+),(%d+)$")
	return start and tonumber(start) or tonumber(range), start and tonumber(count) or 1
end

local function run_command(command, args)
	local output = Command(command):arg(args):output()
	if not output then
		return nil, true
	end

	return output.stdout, not output.status.success
end

local function compute_signs(path)
	local source = io.open(path, "rb")
	if not source then
		return nil
	end
	local content = source:read("*a")
	source:close()
	if content:find("\0", 1, true) then
		return nil -- binary file, nothing to mark up
	end
	local lines = count_lines(content)
	local directory = path:match("^(.*)/[^/]+$") or "."
	local root, root_failed = run_command("git", { "-C", directory, "rev-parse", "--show-toplevel" })
	if root_failed or not root then
		return nil -- not inside a git repo
	end

	root = trim(root)

	local diff, diff_failed = run_command("git", {
		"-C",
		root,
		"diff",
		"--no-ext-diff",
		"--no-color",
		"--unified=0",
		"HEAD",
		"--",
		path,
	})
	if diff_failed then
		diff, diff_failed = run_command("git", {
			"-C",
			root,
			"diff",
			"--no-ext-diff",
			"--no-color",
			"--unified=0",
			"--",
			path,
		})
	end
	if diff_failed or not diff then
		return nil
	end

	local signs = {}
	for header in diff:gmatch("[^\n]+") do
		local old_range, new_range = header:match("@@ %-([^ ]+) %+([^ ]+) @@")
		if old_range and new_range then
			local _, old_count = parse_range(old_range)
			local new_start, new_count = parse_range(new_range)
			if new_count == 0 then
				signs[math.max(1, math.min(new_start, lines))] = "-"
			else
				local sign = old_count > 0 and "~" or "+"
				for line = new_start, math.min(lines, new_start + new_count - 1) do
					signs[line] = sign
				end
			end
		end
	end

	if diff == "" then
		local untracked, untracked_failed = run_command("git", {
			"-C",
			root,
			"ls-files",
			"--others",
			"--exclude-standard",
			"--",
			path,
		})
		if not untracked_failed and untracked and trim(untracked) ~= "" then
			for line = 1, lines do
				signs[line] = "+"
			end
		end
	end

	return signs
end

local last = {}
local function signs_for_file(file)
	local path = tostring(file.url.path)
	local cha = file.cha
	if last.path == path and last.mtime == cha.mtime and last.size == cha.len then
		return last.signs
	end
	local signs = compute_signs(path)
	last = { path = path, mtime = cha.mtime, size = cha.len, signs = signs }
	return signs
end

local function add_git_markers(text, signs)
	if not signs then
		return text
	end
	local rendered = {}
	for line in (text .. "\n"):gmatch("(.-)\n") do
		local plain = line:gsub(ESC .. "%[[%d;]*m", "")
		local line_number = tonumber(plain:match("^%s*(%d+)%s"))
		local sign = line_number and signs[line_number]
		if sign and line:sub(1, 1) == " " then
			rendered[#rendered + 1] = SIGNS[sign].marker .. line:sub(2)
		else
			rendered[#rendered + 1] = line
		end
	end
	return table.concat(rendered, "\n")
end

local function rich_pythonpath()
	local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
	local theme_path = config_home .. "/dotfiles/tools/rich"
	local current = os.getenv("PYTHONPATH")
	return current and theme_path .. ":" .. current or theme_path
end

local RICH_PYTHONPATH = rich_pythonpath()

function M:peek(job)
	local path = tostring(job.file.url.path)
	local signs = signs_for_file(job.file)
	local width = tostring(rt.preview.max_width)

	local child = Command("rich")
		:env("COLUMNS", width)
		:env("COLORTERM", "truecolor")
		:env("PYTHONPATH", RICH_PYTHONPATH)
		:arg({
			"--syntax",
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
		})
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return require("code"):peek(job)
	end

	local limit = job.area.h
	local i, lines, errors = 0, {}, 0
	repeat
		local line, event = child:read_line()
		if event == 0 then
			i = i + 1
			if i > job.skip then
				lines[#lines + 1] = line
			end
		elseif event == 1 then
			errors = errors + 1
		else
			break
		end

	until i >= job.skip + limit
	child:start_kill()

	if i == 0 and errors > 0 then
		return require("code"):peek(job)
	elseif job.skip > 0 and i < job.skip + limit then
		return ya.emit("peek", {
			math.max(0, i - limit),
			only_if = job.file.url,
			upper_bound = true,
		})
	end

	local rendered = add_git_markers(table.concat(lines), signs)
	rendered = rendered:gsub("\t", string.rep(" ", rt.preview.tab_size))
	ya.preview_widget(job, ui.Text.parse(rendered):area(job.area):wrap(ui.Wrap.NO))
end

function M:seek(job)
	require("code"):seek(job)
end

return M
