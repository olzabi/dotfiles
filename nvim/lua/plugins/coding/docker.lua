return {
  {
    "mgierada/lazydocker.nvim",
    cmd = "LazyDocker",
    dependencies = {
      {
        "akinsho/toggleterm.nvim",
        lazy = true,
        cmd = {
          "ToggleTerm",
          "ToggleTermSetName",
          "ToggleTermToggleAll",
          "ToggleTermSendVisualLines",
          "ToggleTermSendCurrentLine",
          "ToggleTermSendVisualSelection",
        },
      },
    },
    config = function()
      require("lazydocker").setup()
    end,
    keys = require('keymaps').lazydocker
  },
}
