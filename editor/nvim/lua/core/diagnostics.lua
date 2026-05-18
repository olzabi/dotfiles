local original_sign_handler = vim.diagnostic.handlers.signs
vim.diagnostic.handlers.signs = {
  show = function(ns, bufnr, diagnostics, opts)
    if diagnostics then
      local new_diagnostics = {}
      for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.message:match "Unexpected statement, found '<<'" then
          if diagnostic.severity == vim.diagnostic.severity.ERROR then
            diagnostic.message = "Git conflict detected."
            table.insert(new_diagnostics, diagnostic)
          end
          -- WARN variant is silently dropped
        else
          table.insert(new_diagnostics, diagnostic)
        end
      end
      diagnostics = new_diagnostics
    end
    original_sign_handler.show(ns, bufnr, diagnostics, opts)
  end,
  hide = original_sign_handler.hide,
}

local symbols = {
  [vim.diagnostic.severity.ERROR] = "✘",
  [vim.diagnostic.severity.WARN] = " ",
  [vim.diagnostic.severity.INFO] = "",
  [vim.diagnostic.severity.HINT] = "",
}

local float = {
  source = "if_many",
  header = "",
  border = "rounded",
  style = "minimal",
  prefix = "",
  format = function(d)
    local msg = d.message
    local sym = symbols[d.severity] or ""
    return string.format("%s\n%s", sym, msg)
  end,
}

vim.diagnostic.config {
  title = false,
  underline = true,
  update_in_insert = false,
  virtual_text = true,
  severity_sort = true,
  float = float,
  signs = { text = symbols },
}

local map = vim.keymap.set
map("n", "[e", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]e", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
