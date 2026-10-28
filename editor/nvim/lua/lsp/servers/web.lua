local M = {}

local _vue_plugin_path = vim.fn.stdpath "data" .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
local _vue_ts_sdk = vim.fn.stdpath "data" .. "/mason/packages/vue-language-server/node_modules/typescript/lib"

M.vtsls = {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  settings = {
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = _vue_plugin_path,
            languages = { "vue" },
            configNamespace = "typescript",
            enableForWorkspaceTypeScriptVersions = true,
          },
        },
      },
    },
    typescript = {
      preferences = {
        importModuleSpecifier = "shortest",
        updateImportsOnFileMove = { enabled = "always" },
      },
    },
  },
}

M.vue_ls = {
  cmd = { "vue-language-server", "--stdio" },
  filetypes = { "vue" },
  init_options = {
    typescript = { tsdk = _vue_ts_sdk },
  },
  settings = {
    vue = { hybridMode = false, format = { enable = true } },
  },
  on_init = function(client)
    client.handlers["tsserver/request"] = function(_, result, context)
      local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
      if #clients == 0 then
        vim.notify("Could not find `vtsls` lsp client, required by `vue_ls`.", vim.log.levels.ERROR)
        return
      end
      local ts_client = clients[1]

      local param = unpack(result)
      local id, command, payload = unpack(param)
      ts_client:exec_cmd({
        title = "vue_request_forward", -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
        command = "typescript.tsserverRequest",
        arguments = {
          command,
          payload,
        },
      }, { bufnr = context.bufnr }, function(_, r)
        local response_data = { { id, r and r.body } }
        ---@diagnostic disable-next-line: param-type-mismatch
        client:notify("tsserver/response", response_data)
      end)
    end
  end,
}

local ls_cache = {}
local function mise_ls_dir(root)
  if ls_cache[root] == nil then
    local r = vim.system({ "mise", "where", "npm:@angular/language-service" }, { cwd = root, text = true }):wait()
    local dir = r.code == 0 and (vim.trim(r.stdout) .. "/node_modules") or false
    ls_cache[root] = (dir and vim.uv.fs_stat(dir)) and dir or false
  end
  return ls_cache[root] or nil
end

M.angularls = {
  filetypes = { "typescript", "html", "htmlangular" },
  root_markers = { "angular.json" },
  workspace_required = true,
  cmd = function(dispatchers, config)
    local root = config.root_dir or vim.uv.cwd()
    local paths = {
      root .. "/node_modules",
      mise_ls_dir(root),
      vim.fn.stdpath "data" .. "/mason/packages/angular-language-server/node_modules",
    }
    local probe = table.concat(vim.tbl_filter(function(p) return p end, paths), ",")
    return vim.lsp.rpc.start(
      { "ngserver", "--stdio", "--tsProbeLocations", probe, "--ngProbeLocations", probe },
      dispatchers,
      { cwd = config.cmd_cwd, env = config.cmd_env }
    )
  end,
}
-- M.angularls = (function()
--   local function get_probe_dir()
--     local node_modules = vim.fs.find("node_modules", { path = vim.uv.cwd(), upward = true })[1]
--     return node_modules and vim.fs.dirname(node_modules) .. "/node_modules" or ""
--   end
--
--   local function get_angular_version()
--     local node_modules = vim.fs.find("node_modules", { path = vim.uv.cwd(), upward = true })[1]
--     if not node_modules then
--       return ""
--     end
--     local pkg_path = vim.fs.dirname(node_modules) .. "/package.json"
--     if not vim.uv.fs_stat(pkg_path) then
--       return ""
--     end
--     local f = io.open(pkg_path)
--     if not f then
--       return ""
--     end
--     local ok, json = pcall(vim.json.decode, f:read "*a")
--     f:close()
--     if not ok or not json.dependencies then
--       return ""
--     end
--     local v = json.dependencies["@angular/core"]
--     return v and (v:match "%d+%.%d+%.%d+" or "") or ""
--   end
--
--   local ngserver_exe = vim.fn.exepath "ngserver"
--   local ngserver_dir = #(ngserver_exe or "") > 0 and vim.fs.dirname(vim.uv.fs_realpath(ngserver_exe)) or ""
--   local extension_path = vim.fs.normalize(ngserver_dir .. "/../../../")
--
--   return {
--     cmd = function()
--       local probe = get_probe_dir()
--       local ts_probe = table.concat({ extension_path, probe }, ",")
--       local ng_probe = table.concat({
--         extension_path .. "/@angular/language-server/node_modules",
--         probe .. "/@angular/language-server/node_modules",
--       }, ",")
--       return {
--         "ngserver",
--         "--stdio",
--         "--tsProbeLocations",
--         ts_probe,
--         "--ngProbeLocations",
--         ng_probe,
--         "--angularCoreVersion",
--         get_angular_version(),
--       }
--     end,
--     filetypes = { "typescript", "html", "htmlangular" },
--     root_markers = { "angular.json", "nx.json" },
--   }
-- end)()

