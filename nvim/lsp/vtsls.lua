local capabilities = require("configs.lsp.capabilities")
local on_attach = require("configs.lsp.on_attach")

local vue_path = vim.fn.expand("$MASON/packages") .. "/vue-language-server" .. "/node_modules/@vue/language-server"
local vue_language_server_path = vim.fn.stdpath("data")
  .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vue_path or vue_language_server_path,
  languages = { "vue" },
  configNamespace = "typescript",
}

local globalPlugins = { vue_plugin }

-- ---@module "vim.lsp.client"
-- ---@class vim.lsp.ClientConfig
return {
  cmd = { "vtsls", "--stdio" },
  -- NOTE: jsx, tsx turned off, might be unappropriate
  filetypes = {
    -- "vue",
    "typescriptreact",
    "typescript",
    "javascript",
  },
  root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
  settings = {
    completeFunctionCalls = true,
    vtsls = {
      autoUseWorkspaceTsdk = true,
      tsserver = { globalPlugins = globalPlugins },
    },
    typescript = {
      preferences = {
        importModuleSpecifier = "non-relative",
        updateImportsOnFileMove = { enabled = "always" },
        suggest = { completeFunctionCalls = true },
      },
    },
    javascript = {
      implicitProjectConfig = {
        checkJs = false,
        allowJs = true,
        skipLibCheck = true,
        -- target = "ES2020",
        -- module = "ESNext",
      },
    },
  },

  capabilities = capabilities,
  on_attach = on_attach,
}
