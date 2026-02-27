return {
  cmd = { "yaml-language-server", "--stdio" },

  schemastore = { enable = true },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemas = require("schemastore").yaml.schemas(),
      schemaStore = { enable = false, url = "" },
      validate = true,
      keyOrdering = false,
      format = { enalbe = true },
    },
  },
  filetypes = { "yaml", "yml" },

  on_attach = function(client, bufnr)
    vim.lsp.completion.enable(true, client.id, bufnr, {
      autotrigger = true,
    })
  end,
}
