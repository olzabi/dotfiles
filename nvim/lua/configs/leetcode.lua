local M = {}

M.dependencies = {
  "nvim-lua/plenary.nvim",
  "MunifTanjim/nui.nvim",
  "nvim-tree/nvim-web-devicons",
}

M.opts = {
  lang = "typescript",

  injector = {
    ["golang"] = {
      before = "package main",
    },
    ["cpp"] = {
      before = { "#include <bits/stdc++.h>", "using namespace std;" },
      after = "int main() {}",
    },
  },
}

return M
