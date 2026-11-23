-- Runs a waybar custom-module script and shows its {text, tooltip, class} output.
-- waybar class names map onto palette roles, so scripts stay unchanged.
local COLORS = {
  ["accent-focus"] = "primary", ["accent-info"] = "secondary", ["accent-const"] = "tertiary", ["accent-ok"] = "#baffc9",
  connected = "primary", charging = "primary",
  dnd = "#f2c879", warning = "#f2c879", disconnected = "#f2c879",
  critical = "error", error = "error",
  off = "on_surface_variant", muted = "on_surface_variant", disabled = "on_surface_variant", stopped = "on_surface_variant",
}

local started = false

-- waybar text may carry Pango markup; the bar shows plain text.
local function plain(s)
  s = tostring(s or ""):gsub("<[^>]*>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&amp;", "&")
  return s
end

-- waybar tooltips are often boxed for a monospace popup: drop the frame and rule lines, keep the content.
local BOX = { "│", "─", "╭", "╮", "╰", "╯", "├", "┤" }
local function tooltip(t)
  local out, blank = {}, true
  for l in (plain(t) .. "\n"):gmatch("([^\n]*)\n") do
    -- anchored-left patterns only: "%s+$" backtracks quadratically and blows the CPU budget
    l = l:gsub("^%s*│", ""):match("^(.*%S)") or ""
    if l:sub(-3) == "│" then l = l:sub(1, -4):match("^(.*%S)") or "" end
    local bare = l
    for _, c in BOX do bare = bare:gsub(c, "") end
    if bare:find("%S") then
      table.insert(out, l); blank = false
    elseif not blank and bare == l then
      table.insert(out, ""); blank = true -- keep one empty line between sections, not rules
    end
  end
  if blank then table.remove(out) end
  -- common indent left by the frame
  local indent
  for _, l in out do
    local i = l:match("^( *)%S")
    if i and (not indent or #i < indent) then indent = #i end
  end
  for k, l in out do
    l = l:sub((indent or 0) + 1)
    out[k] = l:match("^%s%s%s%s%s%s%s%s+(.*)") or l -- centered titles
  end
  return table.concat(out, "\n")
end

local function show(line)
  line = line and line:match("^%s*(.*%S)") or ""
  if line == "" then return end
  local data = noctalia.json.decode(line)
  if type(data) ~= "table" then data = { text = line } end -- plain-text scripts
  local text = plain(data.text) -- keep spaces: neko walks by padding
  barWidget.setVisible(text:find("%S") ~= nil)
  barWidget.setText(text)
  barWidget.setTooltip(data.tooltip and tooltip(data.tooltip) or nil)
  barWidget.setColor(COLORS[data.class] or "on_surface")
end

function update()
  local cmd = noctalia.getConfig("command") or ""
  local interval = noctalia.getConfig("interval") or 5
  if cmd == "" then barWidget.setVisible(false) return end
  if interval == 0 then
    if not started then
      started = noctalia.runStream(cmd, show)
    end
    noctalia.setUpdateInterval(60000)
    return
  end
  noctalia.setUpdateInterval(interval * 1000)
  noctalia.runAsync(cmd, function(r)
    local last
    for l in (r.stdout or ""):gmatch("[^\n]+") do last = l end
    show(last)
  end)
end
