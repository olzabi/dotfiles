return {
  {
    "piersolenski/wtf.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
    },
    opts = {},
    keys = {
      -- {  "<leader>wd", mode = { "n", "x" }, function() require("wtf").diagnose() end, desc = "Debug diagnostic with AI", },
      -- {  "<leader>wf", mode = { "n", "x" }, function() require("wtf").fix() end, desc = "Fix diagnostic with AI", },
      -- {  "<leader>ws", mode = { "n" },      function() require("wtf").search() end, desc = "Search diagnostic with Google", },
      -- {  "<leader>wp", mode = { "n" },      function() require("wtf").pick_provider() end, desc = "Pick provider", },
      -- {  "<leader>wh", mode = { "n" },      function() require("wtf").history() end, desc = "Populate the quickfix list with previous chat history", },
      -- {  "<leader>wg", mode = { "n" },      function() require("wtf").grep_history() end, desc = "Grep previous chat history with Telescope", },
      -- {  "<leader>wy", mode = { "n", "x" }, function() require("wtf").yank() end, desc = "Yank diagnostic to clipboard", },
    },
  },
}
