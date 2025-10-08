local schemastore = require("schemastore")

return {
  schemastore = { enable = true },
  settings = {
    json = {
      schemas = schemastore.json.schemas(),
      validate = { enable = true },
    },
  },
  filetypes = { "json", "jsonc" },
}
