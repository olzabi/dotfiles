local M = {}

local capabilities = function()
  local ok, blink = pcall(require, "blink.cmp")
  local base = ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()
  return vim.tbl_deep_extend("force", base, {
    textDocument = {
      semanticTokens = { multilineTokenSupport = true },
      foldingRange = { dynamicRegistration = true, lineFoldingOnly = true },
    },
    workspace = {
      didChangeWorkspaceFolders = { dynamicRegistration = false },
      didChangeConfiguration = { dynamicRegistration = false },
    },
  })
end

local on_attach = function(client, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local wd_ok, wd = pcall(require, "workspace-diagnostics")
  if wd_ok then
    wd.populate_workspace_diagnostics(client, bufnr)
  end

  if client:supports_method "textDocument/inlayHint" then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  if client:supports_method "textDocument/codeLens" then
    vim.lsp.codelens.refresh()
    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
      buffer = bufnr,
      callback = vim.lsp.codelens.refresh,
    })
  end

  if client:supports_method "textDocument/documentHighlight" then
    local group = vim.api.nvim_create_augroup("lsp_highlight_" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = bufnr,
      group = group,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      buffer = bufnr,
      group = group,
      callback = vim.lsp.buf.clear_references,
    })
  end
end

M.ansiblels = {
  cmd = { "ansible-language-server", "--stdio" },
  filetypes = { "yaml.ansible" },
  root_markers = { "ansible.cfg", ".ansible-lint" },
  settings = {
    ansible = {
      ansible = { path = "ansible" },
      executionEnvironment = { enabled = false },
      python = { interpreterPath = "python" },
      validation = {
        enabled = true,
        lint = { enabled = true, path = "ansible-lint" },
      },
    },
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

M.bashls = {
  cmd = { "bash-language-server", "start" },
  filetypes = { "bash", "sh", "zsh" },
  root_markers = { ".git" },
  single_file_support = true,
  settings = {
    bashIde = { globPattern = "*@(.sh|.inc|.bash|.command)" },
  },
}

M.clangd = {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  root_markers = {
    ".clangd",
    ".clang-tidy",
    ".clang-format",
    "compile_commands.json",
    "compile_flags.txt",
    ".git",
  },
  capabilities = vim.tbl_deep_extend("force", capabilities(), {
    -- clangd supports UTF-8 offset encoding which is more efficient
    offsetEncoding = { "utf-8", "utf-16" },
    textDocument = {
      completion = { editsNearCursor = true },
    },
  }),
  on_init = function(client, init_result)
    -- Respect the encoding clangd negotiated
    if init_result.offsetEncoding then
      client.offset_encoding = init_result.offsetEncoding
    end
  end,
  on_attach = function(client, bufnr)
    -- Switch between .h/.cpp
    vim.api.nvim_buf_create_user_command(bufnr, "ClangdSwitchSourceHeader", function()
      client:request(
        "textDocument/switchSourceHeader",
        vim.lsp.util.make_text_document_params(bufnr),
        function(err, result)
          if err then
            vim.notify(err.message, vim.log.levels.ERROR)
          elseif result then
            vim.cmd.edit(vim.uri_to_fname(result))
          else
            vim.notify("Corresponding file could not be determined", vim.log.levels.WARN)
          end
        end
      )
    end, { desc = "clangd: Switch Between Source and Header" })

    vim.keymap.set("n", "grs", "<Cmd>ClangdSwitchSourceHeader<CR>", {
      buffer = bufnr,
      desc = "clangd: Switch Between Source and Header",
    })

    vim.api.nvim_create_autocmd("LspDetach", {
      buffer = bufnr,
      group = vim.api.nvim_create_augroup("clangd_detach_" .. bufnr, { clear = true }),
      callback = function(args)
        if args.data.client_id == client.id then
          pcall(vim.keymap.del, "n", "grs", { buffer = bufnr })
          pcall(vim.api.nvim_buf_del_user_command, bufnr, "ClangdSwitchSourceHeader")
          return true
        end
      end,
    })

    on_attach(client, bufnr)
  end,
}

M.cmake = {
  cmd = { "cmake-language-server" },
  filetypes = { "cmake" },
  root_markers = { "CMakePresets.json", "CTestConfig.cmake", "CMakeLists.txt", ".git" },
  init_options = { buildDirectory = "build" },
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

M.css_variables = {
  cmd = { "css-variables-language-server", "--stdio" },
  filetypes = { "css", "scss", "less", "svelte" },
  root_markers = { "package.json", ".git" },
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

M.dockerls = {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile" },
}

M.docker_compose_language_service = {
  cmd = { "docker-compose-langserver", "--stdio" },
  filetypes = { "yaml.docker-compose" },
  root_markers = {
    "docker-compose.yaml",
    "docker-compose.yml",
    "compose.yaml",
    "compose.yml",
  },
}

M.emmet_ls = {
  cmd = { "emmet-ls", "--stdio" },
  filetypes = {
    "html",
    "css",
    "scss",
    "less",
    "sass",
    "javascriptreact",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
  },
  root_markers = { ".git", "package.json" },
}

M.eslint = {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
  },
  root_markers = {
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    "eslint.config.js",
    "eslint.config.mjs",
    "package.json",
  },
  settings = {
    format = true,
    run = "onType",
    validate = "on",
    workingDirectory = { mode = "location" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
}

M.gh_actions_ls = {
  cmd = { "gh-actions-language-server", "--stdio" },
  filetypes = { "yaml" },
  root_dir = function(bufnr, on_dir)
    local parent = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
    if vim.endswith(parent, "/.github/workflows") then
      on_dir(parent)
    end
  end,
  init_options = {},
}

M.gopls = {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.mod", "go.work", ".git" },
  single_file_support = true,
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      usePlaceholders = true,
      completeUnimported = true,
      semanticTokens = true,
      directoryFilters = { "-.git", "-.vscode", "-.idea", "-node_modules" },
      analyses = { unusedparams = true },
      codelenses = {
        generate = true,
        tidy = true,
        test = true,
        upgrade_dependency = true,
        vendor = true,
        run_govulncheck = true,
      },
      hints = {
        parameterNames = true,
        rangeVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypesParameters = true,
      },
    },
  },
}

M.graphql = {
  cmd = { "graphql-lsp", "server", "-m", "stream" },
  filetypes = { "graphql", "typescriptreact", "javascriptreact" },
  root_markers = { ".graphqlrc", ".graphqlrc.json", "graphql.config.js", ".git" },
}

M.html = {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = {
    "html",
    "htmlangular",
    "blade",
    "erb",
    "eruby",
    "gohtml",
    "handlebars",
    "svelte",
    "vue",
    "templ",
  },
  root_markers = { "package.json", ".git" },
  init_options = {
    provideFormatter = true,
    configurationSection = { "html", "css", "javascript" },
    embeddedLanguages = { css = true, javascript = true },
  },
}

M.intelephense = {
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php", "blade" },
  root_markers = { ".git", "composer.json" },
  init_options = {
    storagePath = vim.fn.stdpath "cache" .. "/intelephense",
    licenseKey = os.getenv "INTELEPHENSE_LICENSE_KEY",
  },
  settings = {
    intelephense = {
      diagnostics = { enable = false },
      files = {
        maxSize = 20 * 1024 * 1024,
        associations = { "*.php", "*.phtml" },
        exclude = { "**/vendor/**/vendor/**", "**/.git/**", "**/node_modules/**" },
      },
      completion = {
        insertUseDeclaration = true,
        fullyQualifyGlobalConstantsAndFunctions = false,
        triggerParameterHints = true,
        maxItems = 100,
      },
      stubs = {
        "apache",
        "bcmath",
        "Core",
        "curl",
        "date",
        "dom",
        "fileinfo",
        "filter",
        "gd",
        "hash",
        "iconv",
        "json",
        "mbstring",
        "mysqli",
        "openssl",
        "pcre",
        "PDO",
        "pdo_mysql",
        "pdo_pgsql",
        "pdo_sqlite",
        "pgsql",
        "Reflection",
        "session",
        "SimpleXML",
        "sodium",
        "SPL",
        "sqlite3",
        "standard",
        "superglobals",
        "tokenizer",
        "xml",
        "xmlreader",
        "xmlwriter",
        "Zend OPcache",
        "zip",
        "zlib",
        "Illuminate",
        "Laravel",
      },
    },
  },
}

M.jsonls = {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  init_options = { provideFormatter = true },
  settings = {
    json = {
      schemas = (function()
        local ok, ss = pcall(require, "schemastore")
        return ok and ss.json.schemas() or {}
      end)(),
      validate = { enable = true },
    },
  },
}

M.lua_ls = {
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
    -- Don't override settings if the project has its own .luarc
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath "config"
        and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
      then
        return
      end
    end
    -- Neovim config workspace: inject runtime paths
    client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = {
            vim.env.VIMRUNTIME,
            vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
            vim.fn.stdpath "config" .. "/lua",
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    })
    client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
  end,
  settings = {
    Lua = {
      telemetry = { enable = false },
      hint = { enable = true },
      diagnostics = {
        globals = { "vim", "bit", "it", "describe", "before_each", "after_each" },
        disable = { "missing-fields" },
      },
    },
  },
}

M.nginx_language_server = {
  cmd = { "nginx-language-server" },
  filetypes = { "nginx" },
  root_markers = { "nginx.conf", ".git" },
}

M.pyright = {
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
}

M.rust_analyzer = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "Cargo.lock", ".git" },
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },
      checkOnSave = { command = "clippy" },
      procMacro = { enable = true },
      inlayHints = {
        parameterHints = { enable = true },
        typeHints = { enable = true },
        chainingHints = { enable = true },
      },
    },
  },
}

