return {
  {
    "OXY2DEV/markview.nvim",
    dependencies = {
      "saghen/blink.cmp",
      "nvim-treesitter/nvim-treesitter",
      "3rd/image.nvim",
    },
    opts = {
      highlight_groups = {
        RenderMarkdownDoing = { link = "DiagnosticWarn" },
        RenderMarkdownWontdo = { link = "DiagnosticHint" },
      },

      preview = {
        enable = true,
        hybrid_modes = { "n", "i" },
        callbacks = {
          on_enable = function(_, win)
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            if vim.tbl_contains({ "Avante", "codecompanion" }, ft) then
              return false
            end
          end,
        },
      },

      markdown = {
        headings = {
          enable = true,
          shift_width = 0,
          heading_1 = { style = "label", sign = "", icon = "󰲡 ", hl = "MarkviewHeading1", },
          heading_2 = { style = "label", icon = "󰲣 ", hl = "MarkviewHeading2" },
          heading_3 = { style = "label", icon = "󰲥 ", hl = "MarkviewHeading3" },
          heading_4 = { style = "simple", icon = "󰲧 ", hl = "MarkviewHeading4" },
          heading_5 = { style = "simple", icon = "󰲩 ", hl = "MarkviewHeading5" },
          heading_6 = { style = "simple", icon = "󰲫 ", hl = "MarkviewHeading6" },
        },
        checkboxes = {
          enable = true,
          checked   = {           text = "󰱒", hl = "RenderMarkdownChecked" },
          unchecked = {           text = "󰄱", hl = "RenderMarkdownUnchecked" },
          custom = {
            { match_string = "_", text = "󰄮", hl = "RenderMarkdownDoing", },
            { match_string = "~", text = "󰅗", hl = "RenderMarkdownWontdo", },
          },
        },
        list_items = {
          enable = true,
          marker_minus = { add_padding = true, text = "●", hl = "MarkviewListItemMinus" },
          marker_plus = { add_padding = true, text = "◆", hl = "MarkviewListItemPlus" },
          marker_star = { add_padding = true, text = "◇", hl = "MarkviewListItemStar" },
        },
        tables = {
          enable = true,
          parts = {
            top           = { "╭", "─", "╮", "┬" },
            header        = { "├", "─", "┤", "┼" },
            separator     = { "├", "─", "┤", "┼" },
            row           = { "│", " ", "│", "│" },
            bottom        = { "╰", "─", "╯", "┴" },
            overlap       = { "┼", "─", "┼", "┼" },
            align_center  = { "╼", "╾" },
            align_left    = "╼",
            align_right   = "╾",
            align_default = "│",
          },
        },

        block_quotes = {
          enable = true,
          default = { border = "▋", border_hl = "MarkviewBlockQuoteDefault" },
          callouts = {
            { match_string = "NOTE",      callout_preview = "󰋽 Note",      border_hl = "MarkviewBlockQuoteNote", },
            { match_string = "TIP",       callout_preview = "󰌶 Tip",       border_hl = "MarkviewBlockQuoteTip", },
            { match_string = "WARNING",   callout_preview = "󰀪 Warning",   border_hl = "MarkviewBlockQuoteWarn", },
            { match_string = "DANGER",    callout_preview = " Danger",     border_hl = "MarkviewBlockQuoteError", },
            { match_string = "IMPORTANT", callout_preview = "󰅾 Important", border_hl = "MarkviewBlockQuoteSpecial", },
          },
        },
        horizontal_rules = {
          enable = true,
          parts = { { type = "repeating", text = "─", hl = "MarkviewGradient1" } },
        },
      },
      latex = { enable = false },
      completion = {
        blink = { enable = true },
      },
    },
  },
}
