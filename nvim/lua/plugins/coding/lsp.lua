return {

  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall" },
    lazy = false,
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        config = function()
          require("configs.lsp").mason_setup()
        end,
      },
    },
    opts = {
      ensure_installed = require("utils.packages").lsp_packages,
      ui = { border = "single" },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = require("configs.cmp").dependencies,
    ---@param config cmp.ConfigSchema
    config = require("configs.cmp").config,
  },

  {
    -- Code actions preview
    "aznhe21/actions-preview.nvim",
    event = { "LspAttach" },
    opts = {
      -- priority list of preferred backend
      backend = { "snacks", "telescope", "nui" },
      -- options for nui.nvim components
      nui = {
        -- options for nui Layout component: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/layout
        layout = {
          position = "50%",
          size = {
            width = "80%",
            height = "80%",
          },
          min_width = 40,
          min_height = 10,
          relative = "editor",
        },
        -- options for preview area: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup
        preview = {
          size = "60%",
          border = {
            padding = { 0, 1 },
          },
        },
        -- options for selection area: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/menu
        select = {
          size = "40%",
          border = {
            padding = { 0, 1 },
          },
        },
      },
      snacks = {
        layout = { preset = "telescope" },
      },
    },

    -- config = function()
    --   -- code actions on ..
    --   vim.keymap.set({ "v", "n" }, "..", require("actions-preview").code_actions)
    -- end,
    keys = {
      {
        "..",
        function()
          require("actions-preview").code_actions()
        end,
      },
    },
  },
}
