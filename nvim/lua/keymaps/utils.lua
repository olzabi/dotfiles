local M = {}

function M.nmap(keys, func, desc, buf)
  if desc then
    desc = desc
  end

  if buf then
    buf = buf
  end

  vim.keymap.set("n", keys, func, { noremap = true, silent = true, desc = desc, buffer = buf })
end

return M
