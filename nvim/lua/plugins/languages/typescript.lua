local capabilities = require("configs.lsp.capabilities")
local on_attach = require("configs.lsp.on_attach")
local opts = {
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    -- "vue",
  },
  settings = {
    tsserver_file_preferences = {
      importModuleSpecifierPreference = "non-relative",
      includeCompletionsForModuleExports = true,
    },
    jsx_close_tag = {
      enable = false,
      filetypes = {
        "javascriptreact",
        "typescriptreact",
      },
    },
    tsserver_plugins = { "@vue/typescript-plugin" },
    tsserver_max_memory = "auto",
    expose_as_code_action = "all",
    separate_diagnostic_server = true,
    publish_diagnostic_on = "insert_leave",
    composite_mode = 'separate_diagnostic',
  },
  capabilities = capabilities,
  on_attach = on_attach,
}

return {
  {
    -- It's used instead of ts_ls, tsserver and vtsls
    -- due to poor optimization
    "pmizio/typescript-tools.nvim",
    build = "yarn add global @vue/typescript-plugin",
    lazy = false,
    event = {
      -- "BufEnter",
      "BufRead *.js,*.jsx,*.mjs,*.cjs,*.ts,*.tsx",
      "BufNewFile *.js,*.jsx,*.mjs,*.cjs,*.ts,*.tsx",
    },
    code_lens = "all",
    config = function()
      require("typescript-tools").setup(opts)

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.ts,*.tsx,*.jsx,*.js",
        callback = function(args)
          vim.cmd("silent! undojoin | TSToolsAddMissingImports sync")
          vim.cmd("silent! undojoin | TSToolsOrganizeImports sync")
          require("conform").format({ bufnr = args.buf })
        end,
      })
    end,
    keys = require("keymaps").typescript,
  },

  -- {
  --   "luckasRanarison/tailwind-tools.nvim",
  --   name = "tailwind-tools",
  --   build = ":UpdateRemotePlugins",
  --   opts = {},
  -- },

  {
    "OlegGulevskyy/better-ts-errors.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      -- keymaps = {
      -- toggle = "<leader>zd", -- default '<leader>dd'
      -- go_to_definition = "<leader>zx", -- default '<leader>dx'
      -- },
    },
  },
  { "dmmulroy/tsc.nvim" },
  { "davidosomething/format-ts-errors.nvim" },
  { "dmmulroy/ts-error-translator.nvim", opts = { auto_override_publish_diagnostics = true } },
}
