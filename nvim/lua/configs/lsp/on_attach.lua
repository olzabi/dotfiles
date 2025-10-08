return function(client, bufnr) -- client, buffer
  -- Enable completion triggered by <c-x><c-o>
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

  local workspace_diagnostics = require("workspace-diagnostics")
  workspace_diagnostics.populate_workspace_diagnostics(client, bufnr)

  if client.supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  -- if client.supports_method "textDocument/documentSymbol" and client.name ~= "bashls" then
  -- require("nvim-navic").attach(client, bufnr)
  -- end

  if client.supports_method("textDocument/definition") then
    vim.keymap.set("n", "<C-]>", vim.lsp.buf.definition, { buffer = bufnr })
    -- vim.keymap.set("n", "<C-[>", vim.lsp.buf.type_definition, { buffer = bufnr })
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

  if client.supports_method("textDocument/rename") then
    vim.keymap.set("n", "<Space>rn", vim.lsp.buf.rename, { buffer = bufnr })
  end

  -- require("lsp_signature").on_attach({
  --   bind = true,
  --   hint_enable = false,
  --   hint_prefix = {
  --     above = "↙ ", -- when the hint is on the line above the current line
  --     current = "← ", -- when the hint is on the same line
  --     below = "↖ ", -- when the hint is on the line below the current line
  --   },
  --   hint_scheme = "NonText",
  --   handler_opts = { border = "rounded" },
  --   floating_window = true,
  --   doc_lines = 50,
  --   wrap = true,
  --   fix_pos = true,
  --   -- always_trigger = true,
  --   toggle_key = "<C-x>",
  -- }, bufnr)

  -- if client.server_capabilities.documentHighlightProvider then
  --   vim.api.nvim_create_autocmd("CursorHold", {
  --     buffer = bufnr,
  --     callback = function()
  --       local opts = {
  --         focusable = false,
  --         close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
  --         border = "none",
  --         source = "always",
  --         prefix = " ",
  --         scope = "cursor",
  --         header = "",
  --       }
  --       vim.diagnostic.open_float(nil, opts)
  --     end,
  --   })
  --   vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  --     buffer = bufnr,
  --     callback = vim.lsp.buf.document_highlight,
  --   })
  --   vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  --     buffer = bufnr,
  --     callback = vim.lsp.buf.clear_references,
  --   })
  -- end

  -- if client.server_capabilities.documentSymbolProvider then
  --   local navic = require("nvim-navic")
  --   navic.attach(client, bufnr)
  -- end
end
