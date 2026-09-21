---@diagnostic disable: undefined-global
local M = {}
local ansi = string.char(27)
local reset = ansi .. "[0m"
local glyphs = { ["+"] = "▎", ["~"] = "┆", ["-"] = "╴" }

local function trim(value)
	value = value:gsub("^%s+", "")
	return value:gsub("%s+$", "")
end

local function run_command(command, args)
	local child = Command(command):arg(args):stdout(Command.PIPED):stderr(Command.PIPED):spawn()
	if not child then
		return nil, true
	end
	local output, errors = {}, 0
	repeat
		local line, event = child:read_line()
		if event == 0 then
			output[#output + 1] = line
		elseif event == 1 then
			errors = errors + 1
		else
			break
		end
	until false
	child:start_kill()
	return table.concat(output), errors > 0
end

local function parse_range(range)
	local start, count = range:match("^(%d+),(%d+)$")
	return start and tonumber(start) or tonumber(range), start and tonumber(count) or 1
end

local function signs_for_file(path)
	local source = io.open(path, "rb")
	if not source then return nil end
	local content = source:read("*a")
	source:close()
	if content:find("\0", 1, true) then return nil end
	local lines = 0
	for _ in (content .. "\n"):gmatch(".-\n") do lines = lines + 1 end

	local directory = path:match("^(.*)/[^/]+$") or "."
	local root, failed = run_command("git", { "-C", directory, "rev-parse", "--show-toplevel" })
	if failed or not root then return nil end
	root = trim(root)
	local relative = path:sub(1, #root + 1) == root .. "/" and path:sub(#root + 2) or path
	local diff, diff_failed = run_command("git", {
		"-C", root, "diff", "--no-ext-diff", "--no-color", "--unified=0", "HEAD", "--", relative,
	})
	if diff_failed then
		diff, diff_failed = run_command("git", {
			"-C", root, "diff", "--no-ext-diff", "--no-color", "--unified=0", "--", relative,
		})
	end
	if diff_failed or not diff then return nil end
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
				for line = new_start, math.min(lines, new_start + new_count - 1) do signs[line] = sign end
			end
		end
	end
	if diff == "" then
		local untracked, untracked_failed = run_command("git", {
			"-C", root, "ls-files", "--others", "--exclude-standard", "--", relative,
		})
		if not untracked_failed and untracked and trim(untracked) ~= "" then
			for line = 1, lines do signs[line] = "+" end
		end
	end
	return signs
end

local function ansi_fg(hex)
	local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
	return r and string.format("%s[38;2;%d;%d;%dm", ansi, tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)) or ""
end

local function add_git_markers(text, signs)
	if not signs then return text end
	local colors = { ["+"] = "#baffc9", ["~"] = "#ffffba", ["-"] = "#ffb3ba" }
	local rendered = {}
	for line in (text .. "\n"):gmatch("(.-)\n") do
		local plain = line:gsub(ansi .. "%[[%d;]*m", "")
		local line_number = tonumber(plain:match("^%s*(%d+)%s"))
		local sign = line_number and signs[line_number]
		local rendered_line = line
		if sign and line:sub(1, 1) == " " then
			rendered_line = ansi_fg(colors[sign]) .. glyphs[sign] .. reset .. line:sub(2)
		end
		rendered[#rendered + 1] = rendered_line
	end
	return table.concat(rendered, "\n")
end

local function rich_theme_path()
	local config_home = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
	return config_home .. "/dotfiles/tools/rich"
end

local function rich_pythonpath()
	local path = rich_theme_path()
	local current = os.getenv("PYTHONPATH")
	return current and path .. ":" .. current or path
end

function M:peek(job)
	local path = tostring(job.file.url.path)
	local signs = signs_for_file(path)
	local width = tostring(rt.preview.max_width)
	local child = Command("rich")
		:env("COLUMNS", width)
		:env("COLORTERM", "truecolor")
		:env("PYTHONPATH", rich_pythonpath())
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
