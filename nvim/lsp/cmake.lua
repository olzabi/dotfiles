local capabilities = require("configs.lsp.capabilities")
local on_attach = require("configs.lsp.on_attach")

--- https://github.com/regen100/cmake-language-server
---
return {
  cmd = { "cmake-language-server" },
  filetypes = { "cmake" },
  root_markers = { "CMakePresets.json", "CTestConfig.cmake", ".git", "build", "cmake" },
  init_options = {
    buildDirectory = "build",
  },
  capabilities = capabilities,
  on_attach = on_attach,
} --[[@as vim.lsp.Config]]
