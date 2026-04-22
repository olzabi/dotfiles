return {
  {
    "vhyrro/luarocks.nvim",
    priority = 1001, -- this plugin needs to run before anything else
    opts = {
      rocks = { "magick" },
    },
  },

  {
    -- TODO: sessions manager
    "folke/persistence.nvim",
    enabled = false,
    event = "BufReadPre",
    lazy = false,
    config = function()
      require("persistence").setup(opts)

      vim.api.nvim_create_user_command("PersistenceLoad", function()
        require("persistence").load()
      end, {})

      vim.api.nvim_create_user_command("PersistenceSelect", function()
        require("persistence").select()
      end, {})

      vim.opt.sessionoptions = "buffers"

      local group = vim.api.nvim_create_augroup("user-persistence", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "PersistenceLoadPost",
        callback = function()
          vim.cmd "Neotree show"
        end,
      })
    end,
    keys = require("keymaps").persistence,
  },

  {
    -- Search & replace
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    keys = require("keymaps").grug_far,
    config = function()
      require("grug-far").setup()
    end,
  },

  {
    -- TODO:
    "stevearc/overseer.nvim",
    opts = {
      task_list = {
        direction = "left",
        bindings = {
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
          ["L"] = "IncreaseDetail",
          ["H"] = "DecreaseDetail",
          ["<PageUp>"] = "ScrollOutputUp",
          ["<PageDown>"] = "ScrollOutputDown",
        },
      },
    },
    keys = require("keymaps").overseer,
  },

  {
    "lucidph3nx/nvim-sops",
    event = { "BufEnter" },
    keys = {
      -- { "<leader>ef", vim.cmd.SopsEncrypt, desc = "Encrypt File" },
      -- { "<leader>df", vim.cmd.SopsDecrypt, desc = "Decrypt File" },
    },
  },

  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    enabled = true,
    opts = {},
    keys = require("keymaps").treesj,
  },

  {
    "gbprod/yanky.nvim",
    enabled = true,
    opts = {},
    dependencies = { "folke/snacks.nvim" },
    keys = require("keymaps").yanky,
  },

  {
    -- TODO:
    "nvim-mini/mini.nvim",
    dependencies = {
      { "nvim-mini/mini.bracketed" },
      { "nvim-mini/mini.jump" },
      { "nvim-mini/mini.ai" },
      { "nvim-mini/mini.operators" },
    },
  },

  {
    -- TODO:
    "kylechui/nvim-surround",
  },

  {
    "aznhe21/actions-preview.nvim",
    event = { "LspAttach" },
    opts = {
      backend = { "snacks", "telescope", "nui" },
      nui = {
        layout = {
          position = "50%",
          size = { width = "80%", height = "80%" },
          min_width = 40,
          min_height = 10,
          relative = "editor",
        },
        preview = { size = "60%", border = { padding = { 0, 1 } } },
        select = { size = "40%", border = { padding = { 0, 1 } } },
      },
      snacks = { layout = { preset = "telescope" } },
    },
    keys = {
      {
        "..",
        function()
          require("actions-preview").code_actions()
        end,
      },
    },
  },

  {
    -- TODO:
    "ckolkey/ts-node-action",
    config = function()
      vim.keymap.set({ "n" }, ".f", require("ts-node-action").node_action, { desc = "Trigger Node Action" })
    end,
  },
}
