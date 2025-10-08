local capabilities = require("configs.lsp.capabilities")
local on_attach = require("configs.lsp.on_attach")

return {
  cmd = { "nginx-language-server" },
  filetypes = { "nginx" },
  root_markers = { "nginx.conf", ".git" },
  capabilities = capabilities,
  on_attach = on_attach,
}
