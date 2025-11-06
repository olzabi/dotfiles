return {
  {
    -- TODO: add pipeline in neo-tree
    "topaxi/pipeline.nvim",
    build = "make",
    cmd = "Pipeline",
    keys = require("keymaps").git_pipeline,
  },

  {
    "pwntester/octo.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      -- OR 'ibhagwan/fzf-lua',
      -- OR 'folke/snacks.nvim',
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup()
    end,
  },

  {
    "ldelossa/gh.nvim",
    dependencies = {
      {
        "ldelossa/litee.nvim",
        config = function()
          require("litee.lib").setup()
        end,
      },
    },
    config = function()
      require("litee.gh").setup()
    end,
  },

  {
    "rawnly/gist.nvim",
    cmd = { "GistCreate", "GistCreateFromFile", "GistsList" },
    config = true,
  },

  { "pwntester/octo.nvim", config = true },

  {
    "f-person/git-blame.nvim",
    keys = require("keymaps.plugins").git_blame,
  },

  {
    -- this -> mini
    "lewis6991/gitsigns.nvim",
    enabled = false,
    event = { "CursorHold", "CursorHoldI" },
    config = true,
    keys = require("keymaps").gitsigns,
  },

  { "tpope/vim-fugitive", event = "VimEnter", cmd = "Git" },
  { "tpope/vim-rhubarb" },

  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = require("keymaps").lazygit,
    config = function()
      vim.g.lazygit_floating_window_scaling_factor = 1
      vim.g.lazygit_floating_window_winblend = 0 -- transparency of floating window (0-100)
      vim.g.lazygit_floating_window_scaling_factor = 0.9 -- scaling factor for floating window
      vim.g.lazygit_floating_window_border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" } -- customize lazygit popup window border characters
      vim.g.lazygit_floating_window_use_plenary = 0 -- use plenary.nvim to manage floating window if available
      vim.g.lazygit_use_neovim_remote = 1 -- fallback to 0 if neovim-remote is not installed
      vim.g.lazygit_use_custom_config_file_path = 0 -- config file path is evaluated if this value is 1
      vim.g.lazygit_config_file_path = {} -- table of custom config file paths
    end,
  },

  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = require("keymaps").git_worktree,
    config = true,
  },
}
