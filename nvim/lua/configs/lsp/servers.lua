local M = {}

M.servers = {
  angularls = {},
  eslint = { settings = { packageManager = "npm" } },
  emmet_ls = { filetypes = { "css", "sass", "scss" } },
  svelte = {},

  taplo = {}, -- toml
  sqlls = {},

  rust_analyzer = { filetypes = { "rust" } },
  pyright = {
    filetypes = "python",
    settings = { python = { pythonPath = require("utils").get_python_path() } },
  },
  prismals = {},
  graphql = {},
  docker_compose_language_service = {},
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
    "json",
    "yaml",
    "go",
    "html",
    "terraform",
    "ansible",
    "css",
    "bash",
    "svelte",
  })
  vim.lsp.enable(M.servers)

  local lsp_pkg = require("utils.packages").lsp
  vim.lsp.enable(lsp_pkg)
end

return M
