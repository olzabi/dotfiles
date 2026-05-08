return {
  clangd = {
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
    on_init = function(client, init_result)
      if init_result.offsetEncoding then
        client.offset_encoding = init_result.offsetEncoding
      end
    end,
    on_attach = function(client, bufnr)
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
    end,
  },

  cmake = {
    cmd = { "cmake-language-server" },
    filetypes = { "cmake" },
    root_markers = { "CMakePresets.json", "CTestConfig.cmake", "CMakeLists.txt", ".git" },
    init_options = { buildDirectory = "build" },
  },

  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork" },
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
          assignVariableTypes = true,
          parameterNames = true,
          rangeVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypesParameters = true,
        },
      },
    },
  },

  rust_analyzer = {
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
  },
}
