return {
  {
    "christoomey/vim-tmux-navigator",
    enabled = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
    },
  },

  {
    "lmilojevicc/herdr-splits.nvim",
    cond = vim.env.HERDR_ENV == "1",
    lazy = false,
    build = ':lua require("herdr-splits").sync_herdr()',
    config = function()
      require("herdr-splits").setup({
        -- Defaults shown. All fields optional.
        default_amount = 0.03, -- Herdr resize ratio
        neovim_amount = 3, -- Neovim resize cells
        at_edge = "wrap", -- 'wrap' | 'stop' | 'split' | function
        ignored_buftypes = { "nofile", "quickfix", "prompt", "help", "terminal" },
        ignored_filetypes = {
          "NvimTree",
          -- sidebars
          "neo-tree",
          "snacks_dashboard",
          "snacks_explorer",
          "snacks_picker",
          -- DB / REPL / data sidebars
          "dadbod-ui",
          "dbout",
          -- outlines / symbols
          "aerial",
          "Outline",
          -- diagnostics / quick lists
          "Trouble",
          "quickfix",
        },
        move_cursor_same_row = false,
        herdr_bin = nil, -- auto-detected from HERDR_BIN_PATH
        floating_zindex_max = 50, -- floats with zindex < this are treated as embedded sidebars
        ignore_previewwindows = false, -- opt-in: also treat previewwindow windows (e.g. .dbout) as sidebars
        auto_sync_herdr = true, -- opt-in: sync Herdr-side scripts on update
        -- Managed keys — written to the generated herdr-splits.conf so the
        -- Herdr-side scripts agree. Pass Neovim notation (e.g. <M-Left>).
        nav_keys = { left = "<M-left>", down = "<M-down>", up = "<M-up>", right = "<M-right>" },
        resize_keys = { left = "<M-C-left>", down = "<M-C-down>", up = "<M-C-up>", right = "<M-C-right>" },
        unzoom_on_nav = true, -- auto-unzoom when navigating away from a zoomed pane
        nav_at_edge = "wrap", -- 'wrap' | 'stop' — Herdr pane-boundary wrap (distinct from at_edge)
      })
    end,
    keys = {
      -- stylua: ignore start
      { "<M-left>",   function() require("herdr-splits").move_cursor_left()  end, desc = "Navigate left", },
      { "<M-down>",   function() require("herdr-splits").move_cursor_down()  end, desc = "Navigate down", },
      { "<M-up>",     function() require("herdr-splits").move_cursor_up()    end, desc = "Navigate up", },
      { "<M-right>",  function() require("herdr-splits").move_cursor_right() end, desc = "Navigate right", },
      { "<M-C-left>", function() require("herdr-splits").resize_left()       end, desc = "Resize left", },
      { "<M-C-down>", function() require("herdr-splits").resize_down()       end, desc = "Resize down", },
      { "<M-C-up>",   function() require("herdr-splits").resize_up()         end, desc = "Resize up", },
      { "<M-C-right>",function() require("herdr-splits").resize_right()      end, desc = "Resize right", },
      -- stylua: ignore end
    },
  },

}
