return function(client, bufnr) -- client, buffer
  -- Enable completion triggered by <c-x><c-o>
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

  local workspace_diagnostics = require("workspace-diagnostics")
  workspace_diagnostics.populate_workspace_diagnostics(client, bufnr)

  if client.supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  if client.supports_method("textDocument/definition") then
    vim.keymap.set("n", "<C-]>", vim.lsp.buf.definition, { buffer = bufnr })
  end

  if client.supports_method("textDocument/implementation") then
    vim.keymap.set("n", "<space>&", vim.lsp.buf.implementation, { buffer = bufnr })
  end

  if client.supports_method("textDocument/hover") then
    vim.keymap.set("n", "<CR>", function()
      vim.lsp.buf.hover({ border = vim.g.floating_window_border_dark })
    end, { buffer = bufnr })
  end

  if client.supports_method("textDocument/definition") then
    vim.keymap.set("n", "<Space>*", function()
      require("lists").change_active("Quickfix")
      vim.lsp.buf.references()
    end, { buffer = bufnr })
  end

  if client.supports_method("textDocument/signatureHelp") then
    vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
  end

  -- if client.supports_method("textDocument/rename") then
  --   vim.keymap.set("n", "<Space>rn", vim.lsp.buf.rename, { buffer = bufnr })
  -- end
end
