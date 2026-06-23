return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      dir = vim.fn.stdpath("state") .. "/sessions/",
      need = 1,
      branch = true,
    },
    keys = {
      -- stylua: ignore start
      { ";qs", function()
        require("persistence").load()
      end, desc = "Restore Session" },
      { ";qS", function()
        require("persistence").select()
      end, desc = "Select Session" },
      { ";ql", function()
        require("persistence").load({ last = true })
      end, desc = "Restore Last Session" },
      { ";qw", function()
        require("persistence").save()
      end, desc = "Save Session" },
      { ";qr", function()
        require("persistence").start()
      end, desc = "Resume Session Saving" },
      { ";qd", function()
        require("persistence").stop()
      end, desc = "Stop Session Saving" },
      { ";qx", function()
        local dir = vim.fn.stdpath("state") .. "/sessions/"
        local files = vim.fn.glob(dir .. "*.vim", false, true)
        for _, file in ipairs(files) do
          vim.fn.delete(file)
        end
        vim.notify(("Deleted %d sessions"):format(#files), vim.log.levels.INFO)
      end, desc = "Delete All Sessions" },
      -- stylua: ignore end
    },
  },

  {
    -- Search & replace
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        "<leader>sR",
        function()
          local ext = vim.bo.buftype == "" and vim.fn.expand "%:e"
          require("grug-far").open {
            transient = true,
            prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
          }
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
    config = function()
      require("grug-far").setup({
        startInInsertMode = false,
        prefills = {
          flags = "--smart-case --no-ignore --hidden",
        },
      })
    end,
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
    dependencies = "nvim-treesitter/nvim-treesitter",
    opts = {},
    keys = {
      { ".j", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
    },
  },

  {
    "gbprod/yanky.nvim",
    enabled = false,
    opts = {},
    dependencies = "folke/snacks.nvim",
    keys = {
      -- stylua: ignore start
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before" },
      { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put after selection" },
      { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put before selection", },
      { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after" },
      { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before" },
      { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put indented after" },
      { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indented before" },
      { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put indent right" },
      { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put indent left" },
      { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put before indent right" },
      { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put before indent left" },
      { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put after filter" },
      { "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put before filter" },
      -- stylua: ignore end
    },
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
    config = function()
      require("nvim-surround").setup()
    end,
  },

  {
    "aznhe21/actions-preview.nvim",
    event = { "LspAttach" },
    opts = {
      backend = { "snacks", "nui" },
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
      snacks = {
        layout = { preset = "vertical" },
      },
    },
    keys = {
      -- stylua: ignore start
      { "..", function() require("actions-preview").code_actions() end, },
      -- stylua: ignore end
    },
  },

  {
    "ckolkey/ts-node-action",
    config = function()
      vim.keymap.set({ "n" }, ".<leader>", require("ts-node-action").node_action, { desc = "Trigger Node Action" })
    end,
  },
}
