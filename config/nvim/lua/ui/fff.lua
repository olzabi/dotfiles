local function live_grep_fuzzy()
  require("fff").live_grep { grep = { modes = { "fuzzy", "plain" } } }
end

return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    opts = {
      title = "FFFiles",
      lazy_sync = true,
      layout = {
        height = 0.8,
        width = 0.8,
        prompt_position = "bottom",
        preview_position = "right",
        preview_size = 0.5,
        border = vim.g.border_style,
      },
      preview = {
        enabled = true,
        line_numbers = false,
        wrap_lines = false,
        filetypes = {
          markdown = { wrap_lines = true },
          text = { wrap_lines = true },
        },
      },
      frecency = {
        enabled = true,
        db_path = vim.fn.stdpath "cache" .. "/fff_nvim",
      },
      history = {
        enabled = true,
        db_path = vim.fn.stdpath "data" .. "/fff_queries",
      },
      grep = {
        smart_case = true,
        modes = { "plain", "regex", "fuzzy" },
      },
      keymaps = {
        close = "<Esc>",
        select = "<CR>",
        select_split = "<C-s>",
        select_vsplit = "<C-v>",
        select_tab = "<C-t>",
        move_up = { "<Up>", "<C-p>" },
        move_down = { "<Down>", "<C-n>" },
        preview_scroll_up = "<C-u>",
        preview_scroll_down = "<C-d>",
        cycle_grep_modes = "<S-Tab>",
        toggle_select = "<Tab>",
        send_to_quickfix = "<C-q>",
      },
    },
    keys = {
      { ";;", function() require("fff").live_grep() end, desc = "Live grep" },
      { ";<leader>", function() require("fff").find_files() end, desc = "Find files" },
      { ";ff", function() require("fff").find_files() end, desc = "Find files" },
      { ";fz", live_grep_fuzzy, desc = "Fuzzy grep" },
      { "<leader>sw", function() require("fff").live_grep_under_cursor() end, mode = { "n", "x" }, desc = "Search word or selection" },
      { ";fr", function() require("fff").find_files { resume = true } end, desc = "Resume file search" },
      { ";gr", function() require("fff").live_grep { resume = true } end, desc = "Resume grep" },
      { ";fR", "<cmd>FFFScan<cr>", desc = "Rescan files" },
    },
  },
}
