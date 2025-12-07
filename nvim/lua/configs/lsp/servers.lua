local M = {}

M.servers = {
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
    "angular",
    "ansible",
    "bash",
    "cmake",
    "clangd",
    "css",
    "docker",
    "docker_compose_ls",
    "eslint",
    "emmet_ls",
    "gopls",
    "graphql",
    "html",
    "intelephense",
    "json",
    "lua_ls",
    "nginx_language_server",
    "pyright",
    "rust_analyzer",
    "svelte",
    "sqls",
    "terraformls",
    "toml",
    "vtsls",
    "vue_ls",
    "yaml",
  })
  -- vim.lsp.enable(M.servers)

  local lsp_pkg = require("utils.packages").lsp
  vim.lsp.enable(lsp_pkg)
end

return M