M.svelte = {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  root_markers = { "svelte.config.js", "svelte.config.ts" },
  settings = {
    svelte = {
      plugin = {
        html = { completions = { enable = true } },
        svelte = { defaultScriptLanguage = "ts" },
      },
    },
  },
}

M.html = {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html", "htmlangular", "eruby", "handlebars", "svelte", "vue" },
  init_options = {
    provideFormatter = true,
    configurationSection = { "html", "css", "javascript" },
    embeddedLanguages = { css = true, javascript = true },
  },
}

M.eslint = {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
  root_markers = { "eslint.config.js", "eslint.config.mjs", "eslint.config.ts", ".eslintrc", ".eslintrc.js", ".eslintrc.json", "package.json" },
  workspace_required = true,
  settings = {
    validate = "on",
    useESLintClass = false,
    experimental = { useFlatConfig = false },
    codeActionOnSave = { enable = false, mode = "all" },
    format = true,
    quiet = false,
    onIgnoredFiles = "off",
    rulesCustomizations = {},
    run = "onType",
    problems = { shortenToSingleLine = false },
    nodePath = "",
    workingDirectory = { mode = "auto" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
  before_init = function(_, config)
    config.settings.workspaceFolder = {
      uri = config.root_dir,
      name = vim.fn.fnamemodify(config.root_dir, ":t"),
    }
  end,
  handlers = {
    ["eslint/openDoc"] = function(_, result)
      if result then
        vim.ui.open(result.url)
      end
      return {}
    end,
    ["eslint/confirmESLintExecution"] = function(_, result)
      if result then
        return 4
      end
    end,
    ["eslint/probeFailed"] = function()
      vim.notify("ESLint probe failed", vim.log.levels.WARN)
      return {}
    end,
    ["eslint/noLibrary"] = function()
      vim.notify("ESLint library not found", vim.log.levels.WARN)
      return {}
    end,
  },
}

M.emmet_language_server = {
  cmd = { "emmet-language-server", "--stdio" },
  filetypes = { "html", "css", "scss", "less", "javascriptreact", "typescriptreact", "vue", "svelte", "htmlangular", "eruby", "php", "blade" },
}

M.css_variables = {
  cmd = { "css-variables-language-server", "--stdio" },
  filetypes = { "css", "scss", "less", "svelte" },
  settings = {
    cssVariables = {
      blacklistFolders = {
        "**/.cache",
        "**/.git",
        "**/.next",
        "**/dist",
        "**/node_modules",
        "**/tmp",
      },
      lookupFiles = { "**/*.less", "**/*.scss", "**/*.sass", "**/*.css" },
    },
  },
}

M.cssls = {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  root_markers = { "package.json", ".git" },
  init_options = { provideFormatter = true },
  settings = {
    css = { validate = true, lint = { unknownAtRules = "ignore" } },
    less = { validate = true, lint = { unknownAtRules = "ignore" } },
    scss = { validate = true, lint = { unknownAtRules = "ignore" } },
  },
}

M.graphql = {
  cmd = { "graphql-lsp", "server", "-m", "stream" },
  filetypes = { "graphql", "typescriptreact", "javascriptreact" },
  root_markers = { ".graphqlrc", ".graphqlrc.json", "graphql.config.js" },
}

return M
