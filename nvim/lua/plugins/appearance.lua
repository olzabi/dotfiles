return {
  {
    "aliqyan-21/darkvoid.nvim",
    lazy = false,
    config = function()
      vim.api.nvim_set_hl(0, "TabLine", { reverse = false })
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.schedule(function()
            vim.api.nvim_set_hl(0, "TabLine", { reverse = false })
          end)
        end,
      })

      vim.cmd([[
      colorscheme darkvoid
      ]])

      require("darkvoid").setup({
        glow = true,
        colors = {
          plugins = {
            lualine = true,
          },
        },
      })
    end,
    -- NOTE: TabLine is temporary fix after switching from nvim 0.10 to 0.11
  },

  "kdheepak/monochrome.nvim",
  "slugbyte/lackluster.nvim",
  "jonathanfilip/vim-lucius",
  "robertmeta/nofrils",
  -- "fxn/vim-monochrome",

  {
    -- Statusline
    "nvim-lualine/lualine.nvim",
    event = { "BufReadPost", "BufAdd", "BufNewFile" },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "bwpge/lualine-pretty-path",
    },
    opts = require("configs.lualine"),
  },

  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    event = "VimEnter",
    keys = require("keymaps").transparent,
    config = require("configs.transparent").config,
  },

  {
    "goolord/alpha-nvim",
    lazy = false,
    event = { "VimEnter", "BufWinEnter" },
    config = require("configs.alpha").config,
  },

  {
    "folke/noice.nvim",
    event = "VimEnter",
    lazy = false,
    cmd = "Noice",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        lazy = true,
        opts = {
          background_colour = "#000",
        },
      },
      "vigoux/notifier.nvim",
    },
    opts = require("configs.noice").opts,
    keys = require("keymaps").noice,
  },

  {
    -- TODO: opts/config
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      progress = {
        suppress_on_insert = true,
        ignore_done_already = false,
        ignore_empty_message = false,
      },
      notification = {
        override_vim_notify = true,
        window = {
          winblend = 0,
          border = "none",
        },
      },
    },
  },
}
