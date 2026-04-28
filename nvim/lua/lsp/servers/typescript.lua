local M = {}
local _vue_plugin_path = vim.fn.stdpath "data"
  .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
local _vue_ts_sdk = vim.fn.stdpath "data" .. "/mason/packages/typescript-language-server/node_modules/typescript/lib"

M.vtsls = {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "vue", "html" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  settings = {
    vtsls = {
      autoUseWorkspaceTsdk = true,
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = _vue_plugin_path,
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
    },
    typescript = {
      preferences = {
        importModuleSpecifier = "non-relative",
        updateImportsOnFileMove = { enabled = "always" },
      },
    },
  },
}

M.vue_ls = {
  cmd = { "vue-language-server", "--stdio" },
  filetypes = { "vue" },
  root_markers = { "package.json" },
  init_options = { typescript = { tsdk = _vue_ts_sdk } },
  on_init = function(client)
    client.handlers["tsserver/request"] = function(_, result, context)
      local ts_clients = vim.lsp.get_clients { bufnr = context.bufnr, name = "vtsls" }
      if #ts_clients == 0 then
        vim.notify("vue_ls: vtsls not found; template type-checking disabled.", vim.log.levels.WARN)
        return
      end
      local id, command, payload = table.unpack(table.unpack(result))
      ts_clients[1]:exec_cmd({
        title = "vue_request_forward",
        command = "typescript.tsserverRequest",
        arguments = { command, payload },
      }, { bufnr = context.bufnr }, function(_, r)
        client:notify("tsserver/response", { { id, r and r.body } })
      end)
    end
  end,
  settings = {
    vue = { hybridMode = false, format = { enable = true } },
  },
}

M.angularls = (function()
  local function get_probe_dir()
    local node_modules = vim.fs.find("node_modules", { path = vim.uv.cwd(), upward = true })[1]
    return node_modules and vim.fs.dirname(node_modules) .. "/node_modules" or ""
  end

  local function get_angular_version()
    local node_modules = vim.fs.find("node_modules", { path = vim.uv.cwd(), upward = true })[1]
    if not node_modules then
      return ""
    end
    local pkg_path = vim.fs.dirname(node_modules) .. "/package.json"
    if not vim.uv.fs_stat(pkg_path) then
      return ""
    end
    local f = io.open(pkg_path)
    if not f then
      return ""
    end
    local ok, json = pcall(vim.json.decode, f:read "*a")
    f:close()
    if not ok or not json.dependencies then
      return ""
    end
    local v = json.dependencies["@angular/core"]
    return v and (v:match "%d+%.%d+%.%d+" or "") or ""
  end

  local ngserver_exe = vim.fn.exepath "ngserver"
  local ngserver_dir = #(ngserver_exe or "") > 0 and vim.fs.dirname(vim.uv.fs_realpath(ngserver_exe)) or ""
  local extension_path = vim.fs.normalize(ngserver_dir .. "/../../../")

  return {
    cmd = function()
      local probe = get_probe_dir()
      local ts_probe = table.concat({ extension_path, probe }, ",")
      local ng_probe = table.concat({
        extension_path .. "/@angular/language-server/node_modules",
        probe .. "/@angular/language-server/node_modules",
      }, ",")
      return {
        "ngserver",
        "--stdio",
        "--tsProbeLocations",
        ts_probe,
        "--ngProbeLocations",
        ng_probe,
        "--angularCoreVersion",
        get_angular_version(),
      }
    end,
    filetypes = { "typescript", "html", "htmlangular" },
    root_markers = { "angular.json", "nx.json" },
  }
end)()

M.svelte = {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  root_markers = { "svelte.config.js", "svelte.config.ts", "package.json", ".git" },
  settings = {
    svelte = {
      plugin = {
        html = { completions = { enable = true } },
        svelte = { defaultScriptLanguage = "ts" },
      },
    },
  },
}

return M
