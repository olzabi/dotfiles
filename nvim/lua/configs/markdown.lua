local M = {}

M.opts = {
  enabled = true,
  render_modes = { "n", "v", "i", "c" },
  latex = { enabled = false },
  bullet = {
    enabled = true,
  },
  checkbox = {
    enabled = true,
    position = "inline",
    unchecked = {
      raw = "[-]",
      icon = "   󰄱 ",
      highlight = "RenderMarkdownUnchecked",
      scope_highlight = nil,
    },
    checked = {
      -- raw = "[x]",
      icon = "   󰱒 ",
      highlight = "RenderMarkdownChecked",
      scope_highlight = nil,
    },
    custom = {
      doing = {
        raw = "[_]",
        rendered = "󰄮",
        highlight = "RenderMarkdownDoing",
      },
      wontdo = {
        raw = "[~]",
        rendered = "󰅗",
        highlight = "RenderMarkdownWontdo",
      },
    }
  },
  html = { enabled = true,  },
  -- css = { enabled = true },
  file_types = { "markdown", "FzfPreview" },
}

M.dependencies = {
  "echasnovski/mini.nvim",
  "nvim-tree/nvim-web-devicons",
  { "3rd/image.nvim", lazy = true, opts = {} },
  -- { "OXY2DEV/markview.nvim", priority = 1000},
  -- {
  --           "lukas-reineke/headlines.nvim",
  --   opts = { markdown = {disable = true}}
  --
  -- }
}

return M