M.sqls = {
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
}

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

M.terraformls = {
  cmd = { "terraform-ls", "serve" },
  filetypes = { "terraform", "tf", "terraform-vars" },
  root_markers = { ".terraform", ".terraform.lock.hcl", ".git" },
}

M.taplo = {
  cmd = { "taplo", "lsp", "stdio" },
  filetypes = { "toml" },
  root_markers = { ".git", "Cargo.toml", "pyproject.toml" },
  settings = {
    evenBetterToml = {
      schema = { enabled = true },
      formatter = { alignEntries = false },
    },
  },
}

local _vue_ts_sdk = vim.fn.stdpath "data" .. "/mason/packages/typescript-language-server/node_modules/typescript/lib"

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

local _vue_plugin_path = vim.fn.stdpath "data"
  .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

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

-- ── YAML ──────────────────────────────────────────────────────────────────────
M.yamlls = {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yml" },
  root_markers = { ".git" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemas = (function()
        local ok, ss = pcall(require, "schemastore")
        return ok and ss.yaml.schemas() or {}
      end)(),
      schemaStore = { enable = false, url = "" },
      validate = true,
      keyOrdering = false,
      format = { enable = true },
    },
  },
  -- yamlls benefits from autotrigger completion; also chain the global on_attach.
  on_attach = function(client, bufnr)
    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    on_attach(client, bufnr)
  end,
}


-- --------------------------------------------------------------------------------
vim.lsp.config("*", {
  capabilities = capabilities(),
  on_attach = on_attach,
})

for name, cfg in pairs(M) do
  vim.lsp.config(name, cfg)
end

vim.lsp.enable(vim.tbl_keys(M))

return M
