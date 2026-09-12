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

      vim.keymap.set({ "w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } })
      vim.keymap.set({ "e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } })
      vim.keymap.set({ "b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } })
      vim.keymap.set({ "ge", "<cmd>lua require('spider').motion('ge')<CR>", mode = { "n", "o", "x" } })
    end,
  },
}
