return {
  {
    -- regex
    "tomiis4/Hypersonic.nvim",
    event = "CmdlineEnter",
    cmd = "Hypersonic",
    ft = { "regexp" },
    config = function()
      require("hypersonic").setup({
        -- config
      })
    end,
  },

  {
    "bennypowers/nvim-regexplainer",
    ft = { "regexp" },
    config = function()
      require("regexplainer").setup()
    end,
    requires = {
      "nvim-treesitter/nvim-treesitter",
      "MunifTanjim/nui.nvim",
    },
  },
}
