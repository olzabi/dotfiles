return {
  cmd = { "vscode-json-language-server", "--stdio" },
  root_markers = { ".marksman.toml", ".git" },
  schemastore = { enable = true },
  init_options = {
    provideFormatter = true,
  },
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
  filetypes = { "json", "jsonc" },
}
