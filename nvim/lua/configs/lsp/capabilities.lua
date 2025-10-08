local client_capabilities = vim.lsp.protocol.make_client_capabilities()
client_capabilities.textDocument.completion.completionItem.snippetSupport = true
client_capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

client_capabilities.textDocument.completion.completionItem = {
  snippetSupport = true,
  preselectSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
local cmp_capabilities = ok and cmp_nvim_lsp.default_capabilities() or {}

local capabilities = vim.tbl_deep_extend("force", client_capabilities, cmp_capabilities)

return capabilities
