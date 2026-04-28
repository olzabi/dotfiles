return {

  {
    "folke/flash.nvim",
    event = "VeryLazy", -- loads after UI, before you type
    opts = {
      modes = {
        char = {
          enabled = false,
        }
      }
    },
    keys = {
      { "ff",    mode = { "n", "x", "o" }, function() require("flash").jump()       end, desc = "Flash", },
      { "ft",    mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter", },
      { "fr",    mode = { "o" },           function() require("flash").remote()     end, desc = "Remote Flash", },
      { "st",    mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search", },
      { "<c-s>", mode = { "c" },           function() require("flash").toggle()     end, desc = "Toggle Flash Search", },
    },
  },
}
