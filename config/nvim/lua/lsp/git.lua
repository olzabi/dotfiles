return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "CursorHold", "CursorHoldI" },
    config = function()
      require("gitsigns").setup {
        signs = {
          add = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "󰐊" },
          topdelete = { text = "󰐊" },
          changedelete = { text = "▎" },
          untracked = { text = "▎" },
        },
      }
    end,
    keys = {
      -- stylua: ignore start
      { "<leader>Gp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Preview hunk" },
      { "<leader>GB", function() require("gitsigns").blame() end, desc = "Blame" },
      -- stylua: ignore end
    },
  },

  -- lazygit.nvim -> snacks.lazygit (snacks is already loaded); git-worktree.nvim -> worktrunk (`wt`)
  {
    "folke/snacks.nvim",
    keys = {
      -- stylua: ignore start
      { ";G", function() Snacks.lazygit() end, desc = "LazyGit" },
      -- stylua: ignore end
    },
  },
}
