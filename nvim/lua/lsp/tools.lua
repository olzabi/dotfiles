return {
  {
    "mgierada/lazydocker.nvim",
    cmd = "LazyDocker",
    config = function()
      require("lazydocker").setup()
    end,
    keys = { { "<leader>ul", "<cmd>Lazydocker<cr>", desc = "LazyDocker" } },
  },
}
