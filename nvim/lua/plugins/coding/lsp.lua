return {

  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall" },
    lazy = false,
    config = function()
      require("configs.lsp").mason()
      require("configs.lsp").setup()
    end,
  },

  {
    -- Code actions preview
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

  { "artemave/workspace-diagnostics.nvim" },
}
