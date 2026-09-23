local map = vim.keymap.set
local sev = vim.diagnostic.severity

local palette = {
  err = "#51202A",
  warn = "#3B3B1B",
  info = "#1F3342",
  hint = "#1E2E1E",
}
vim.api.nvim_set_hl(0, "DiagnosticErrorLine", { bg = palette.err, blend = 20 })
vim.api.nvim_set_hl(0, "DiagnosticWarnLine", { bg = palette.warn, blend = 15 })
vim.api.nvim_set_hl(0, "DiagnosticInfoLine", { bg = palette.info, blend = 10 })
vim.api.nvim_set_hl(0, "DiagnosticHintLine", { bg = palette.hint, blend = 10 })

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
    return string.format("%s", d.message)
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
  linehl = {
    [sev.ERROR] = "DiagnosticErrorLine",
    [sev.WARN] = "DiagnosticWarnLine",
    [sev.INFO] = "DiagnosticInfoLine",
    [sev.HINT] = "DiagnosticHintLine",
  },
}

local diagnostic_goto = function(next, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump({ count = next and 1 or -1, float = true, severity = severity })
  end
end

map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
