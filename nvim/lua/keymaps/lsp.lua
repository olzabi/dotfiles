local M = {}

M.attach = function(buf)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = buf, desc = desc })
  end

  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gri", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "grr", vim.lsp.buf.references, "References")
  map("n", "grt", vim.lsp.buf.type_definition, "Go to type definition")

  -- Info
  map("n", "K", vim.lsp.buf.hover, "Hover docs")
  map("n", "gK", vim.lsp.buf.signature_help, "Signature help")

  -- Actions
  map("n", "grn", vim.lsp.buf.rename, "[r]e[n]ame")
  map({ "n", "v" }, "gra", vim.lsp.buf.code_action, "Code action")

  -- Diagnostics
  map("n", "<leader>e", vim.diagnostic.open_float, "Line diagnostics")
  map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
  map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
  map("n", "]e", function() vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR } end, "Next error")
  map("n", "[e", function() vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR } end, "Prev error")

  -- Codelens
  map("n", "<leader>cl", vim.lsp.codelens.run, "Run codelens")
  map("n", "<leader>cL", vim.lsp.codelens.refresh, "Refresh codelens")
end

return M
