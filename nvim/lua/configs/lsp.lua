local M = {}

local utils = require("utils.packages")

M.capabilities = function()
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

M.on_attach = function(client, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local wd_ok, wd = pcall(require, "workspace-diagnostics")
  if wd_ok then
    wd.populate_workspace_diagnostics(client, bufnr)
  end

  if client:supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
end

M.setup = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
      local buf = event.buf
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client then
        return
      end

      if client.server_capabilities.completionProvider then
        vim.bo[buf].omnifunc = "v:lua.vim.lsp.omnifunc"
      end
      if client.server_capabilities.definitionProvider then
        vim.bo[buf].tagfunc = "v:lua.vim.lsp.tagfunc"
      end

      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = buf,
        callback = function()
          if not client:supports_method("textDocument/codeAction") then
            return
          end

          local function sync_action(kind)
            local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
            params.context = { only = { kind }, diagnostics = vim.diagnostic.get(buf) }
            local result, err = client:request_sync("textDocument/codeAction", params, 3000, buf)
            if err or not result or not result.result then
              return
            end
            for _, action in ipairs(result.result) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
              elseif action.command then
                client:exec_cmd(action.command)
              end
            end
          end

          sync_action("source.organizeImports")
        end,
      })

      require("keymaps.lsp").attach(buf)
    end,
  })

  vim.lsp.config("*", {
    capabilities = M.capabilities(),
    on_attach = M.on_attach,
  })

  vim.lsp.enable(utils.lsp)
end

M.mason = function()
  require("mason").setup({
    registries = {
      "github:crashdummyy/mason-registry",
      "github:mason-org/mason-registry",
    },
  })

  local registry = require("mason-registry")
  registry.refresh(function(ok, err)
    if not ok then
      vim.notify("Mason registry refresh failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    for _, name in ipairs(utils.mason_tools) do
      local pkg_ok, pkg = pcall(registry.get_package, name)
      if not pkg_ok then
        vim.notify("Mason: unknown package '" .. name .. "'", vim.log.levels.WARN)
      elseif not pkg:is_installed() then
        pkg:install({}, function(success, result)
          vim.schedule(function()
            local msg = success and ("Mason: installed " .. name)
              or ("Mason: failed " .. name .. " — " .. tostring(result))
            vim.notify(msg, success and vim.log.levels.INFO or vim.log.levels.ERROR)
          end)
        end)
      end
    end
  end)
end

return M
