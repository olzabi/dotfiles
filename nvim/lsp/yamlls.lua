local schemastore = require("schemastore")

return {
  schemastore = { enable = true },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemas = schemastore.yaml.schemas(),
      schemaStore = { enable = false, url = "" },
    },
  },
  filetypes = { "yaml", "yml" },
}
