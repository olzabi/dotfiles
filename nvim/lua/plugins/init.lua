return {

  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall" },
    lazy = false,
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        config = function() require("configs.lsp").mason_setup() end,
      },
    },
    opts = {
      ensure_installed = require("utils.packages").lsp_packages,
      ui = { border = "single" },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = require("configs.cmp").dependencies,
    ---@param config cmp.ConfigSchema
    config = require("configs.cmp").config,
  },

  {
    -- popular language parser for syntax highlighting
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre" },
    build = ":TSUpdate",
    dependencies = require("configs.treesitter").dependencies,
    config = require("configs.treesitter").config,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    lazy = false,
    config = function()
      require("configs.lsp").setup_lsp()
    end,
  },

  "brianhuster/live-preview.nvim",

  { "3rd/diagram.nvim", ft = { "markdown" } },
  {
    "vhyrro/luarocks.nvim",
    priority = 1001, -- this plugin needs to run before anything else
    opts = {
      rocks = { "magick" },
    },
  },

  {
    "3rd/image.nvim",
    enabled = true,
    opts = {
      backend = "viu",
      -- backend = "ueberzug",
      processor = "magick_cli",
      -- hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki", "quarto" },
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
    },
  },

  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = require("configs.snacks").opts,
    init = require("configs.snacks").init,
    keys = require("keymaps").snacks,
  },

  {
    -- TODO:
    "echasnovski/mini.nvim",
    dependencies = require("configs.mini").dependencies,
  },

  {
    enabled = false,
    "kawre/leetcode.nvim",
    cmd = "Leet",
    build = ":TSUpdate html",
    event = { "BufRead leetcode.nvim", "BufNewFile leetcode.nvim" },
    lazy = "leet" ~= vim.fn.argv()[1],
    dependencies = require("configs.leetcode").dependencies,
    opts = require("configs.leetcode").opts,
  },

  {
    "alex-popov-tech/store.nvim",
    dependencies = "OXY2DEV/markview.nvim", -- optional, for pretty readme preview / help window
    cmd = "Store",
    opts = {},
  },

  {
    "codethread/qmk.nvim",
    opts = {
      name = "corne",
      variant = "zmk",
      layout = {
        "x x x x x x _ x x x x x x",
        "x x x x x x _ x x x x x x",
        "x x x x x x _ x x x x x x",
        "_ _ _ x x x _ x x x _ _ _",
      },
    },
  },

  {
    "adelarsq/image_preview.nvim",
    event = "VeryLazy",
    config = function()
      require("image_preview").setup()
    end,
  },
}
