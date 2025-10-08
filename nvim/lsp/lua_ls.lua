local on_attach = require("configs.lsp.on_attach")
local capabilities = require("configs.lsp.capabilities")

local lua_runtime_path = vim.split(package.path, ";")
table.insert(lua_runtime_path, "lua/?.lua")
table.insert(lua_runtime_path, "lua/?/init.lua")

return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
  },

  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath("config")
        and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
      then
        return
      end
    end
  end,

  settings = {
    Lua = {
      telemetry = { enable = false },
      hint = { enable = true },
      runtime = { version = "LuaJIT", path = lua_runtime_path },
      diagnostics = {
        globals = { "bit", "vim", "vim.g", "it", "describe", "before_each", "after_each" },
        disable = { "missing-fields" },
      },
      workspace = {
        checkThirdParty = true,
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
          vim.fn.stdpath("config") .. "/lua",
          vim.env.VIMRUNTIME,
        },
      },
    },
  },

  on_attach = on_attach,
  capabilities = capabilities,
}
