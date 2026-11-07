return {
  {
    "OXY2DEV/markview.nvim",
    lazy = false, -- plugin docs advise against lazy-loading
    dependencies = {
      "saghen/blink.cmp", -- markview auto-registers its blink source when blink is loaded
      "nvim-treesitter/nvim-treesitter",
      "3rd/image.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = function()
      local presets = require("markview.presets")

      -- nerd-font icons draw 2 cells wide but count as 1, swallowing the preset's single space
      local headings = vim.deepcopy(presets.headings.glow)
      for i = 1, 6 do
        local h = headings["heading_" .. i]
        h.icon = h.icon .. " "
      end

      return {
        preview = {
          enable = true,
          icon_provider = "devicons", -- already loaded by statusline/bufferline
          hybrid_modes = { "n", "i", "no", "c" },
          -- tables stay rendered under the cursor: a raw row can't line up with the virtual borders.
          -- needs node-wise hybrid mode; linewise_hybrid_mode ignores raw_previews
          raw_previews = { markdown = { "!tables" } },
          callbacks = {
            on_enable = function(_, wins)
              for _, win in ipairs(wins) do
                vim.wo[win].conceallevel = 2
                vim.wo[win].concealcursor = "nc"
              end
            end,
          },
        },
        markdown = {
          headings = headings,
          horizontal_rules = presets.horizontal_rules.thin,
          list_items = {
            shift_width = 2,
            indent_size = 2,
          },
          code_blocks = {
            style = "block",
            min_width = 80,
            label_direction = "left",
          },
          tables = {
            -- virt lines: top/bottom borders always draw, even with no blank line around the table
            use_virt_lines = true,
            parts = presets.tables.rounded.parts,
          },
        },
        markdown_inline = {
          enable = true,
          checkboxes = presets.checkboxes.nerd,
        },
        latex = { enable = true },
      }
    end,
    config = function(_, opts)
      require("markview").setup(opts)

      local function bind(wins, on)
        for _, win in ipairs(wins) do
          if vim.api.nvim_win_is_valid(win) then
            vim.wo[win].scrollbind = on
            vim.wo[win].cursorbind = on
          end
        end
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "MarkviewSplitviewOpen",
        callback = function(ev)
          local wins = vim.fn.win_findbuf(ev.data.source)
          table.insert(wins, ev.data.preview_window)
          bind(wins, true)
          vim.cmd("syncbind")
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "MarkviewSplitviewClose",
        callback = function(ev)
          bind(vim.fn.win_findbuf(ev.data.source), false)
        end,
      })
    end,
  },

  -- {
  --   "MeanderingProgrammer/render-markdown.nvim",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "nvim-mini/mini.nvim",
  --     -- "nvim-mini/mini.icons",
  --     -- "nvim-tree/nvim-web-devicons",
  --   }, -- if you use the mini.nvim suite,
  --   ---@module 'render-markdown'
  --   ---@type render.md.UserConfig
  --   -- opts = {  },
  --   opts = {
  --     file_types = { "markdown" },
  --     heading = { sign = false },
  --     code = { sign = false },
  --     latex = { enabled = false },
  --   },
  -- },
}
