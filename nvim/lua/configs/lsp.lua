local M = {}

M.capabilities = function()
  local client_capabilities = vim.lsp.protocol.make_client_capabilities()

  client_capabilities.textDocument.completion.completionItem.snippetSupport = true
  client_capabilities.textDocument.semanticTokens.multilineTokenSupport = true

  client_capabilities.textDocument.foldingRange = {
    dynamicRegistration = true,
    lineFoldingOnly = true,
  }

  client_capabilities.textDocument.completion.completionItem = {
    snippetSupport = true,
    preselectSupport = true,
    deprecatedSupport = true,
    commitCharactersSupport = true,
    resolveSupport = {
      properties = {
        "documentation",
        "detail",
        "additionalTextEdits",
      },
    },
  }

  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  local cmp_capabilities = ok and cmp_nvim_lsp.default_capabilities() or {}

  local capabilities = vim.tbl_deep_extend("force", client_capabilities, cmp_capabilities)

  return capabilities
end

M.on_attach = function(client, bufnr) -- client, buffer
  -- Enable completion triggered by <c-x><c-o>
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

  local ok, wd = pcall(require, "workspace-diagnostics")
  if ok then
    wd.populate_workspace_diagnostics(client, bufnr)
  end

  if client.supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  if client.supports_method("textDocument/definition") then
    vim.keymap.set("n", "<C-]>", vim.lsp.buf.definition, { buffer = bufnr })
  end

  if client.supports_method("textDocument/implementation") then
    vim.keymap.set("n", "<space>&", vim.lsp.buf.implementation, { buffer = bufnr })
  end

  if client.supports_method("textDocument/hover") then
    vim.keymap.set("n", "<CR>", function()
      vim.lsp.buf.hover({ border = vim.g.floating_window_border_dark })
    end, { buffer = bufnr })
  end

  if client.supports_method("textDocument/definition") then
    vim.keymap.set("n", "<Space>*", function()
      require("lists").change_active("Quickfix")
      vim.lsp.buf.references()
    end, { buffer = bufnr })
  end

  if client.supports_method("textDocument/signatureHelp") then
    vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
  end

  -- if client.supports_method("textDocument/rename") then
  --   vim.keymap.set("n", "<Space>rn", vim.lsp.buf.rename, { buffer = bufnr })
  -- end
end

M.diagnostic = function()
  local signs = require("utils.icons").diagnostic
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
  end

  local original_sign_handler = vim.diagnostic.handlers.signs
  vim.diagnostic.handlers.signs = {
    show = function(ns, bufnr, diagnostics, opts)
      if diagnostics then
        local new_diagnostics = {}
        for _, diagnostic in ipairs(diagnostics) do
          if
            diagnostic.message:match("Unexpected statement, found '<<'")
            and diagnostic.severity == vim.diagnostic.severity.WARN
          then
          -- Remove these warnings...
          elseif
            diagnostic.message:match("Unexpected statement, found '<<'")
            and diagnostic.severity == vim.diagnostic.severity.ERROR
          then
            diagnostic.message = "Git conflict detected."
            table.insert(new_diagnostics, diagnostic)
          else
            table.insert(new_diagnostics, diagnostic)
          end
        end
        diagnostics = new_diagnostics
      end
      original_sign_handler.show(ns, bufnr, diagnostics, opts)
    end,
    hide = original_sign_handler.hide,
  }

  -- Global diagnostic settings
  vim.diagnostic.config({
    title = false,
    underline = true,
    update_in_insert = true,
    virtual_text = true,
    severity_sort = true,
    virtual_lines = {
      current_line = true,
    },
    sigs = true,
    float = {
      source = "always",
      focusable = false,
      border = "rounded",
      style = "minimal",
      header = "",
      suffix = "",
      prefix = "",
      format = function(diagnostic)
        local severity_symbols = {
          [vim.diagnostic.severity.ERROR] = "✘",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.INFO] = "",
          [vim.diagnostic.severity.HINT] = "",
        }
        local msg = diagnostic.message
        local sym = severity_symbols[diagnostic.severity] or ""
        return string.format("%s\n%s", sym, msg)
      end,
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✘",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.INFO] = "",
        [vim.diagnostic.severity.HINT] = "",
      },
      numhl = {
        [vim.diagnostic.severity.ERROR] = "ErrorMsg",
        [vim.diagnostic.severity.WARN] = "WarningMsg",
      },
    },
  })
end

M.setup = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
      local buf = event.buf
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client then
        return
      end

      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = args.buf,
        callback = function()
          -- if client:supports_method("textDocument/formatting") then
          --   vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
          -- end

          if client:supports_method("textDocument/codeAction") then
            local function apply_code_action(action_type)
              local ctx = { only = action_type, diagnostics = {} }
              local actions = vim.lsp.buf.code_action({ context = ctx, apply = true, return_actions = true })

              -- only apply if code action is available
              if actions and #actions > 0 then
                vim.lsp.buf.code_action({ context = ctx, apply = true })
              end
            end
            apply_code_action({ "source.fixAll" })
            apply_code_action({ "source.organizeImports" })
          end
        end,
      })

      ---@diagnostic disable-next-line need-check-nil
      if client.server_capabilities.completionProvider then
        vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
        -- vim.bo[bufnr].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
      end
      ---@diagnostic disable-next-line need-check-nil
      if client.server_capabilities.definitionProvider then
        vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc"
      end

      local bufopts = { noremap = true, silent = true, buffer = event.buf }
      vim.keymap.set("n", "<Leader>gi", "<cmd>Telescope lsp_implementations<CR>", bufopts)
      vim.keymap.set("n", "<Leader>gd", "<cmd>Telescope lsp_definitions<CR>", bufopts)
      vim.keymap.set("n", "<Leader>gr", "<cmd>Telescope lsp_references<CR>", bufopts)
      vim.keymap.set("n", "<Leader>es", "<cmd>Telescope diagnostics bufnr=0<CR>", bufopts)
      vim.keymap.set("n", "<Leader>gD", buf.declaration, bufopts)
      -- vim.keymap.set("n", "<leader>rn", buf.rename, bufopts)
      vim.keymap.set("n", "<leader>rs", "<cmd>LspRestart<CR>", bufopts)
      -- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
      -- vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
      vim.keymap.set("n", "<Leader>ee", function()
        vim.diagnostic.open_float(nil, { scope = "line" })
      end, bufopts)
    end,
  })

  vim.lsp.config("*", {
    capabilities = M.capabilities,
    on_attach = M.on_attach,
  })

  -- nvim version 0.11
  vim.lsp.enable({
    "angular",
    "ansible",
    "bash",
    "cmake",
    "clangd",
    "css",
    "docker",
    "docker_compose_ls",
    "eslint",
    "emmet_ls",
    "gopls",
    "graphql",
    "html",
    "intelephense",
    "json",
    "lua_ls",
    "nginx_language_server",
    "pyright",
    "rust_analyzer",
    "svelte",
    "sqls",
    "terraformls",
    "toml",
    "vtsls",
    "vue_ls",
    "yaml",
  })

  local lsp_pkg = require("utils.packages").lsp
  vim.lsp.enable(lsp_pkg)
end

M.mason = function()
  local mason = require("mason")
  local server_list = require("utils.packages").lsp_packages

  mason.setup({
    registries = {
      "github:crashdummyy/mason-registry",
      "github:mason-org/mason-registry",
    },
  })

  local registry = require("mason-registry")
  for _, server_name in ipairs(server_list) do
    local ok, pkg = pcall(registry.get_package, server_name)
    if ok and not pkg:is_installed() then
      pkg:install()
    end
  end
end

return M
