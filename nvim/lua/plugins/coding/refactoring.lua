return {
  -- Refactoring tool
  {
    "ThePrimeagen/refactoring.nvim",
    cmd = "Refactor",
    keys = require("keymaps").refactoring,
    opts = require("configs.refactoring").opts,
    config = function(_, opts)
      require("refactoring").setup(opts)
      require("telescope").load_extension("refactoring")
    end,
  },

  {
    "adibhanna/phprefactoring.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    ft = "php",
    config = function()
      require("phprefactoring").setup({
        ui = {
          use_floating_menu = true,
          border = "rounded",
          width = 45,
        },
        refactor = {
          show_preview = true,
          confirm_destructive = true,
          auto_format = true,
        },
        lsp = {
          use_lsp_rename = true,
          preferred_clients = { "intelephense", "phpactor", "psalm" },
        },
      })
    end,
  },
}
