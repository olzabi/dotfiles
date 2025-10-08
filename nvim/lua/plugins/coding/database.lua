return {
  {
    "tpope/vim-dadbod",
    lazy = true,
    dependencies = {
      {
        "kristijanhusak/vim-dadbod-ui",
        cmd = {
          "DBUI",
          "DBUIToggle",
          "DBUIAddConnection",
          "DBUIFindBuffer",
        },
        init = function()
          vim.g.db_ui_execute_on_save = 0
          vim.g.db_ui_use_nerd_fonts = 1
        end,
      },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    -- event = 'VeryLazy',
    config = require("configs.db").config,
    keys = require("keymaps").vim_dadbod,
  },

  -- {
  --   "xemptuous/sqlua.nvim",
  --   lazy = true,
  --   cmd = "SQLua",
  --   config = function()
  --     require("sqlua").setup()
  --   end,
  -- },
}
