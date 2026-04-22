require "keymaps.core"

local M = {}

local function merge_tables(dest, ...)
  for _, src in ipairs { ... } do
    for k, v in pairs(src) do
      dest[k] = v
    end
  end
  return dest
end

merge_tables(
  M,
  require "keymaps.plugins",
  require "keymaps.lsp"
)

return M
