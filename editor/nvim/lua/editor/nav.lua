return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right" },
    },
  },

  {
    "chrisgrieser/nvim-spider",
    config = function()
      require("spider").setup({
        skipInsignificantPunctuation = true,
        subwordMovement = true,
        customPatterns = {},
      })

      for _, key in ipairs { "w", "e", "b", "ge" } do
        vim.keymap.set({ "n", "o", "x" }, key, function()
          require("spider").motion(key)
        end, { desc = "Spider-" .. key })
      end
    end,
  },
}
