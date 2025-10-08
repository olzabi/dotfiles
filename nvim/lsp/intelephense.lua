-- local status_ok, _ = pcall(require, "lspconfig")
-- if not status_ok then
-- 	return
-- end

local on_attach = require("configs.lsp.on_attach")
-- local capabilities = require("lsp.capabilities")

return {
  on_attach = on_attach,

  capabilities = {
    textDocument = {
      codeLens = {
        dynamicRegistration = true,
      },
      formatting = {
        dynamicRegistration = false,
      },
      documentFormatting = {
        dynamicRegistration = false,
      },
      documentRangeFormatting = {
        dynamicRegistration = false,
      },
      documentOnTypeFormatting = {
        dynamicRegistration = false,
      },
      codeAction = {
        dynamicRegistration = false,
        codeActionLiteralSupport = {
          codeActionKind = {
            valueSet = {
              "",
              "quickfix",
              "refactor",
              "refactor.extract",
              "refactor.inline",
              "refactor.rewrite",
              "source",
              "source.organizeImports",
            },
          },
        },
        dataSupport = true,
        resolveSupport = {
          properties = { "edit" },
        },
      },
      completion = {
        dynamicRegistration = false,
        contextSupport = true,
        completionItem = {
          snippetSupport = true,
          commitCharactersSupport = true,
          documentationFormat = { "markdown", "plaintext" },
          deprecatedSupport = true,
          preselectSupport = true,
          insertReplaceSupport = true,
          labelDetailsSupport = true,
          resolveSupport = {
            properties = { "documentation", "detail", "additionalTextEdits" },
          },
        },
        completionItemKind = {
          valueSet = (function()
            local result = {}
            for i = 1, 25 do
              table.insert(result, i)
            end
            return result
          end)(),
        },
      },
      hover = {
        dynamicRegistration = false,
        contentFormat = { "markdown", "plaintext" },
      },
      declaration = {
        dynamicRegistration = false,
        linkSupport = true,
      },
      definition = {
        dynamicRegistration = false,
        linkSupport = true,
      },
      typeDefinition = {
        dynamicRegistration = false,
        linkSupport = true,
      },
      implementation = {
        dynamicRegistration = false,
        linkSupport = true,
      },
      references = {
        dynamicRegistration = false,
      },
      documentSymbol = {
        dynamicRegistration = false,
        symbolKind = {
          valueSet = (function()
            local result = {}
            for i = 1, 26 do
              table.insert(result, i)
            end
            return result
          end)(),
        },
        hierarchicalDocumentSymbolSupport = true,
      },
      documentHighlight = {
        dynamicRegistration = false,
      },
      signatureHelp = {
        dynamicRegistration = false,
        signatureInformation = {
          documentationFormat = { "markdown", "plaintext" },
          parameterInformation = {
            labelOffsetSupport = true,
          },
          activeParameterSupport = true,
        },
      },
      rename = {
        dynamicRegistration = false,
        prepareSupport = true,
      },
      publishDiagnostics = {
        dynamicRegistration = false,
        relatedInformation = true,
        tagSupport = {
          valueSet = { 1, 2 },
        },
        versionSupport = true,
        codeDescriptionSupport = true,
        dataSupport = true,
      },
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
      callHierarchy = {
        dynamicRegistration = false,
      },
      semanticTokens = {
        dynamicRegistration = false,
        requests = {
          range = true,
          full = {
            delta = true,
          },
        },
        tokenTypes = {
          "namespace",
          "type",
          "class",
          "enum",
          "interface",
          "struct",
          "typeParameter",
          "parameter",
          "variable",
          "property",
          "enumMember",
          "event",
          "function",
          "method",
          "macro",
          "keyword",
          "modifier",
          "comment",
          "string",
          "number",
          "regexp",
          "operator",
          "decorator",
        },
        tokenModifiers = {
          "declaration",
          "definition",
          "readonly",
          "static",
          "deprecated",
          "abstract",
          "async",
          "modification",
          "documentation",
          "defaultLibrary",
        },
        formats = { "relative" },
        overlappingTokenSupport = true,
      },
      inlayHint = {
        dynamicRegistration = false,
        resolveSupport = {
          properties = { "tooltip", "textEdits", "label.tooltip", "label.location" },
        },
      },
    },
    window = {
      showMessage = {
        messageActionItem = {
          additionalPropertiesSupport = true,
        },
      },
      workDoneProgress = true,
      showDocument = {
        support = true,
      },
    },
    workspace = {
      applyEdit = true,
      workspaceEdit = {
        documentChanges = true,
        resourceOperations = { "create", "rename", "delete" },
      },
      didChangeConfiguration = {
        dynamicRegistration = false,
      },
      didChangeWatchedFiles = {
        dynamicRegistration = false,
        relativePatternSupport = true,
      },
      symbol = {
        dynamicRegistration = false,
        symbolKind = {
          valueSet = (function()
            local result = {}
            for i = 1, 26 do
              table.insert(result, i)
            end
            return result
          end)(),
        },
      },
      executeCommand = {
        dynamicRegistration = false,
      },
      workspaceFolders = true,
      configuration = true,
      semanticTokens = {
        refreshSupport = true,
      },
      inlayHint = {
        refreshSupport = true,
      },
      codeLens = {
        refreshSupport = true,
      },
    },
    general = {
      positionEncodings = { "utf-16", "utf-8" },
    },
  },

  cmd = { "intelephense", "--stdio" },
  filetypes = {
    "php",
    "blade",
    "php_only",
    "*.php",
    "*.phtml",
    "*.module",
    "*.inc",
  },
  root_markers = { ".git", "composer.json" },
  -- root_dir = function ()
  --   return vim.loop.cwd()
  -- end,
  settings = {
    environment = {
      includePaths = {
        "**/vendor/**",
        "**/stubs/**",
        "app",
        "database",
      },
    },
    intelephense = {
      files = {
        maxSize = 10000000, -- 500 KB max, skips composer.phar
        associations = { "*.php" },
        exclude = {
          -- "**/vendor/**",
          "**/.git/**",
          "**/node_modules/**",
          "**/*.phar",
          -- "**/resources/views/**",
        },
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
        "bz2",
        "calendar",
        "com_dotnet",
        "Core",
        "ctype",
        "curl",
        "date",
        "dba",
        "dom",
        "enchant",
        "exif",
        "FFI",
        "fileinfo",
        "filter",
        "fpm",
        "ftp",
        "gd",
        "gettext",
        "gmp",
        "hash",
        "iconv",
        "imap",
        "intl",
        "json",
        "ldap",
        "libxml",
        "mbstring",
        "meta",
        "mysqli",
        "oci8",
        "odbc",
        "openssl",
        "pcntl",
        "pcre",
        "PDO",
        "pdo_ibm",
        "pdo_mysql",
        "pdo_pgsql",
        "pdo_sqlite",
        "pgsql",
        "Phar",
        "posix",
        "pspell",
        "readline",
        "Reflection",
        "session",
        "shmop",
        "SimpleXML",
        "snmp",
        "soap",
        "sockets",
        "sodium",
        "SPL",
        "sqlite3",
        "standard",
        "superglobals",
        "sysvmsg",
        "sysvsem",
        "sysvshm",
        "tidy",
        "tokenizer",
        "xml",
        "xmlreader",
        "xmlrpc",
        "xmlwriter",
        "xsl",
        "Zend OPcache",
        "zip",
        "zlib",
        "Illuminate",
        "Laravel",
      },
    },
  },
  init_options = {
    storagePath = vim.fn.stdpath("cache") .. "/intelephense",
  },
}
