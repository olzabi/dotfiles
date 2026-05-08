return {
  {
    -- It's used instead of ts_ls, tsserver and vtsls
    -- due to poor optimization
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = {
      -- "BufEnter",
      "BufRead *.js,*.jsx,*.mjs,*.cjs,*.ts,*.tsx",
      "BufNewFile *.js,*.jsx,*.mjs,*.cjs,*.ts,*.tsx",
    },
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    code_lens = "all",
    config = function()
      require("typescript-tools").setup {
        filetypes = {
          "javascript",
          "typescript",
          "vue",
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
          composite_mode = "separate_diagnostic",
        },
      }

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.ts,*.tsx,*.jsx,*.js",
        callback = function(args)
          vim.cmd "silent! undojoin | TSToolsAddMissingImports sync"
          vim.cmd "silent! undojoin | TSToolsOrganizeImports sync"
          require("conform").format { bufnr = args.buf }
        end,
      })
    end,
  },

  { "dmmulroy/tsc.nvim" },
  -- { "dmmulroy/ts-error-translator.nvim", opts = { auto_override_publish_diagnostics = true } },
  {
    "bennypowers/nvim-regexplainer",
    ft = { "regexp" },
    config = function()
      require("regexplainer").setup()
    end,
    requires = {
      "nvim-treesitter/nvim-treesitter",
      "MunifTanjim/nui.nvim",
    },
  },

  {
    "Redoxahmii/json-to-types.nvim",
    build = "sh install.sh npm", -- Replace `npm` with your preferred package manager (e.g., yarn, pnpm).
    ft = "json",
    keys = {
      {
        "<leader>cjU",
        "<CMD>ConvertJSONtoLang typescript<CR>",
        desc = "Convert JSON to TS",
      },
      {
        "<leader>cjt",
        "<CMD>ConvertJSONtoLangBuffer typescript<CR>",
        desc = "Convert JSON to TS Buffer",
      },
    },
  },

  {
    -- Better packages info for npm/yarn/pnpm
    "vuki656/package-info.nvim",
    opts = {
      package_manager = "npm",
      autostart = true,
    },
    config = function()
      require("package-info").setup()
    end,
    ft = { "npm", "js" },
  },
}
