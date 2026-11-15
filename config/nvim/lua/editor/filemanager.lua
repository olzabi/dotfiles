return {

  {
    "mikavilpas/yazi.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<F6>", "<cmd>Yazi cwd<cr>", desc = "Yazi (cwd)" },
      { "<F11>", "<cmd>Yazi<cr>", desc = "Yazi (current file)" },
    },
  },
}
