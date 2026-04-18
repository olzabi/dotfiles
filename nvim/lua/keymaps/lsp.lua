local M = {}

M.attach = function(buf)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = buf, desc = desc })
  end

  map("n", "<C-]>", vim.lsp.buf.definition, "LSP definition")
  map("n", "<Space>*", function()
    require("lists").change_active("Quickfix")
    vim.lsp.buf.references()
  end, "LSP references (quickfix)")
  map("n", "<Leader>gD", vim.lsp.buf.declaration, "LSP declaration")
  map("n", "<Leader>gd", "<cmd>Telescope lsp_definitions<CR>", "LSP definitions (Telescope)")
  map("n", "<Leader>gi", "<cmd>Telescope lsp_implementations<CR>", "LSP implementations (Telescope)")
  map("n", "<Leader>gr", "<cmd>Telescope lsp_references<CR>", "LSP references (Telescope)")
  map("n", "<Leader>es", "<cmd>Telescope diagnostics bufnr=0<CR>", "Buffer diagnostics (Telescope)")
  map("n", "<Leader>rs", "<cmd>LspRestart<CR>", "LSP restart")
end

return M
