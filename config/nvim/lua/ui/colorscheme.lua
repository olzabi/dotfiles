-- `over` mixed with `under` (both 0xRRGGBB), t = share of `over`
local function mix(over, under, t)
  local rgb = 0
  for _, s in ipairs { 16, 8, 0 } do
    local a, b = bit.band(bit.rshift(over, s), 255), bit.band(bit.rshift(under, s), 255)
    rgb = rgb + bit.lshift(math.floor(a * t + b * (1 - t) + 0.5), s)
  end
  return rgb
end

local function int(hex) return tonumber(hex:sub(2), 16) end

-- darkvoid.nvim sets ~30 groups; everything else (floats, diffs, Trouble, snacks, noice, ...) keeps nvim's own
-- palette, whose light half is cool and near-white. Swap it for the generated one, then fix the few groups
-- that plugins derive from it. Runs after every :colorscheme, in light mode only.
local function light_tweaks(light)
  local paper, cm, rep = int(light.bg), vim.api.nvim_get_color_map(), {}
  for name, hex in pairs(light.nvim or {}) do
    if cm[name] then rep[cm[name]] = int(hex) end
  end
  for _, c in ipairs { "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan" } do -- NvimLight<colour> is a background tint
    if light.nvim and light.nvim["NvimDark" .. c] then rep[cm["NvimLight" .. c]] = mix(int(light.nvim["NvimDark" .. c]), paper, 0.2) end
  end
  local code = vim.api.nvim_get_hl(0, { name = "MarkviewCode", link = false }).bg -- markview's code tint is a hardcoded white
  if code then rep[code] = rep[cm.NvimLightGrey1] end
  local function set(name, h)
    h.default = nil -- a `default` group would not override the existing one
    vim.api.nvim_set_hl(0, name, h)
  end
  for name, h in pairs(vim.api.nvim_get_hl(0, {})) do
    local hit = false
    for _, k in ipairs { "fg", "bg", "sp" } do
      if rep[h[k]] then
        h[k], hit = rep[h[k]], true
      end
    end
    if hit then set(name, h) end
  end

  -- gitsigns derives GitSignsStaged* by lightening the signs, which vanishes on paper: dim them towards it instead
  for name in pairs(vim.api.nvim_get_hl(0, {})) do
    local rest = name:match "^GitSignsStaged(.+)$"
    local h = rest and vim.api.nvim_get_hl(0, { name = name, link = false })
    local base = rest and vim.api.nvim_get_hl(0, { name = "GitSigns" .. rest, link = false })
    if h and h.fg and base and base.fg then
      h.fg = h.bg and base.fg or mix(base.fg, paper, 0.75) -- line highlights keep their text colour
      set(name, h)
    end
  end

  -- core/diagnostics.lua's dark line tints survive a start with background=light (no `highlight clear`): tint the paper instead
  for sev, c in pairs { Error = light.error, Warn = light.warning, Info = light.info, Hint = light.hint } do
    local name = "Diagnostic" .. sev .. "Line"
    if vim.api.nvim_get_hl(0, { name = name }).bg then set(name, { bg = mix(int(c), paper, 0.15) }) end
  end

  -- darkvoid's lualine puts teal text on the line_nr band in these modes: 2.6:1 on paper, pull it towards the text colour
  for _, mode in ipairs { "insert", "replace", "command" } do
    local name = "lualine_x_" .. mode
    local h = vim.api.nvim_get_hl(0, { name = name, link = false })
    if h.fg then
      h.fg = mix(int(light.fg), h.fg, 0.6)
      set(name, h)
    end
  end
end

return {
  {
    "aliqyan-21/darkvoid.nvim",
    lazy = false,
    config = function()
      local colors = require "darkvoid.colors"
      local dark = vim.deepcopy(colors.config.colors)

      -- 'background' comes from kitty (detected at start, set by themes/mode.d/nvim.sh on switch).
      -- Light colours are generated from the dark defaults by themes/darkvoid-light.py.
      local light_colors
      local function apply()
        package.loaded["darkvoid_light"] = nil -- regenerated on every switch
        local ok, loaded = pcall(require, "darkvoid_light")
        local light = vim.o.background == "light" and ok
        light_colors = light and loaded or nil
        colors.config.colors = vim.tbl_extend("force", dark, light_colors or {})
        -- markview mixes its tints from Normal's bg, which is transparent here; its fallback is a catppuccin white
        if light then vim.g.markview_light_bg = light_colors.bg end
        require("darkvoid").setup {
          glow = true, -- bold keywords, functions and operators in both modes
          transparent = true,
          colors = { plugins = { lualine = true } },
        }
        vim.cmd.colorscheme "darkvoid"
      end

      local applied -- the 'background' the darkvoid colours were last built for
      local function sync() -- 'background' can change without OptionSet (the terminal's answer at startup)
        if vim.o.background ~= applied then
          applied = vim.o.background
          apply()
        end
      end
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.schedule(function() -- after the plugins' own ColorScheme handlers
            if vim.o.background ~= applied then return sync() end -- nvim reloaded us for a new 'background'
            vim.api.nvim_set_hl(0, "TabLine", { reverse = false })
            if light_colors then light_tweaks(light_colors) end
            vim.cmd "redraw!" -- repaint everything at once, not window by window
          end)
        end,
      })
      vim.api.nvim_create_autocmd("OptionSet", { pattern = "background", callback = function() vim.schedule(sync) end })
      vim.api.nvim_create_autocmd({ "UIEnter", "TermResponse" }, { callback = function() vim.schedule(sync) end })
      sync()
    end,
  },
}
