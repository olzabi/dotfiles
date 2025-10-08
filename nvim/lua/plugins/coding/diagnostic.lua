return {
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
    "rachartier/tiny-inline-diagnostic.nvim",
    priority = 1000, -- needs to be loaded in first
    config = function()
      require("tiny-inline-diagnostic").setup({
        preset = "minimal",
      })
      vim.diagnostic.config({ virtual_text = false }) -- Only if needed in your configuration, if you already have native LSP diagnostics
    end,
  },
  { "artemave/workspace-diagnostics.nvim" },

}
