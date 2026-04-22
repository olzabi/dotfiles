return {
  -- Refactoring tool
  {
    "ThePrimeagen/refactoring.nvim",
    cmd = "Refactor",
    keys = require("keymaps").refactoring,
    config = function()
      require("refactoring").setup {
        prompt_func_return_type = {
          go = true,
          java = true,
          cpp = true,
          c = true,
          h = true,
          hpp = true,
          cxx = true,
        },
        prompt_func_param_type = {
          go = true,
          java = true,
          cpp = true,
          c = true,
          h = true,
          hpp = true,
          cxx = true,
        },
        show_success_message = true,
      }
      require("telescope").load_extension "refactoring"
    end,
  },

  {
    "adibhanna/phprefactoring.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    ft = "php",
    config = function()
      require("phprefactoring").setup {
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
      }
    end,
  },
}
