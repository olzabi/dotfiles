local M = {}

local opts = {
  -- enable = true,
  groups = { -- table: default groups
    "Normal",
    "NormalNC",
    "Comment",
    "Constant",
    "Special",
    "Identifier",
    "Statement",
    "PreProc",
    "Type",
    "Underlined",
    "Todo",
    "String",
    "Function",
    "Conditional",
    "Repeat",
    "Operator",
    "Structure",
    "LineNr",
    "NonText",
    "SignColumn",
    "CursorLine",
    "CursorLineNr",
    "StatusLine",
    "StatusLineNC",
    "EndOfBuffer",
    "BufferLineFill",
    -- "TabLine",
    -- "TabLineFill",
    -- "TabLineSel",
    -- "TabLineSeparator",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
  },
  extra_groups = {
    "NormalFloat", -- plugins which have float panel such as Lazy, Mason, LspInfo
    "NeoTreeNormal",
    "NeoTreeNormalNC",
  },
  exclude_groups = {
    "FloatBorder",
    "Term*",
    "TabLine",
    "TabLineFill",
    "TabLineSel",
    "TabLineSeparator",
    -- "winblend",
    -- "lualine",
    -- "StatusLine",
    -- "StatusLineNC",
  },
}

M.config = function()
  local transparent = require("transparent")
  transparent.setup(opts)
end

return M
