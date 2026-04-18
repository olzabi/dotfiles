require("keymaps.core")

local M = {}

local plugins = require("keymaps.plugins")
for k, v in pairs(plugins) do
  M[k] = v
end

local lsp = require("keymaps.lsp")
for k, v in pairs(lsp) do
  M[k] = v
end

return M
