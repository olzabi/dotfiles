return {

  {
    "mfussenegger/nvim-lint",
    event = {
      "BufWritePost",
      "BufReadPost",
      "InsertLeave",
    },
    config = require("configs.formatters").lint,
  },

  {
    "stevearc/conform.nvim",
    dependencies = {
      "MunifTanjim/prettier.nvim",
      "mcauley-penney/tidy.nvim",
      "bennypowers/svgo.nvim",
    },
    event = { "BufWritePre", "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    opts = require("configs.formatters").conform,
    keys = require("keymaps").formatter,
  },
}
