return {
  {
    "mgierada/lazydocker.nvim",
    cmd = "LazyDocker",
    config = function()
      require("lazydocker").setup()
    end,
    keys = require("keymaps").lazydocker,
  },
}
