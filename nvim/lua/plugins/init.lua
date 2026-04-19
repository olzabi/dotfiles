return {

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
    dependencies = { "luarocks.nvim" },
    enabled = true,
    config = require "configs.image",
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
    "nvim-mini/mini.nvim",
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
    -- Diagnostics tool
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
    keys = require("keymaps").trouble,
  },

  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall" },
    lazy = false,
    config = function()
      require("configs.lsp").mason()
      require("configs.lsp").setup()
    end,
  },

  {
    -- Code actions preview
    "aznhe21/actions-preview.nvim",
    event = { "LspAttach" },
    opts = {
      backend = { "snacks", "telescope", "nui" },
      nui = {
        layout = {
          position = "50%",
          size = { width = "80%", height = "80%" },
          min_width = 40,
          min_height = 10,
          relative = "editor",
        },
        preview = { size = "60%", border = { padding = { 0, 1 } } },
        select = { size = "40%", border = { padding = { 0, 1 } } },
      },
      snacks = { layout = { preset = "telescope" } },
    },

    keys = {
      {
        "..",
        function()
          require("actions-preview").code_actions()
        end,
      },
    },
  },

  { "artemave/workspace-diagnostics.nvim" },
}
