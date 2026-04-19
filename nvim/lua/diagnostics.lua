local orig = vim.diagnostic.handlers.signs
vim.diagnostic.handlers.signs = {
  show = function(ns, bufnr, diagnostics, opts)
    local filtered = {}
    for _, d in ipairs(diagnostics or {}) do
      if d.message:match "Unexpected statement, found '<<'" then
        if d.severity ~= vim.diagnostic.severity.WARN then
          d = vim.deepcopy(d)
          d.message = "Git conflict detected."
          table.insert(filtered, d)
        end
        -- WARN variant is silently dropped
      else
        table.insert(filtered, d)
      end
    end
    orig.show(ns, bufnr, filtered, opts)
  end,
  hide = orig.hide,
}

local symbols = {
  [vim.diagnostic.severity.ERROR] = "✘",
  [vim.diagnostic.severity.WARN] = " ",
  [vim.diagnostic.severity.INFO] = "",
  [vim.diagnostic.severity.HINT] = "",
}

vim.diagnostic.config {
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  virtual_text = false,
  virtual_lines = { current_line = true },
  signs = {
    text = symbols,
    priority = 5,
  },
  float = {
    border = "rounded",
    style = "minimal",
    source = true,
    header = "",
    prefix = "",
    format = function(d)
      local sym = symbols[d.severity] or ""
      return sym .. " " .. d.message
    end,
  },
}
