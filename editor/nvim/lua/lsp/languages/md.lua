return {
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = {
      "saghen/blink.cmp",
      "nvim-treesitter/nvim-treesitter",
      "3rd/image.nvim",
    },
    opts = {
      markdown = {
        enable = true,

        markdown_inline = { enable = true },
        latex = { enable = true },
        list_items = {
          shift_width = 2,
          indent_size = 2,
          -- marker_minus = { add_padding = false },
          -- marker_plus = { add_padding = false },
          -- marker_star = { add_padding = false },
          -- marker_dot = { add_padding = false },
          -- marker_parenthesis = { add_padding = false },
        },

        preview = {
          enable = true,
          hybrid_modes = { "n", "i", "no", "c" },
          callbacks = {
            on_enable = function(_, win)
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.bo[buf].filetype
              vim.wo[win].conceallevel = 2
              vim.wo[win].concealcursor = "nc"
            end,
          },
        },

        completion = {
          blink = { enable = true },
        },
      },
    },
    config = function(_, opts)
      require("markview").setup(opts)

      vim.api.nvim_create_autocmd("User", {
        pattern = "MarkviewSplitviewOpen",
        callback = function(event)
          local source_buffer = event.data.source
          local preview_window = event.data.preview_window

          -- Enable scrollbind and cursorbind in both windows
          for _, win in ipairs(vim.fn.win_findbuf(source_buffer)) do
            vim.api.nvim_set_option_value("scrollbind", true, { win = win })
            vim.api.nvim_set_option_value("cursorbind", true, { win = win })
          end

          -- Enable scrollbind and cursorbind in the preview window
          vim.api.nvim_set_option_value("scrollbind", true, { win = preview_window })
          vim.api.nvim_set_option_value("cursorbind", true, { win = preview_window })

          -- Sync the scroll and cursor positions
          vim.cmd("syncbind")
        end,
      })

      -- Optional: Clean up when splitview closes
      vim.api.nvim_create_autocmd("User", {
        pattern = "MarkviewSplitviewClose",
        callback = function(event)
          local source_buffer = event.data.source

          -- Disable scrollbind and cursorbind in source windows
          for _, win in ipairs(vim.fn.win_findbuf(source_buffer)) do
            vim.api.nvim_set_option_value("scrollbind", false, { win = win })
            vim.api.nvim_set_option_value("cursorbind", false, { win = win })
          end
        end,
      })
    end,
  },
}
