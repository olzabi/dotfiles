---@diagnostic disable: redundant-value
---@diagnostic disable: redundant-value
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
      { "<leader>Gp", "<cmd>Gitsigns preview_hunk<cr>",           desc = "Preview hunk" },
      { "<leader>GB", function() require("gitsigns").blame() end, desc = "Blame" },
    },
  },

  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = { { "<leader>Gl", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
    init = function()
      vim.g.lazygit_floating_window_scaling_factor = 0.9
      vim.g.lazygit_floating_window_winblend = 0
      vim.g.lazygit_use_neovim_remote = 1
    end,
  },

  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
  },
}
