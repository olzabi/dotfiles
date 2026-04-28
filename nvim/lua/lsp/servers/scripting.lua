local nvim_config_settings = {
  Lua = {
    runtime = { version = "LuaJIT" },
    workspace = {
      checkThirdParty = false,
      library = {
        vim.env.VIMRUNTIME,
        vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
        vim.fn.stdpath "config" .. "/lua",
        -- luv / vim.uv types
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
}

local function is_nvim_config(client)
  if not client.workspace_folders then
    return false
  end
  local path = client.workspace_folders[1].name
  -- Has its own .luarc? Respect it, don't inject anything
  if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
    return false
  end
  return path == vim.fn.stdpath "config"
end

return {
  bashls = {
    cmd = { "bash-language-server", "start" },
    filetypes = { "bash", "sh", "zsh" },
    root_markers = { ".git" },
    single_file_support = true,
    settings = {
      bashIde = { globPattern = "*@(.sh|.inc|.bash|.command)" },
    },
  },
  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = {
      ".luarc.json",
      ".luarc.jsonc",
      ".luacheckrc",
      ".stylua.toml",
      "stylua.toml",
      ".git",
    },
    on_init = function(client)
      if not is_nvim_config(client) then
        return
      end
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings, nvim_config_settings)
      client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
    end,
    settings = {
      Lua = {
        telemetry = { enable = false },
        hint = { enable = true, arrayIndex = "Disable" },
        completion = { callSnippet = "Replace" }, -- prevents argument swapping in completions
        diagnostics = {
          globals = { "vim", "bit", "it", "describe", "before_each", "after_each" },
          disable = {
            "missing-fields",
            "trailing-space",
            "redefined-local",
            "need-check-nil",
            "inject-field",
            "deprecated",
            "redundant-parameter",
            "param-type-mismatch",
          },
        },
      },
    },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "openFilesOnly",
          typeCheckingMode = "basic",
        },
      },
    },
  },
  sqls = {
    cmd = { "sqls" },
    filetypes = { "sql", "mysql" },
    root_markers = { ".git" },
    -- settings = {
    --   sqls = {
    --     connections = {
    --       { driver = "postgresql", dataSourceName = "host=127.0.0.1 ..." },
    --     },
    --   },
    -- },
  },
}
