return {
  {
    "andythigpen/nvim-coverage",
    version = "*",
    config = function()
      require("coverage").setup({
        auto_reload = true,
      })
    end,
  },

  {
    "klen/nvim-test",
    config = function()
      require("nvim-test").setup()
    end,
  },

  {
    "David-Kunz/jester",
    config = function()
      require("jester").setup({
        dap = {
          console = "externalTerminal",
        },
      })
    end,
  },

    {
    -- Add neotest-pest plugin for running PHP tests.
    -- A package is also available for PHPUnit if needed.
    "nvim-neotest/neotest",
    dependencies = { "V13Axel/neotest-pest" },
    opts = { adapters = { "neotest-pest" } },
  },

}
