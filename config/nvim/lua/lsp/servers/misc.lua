local M = {}

M.jsonls = {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  init_options = { provideFormatter = true },
  settings = {
    json = {
      schemas = (function()
        local ok, ss = pcall(require, "schemastore")
        return ok and ss.json.schemas() or {}
      end)(),
      validate = { enable = true },
    },
  },
}

M.taplo = {
  cmd = { "taplo", "lsp", "stdio" },
  filetypes = { "toml" },
  root_markers = { ".git", "Cargo.toml", "pyproject.toml" },
  settings = {
    evenBetterToml = {
      schema = { enabled = true },
      formatter = { alignEntries = false },
    },
  },
}

M.yamlls = {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yml" },
  root_markers = { ".git" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemas = (function()
        local ok, ss = pcall(require, "schemastore")
        return ok and ss.yaml.schemas() or {}
      end)(),
      schemaStore = { enable = false, url = "" },
      validate = true,
      keyOrdering = false,
      format = { enable = true },
    },
  },
}

return M
