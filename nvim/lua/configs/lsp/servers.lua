local M = {}

M.servers = {
  angularls = {},
  eslint = { settings = { packageManager = "npm" } },
  emmet_ls = { filetypes = { "css", "sass", "scss" } },
  html = {
    filetypes = { "html", "htm", "blade" },
    init_options = {
      configurationSection = { "html", "css", "javascript" },
      embeddedLanguages = { css = true, javascript = true },
      provideFormatter = true,
    },
  },
  cssls = {
    filetypes = { "css", "scss", "less" },
    root_markers = { "package.json", ".git" },
    settings = {
      css = { validate = true, lint = { unknownAtRules = "ignore" } },
      less = { validate = true, lint = { unknownAtRules = "ignore" } },
      scss = { validate = true, lint = { unknownAtRules = "ignore" } },
    },
  },

  svelte = {},
  -- tailwindcss = {
  --   filetypes = { "javascriptreact", "typescriptreact", "html", "css", "scss", "templ" },
  --   settings = {
  --     tailwindCSS = {
  --       classAttributes = { "class", "className", "classList" },
  --       emmetCompletions = true,
  --       hovers = true,
  --       suggestions = true,
  --     },
  --   },
  -- },

  taplo = {}, -- toml
  sqlls = {},
  -- marksman = {},
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    settings = { staticcheck = true, telemetry = false },
  },
  golangci_lint_ls = {},
  rust_analyzer = { filetypes = { "rust" } },
  pyright = {
    filetypes = "python",
    settings = { python = { pythonPath = require("utils").get_python_path() } },
  },
  prismals = {},
  graphql = {},

  ansiblels = {},
  terraformls = { filetypes = { "terraform", "tf", "terraform-vars" } },
  bashls = { filetypes = { "sh", "zsh", "bash" }, single_file_support = true },

  -- docker
  dockerls = {},
  docker_compose_language_service = {},

  -- php
  -- phpactor = {
  --   filetypes = { "php", "blade" },
  --   root_dir = function(_)
  --     return vim.loop.cwd()
  --   end,
  --   init_options = {
  --     ["language_server.diagnostics_on_update"] = false,
  --     ["language_server.diagnostics_on_open"] = false,
  --     ["language_server.diagnostics_on_save"] = false,
  --     ["language_server_phpstan.enabled"] = true,
  --     ["language_server_phpstan.level"] = "8",
  --     ["language_server_psalm.enabled"] = false,
  --   },
  -- },

  zls = {
    settings = {
      zls = {
        enable_inlay_hints = true,
        enable_snippets = true,
        warn_style = true,
      },
    },
  },
}

M.setup_servers = function(capabilities, on_attach)
  -- nvim version <0.10
  local lspconfig = require("lspconfig")
  for server_name, config in pairs(M.servers) do
    lspconfig[server_name].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = config.settings,
      filetypes = config.filetypes,
      root_dir = config.root_dir,
      single_file_support = config.single_file_support,
      init_options = config.init_options,
      before_init = config.before_init,
      flags = { debounce_text_changes = 50 },
    })
  end

  -- nvim version 0.11
  vim.lsp.enable({
    "vtsls",
    "vue_ls",
    "lua_ls",
    "intelephense",
    "nginx_language_server",
    "cmake",
    "clangd",
    "jsonls",
    "yamlls",
  })
  vim.lsp.enable(M.servers)

  local lsp_pkg = require("utils.packages").lsp
  vim.lsp.enable(lsp_pkg)

end

return M
