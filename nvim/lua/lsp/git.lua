return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "CursorHold", "CursorHoldI" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "󰐊" },
          topdelete = { text = "󰐊" },
          changedelete = { text = "▎" },
          untracked = { text = "▎" },
        },
      })
    end,
    keys = require("keymaps").gitsigns,
  },

  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = require("keymaps").lazygit,
    opts = {
      lazygit_floating_window_scaling_factor = 0.9,
      lazygit_floating_window_winblend = 0,
      lazygit_use_neovim_remote = 1,
    },
  },

  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = require("keymaps").git_worktree,
    config = true,
  },
}
