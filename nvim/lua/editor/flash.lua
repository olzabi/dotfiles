return {

  {
    "folke/flash.nvim",
    event = "VeryLazy", -- loads after UI, before you type
    opts = {
      modes = {
        char = { enabled = true, },
        search = { enabled = false }, -- don't hijack /
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump", },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter", },
    },
  },


}
