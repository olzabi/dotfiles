return {
  "b0o/SchemaStore.nvim",
  "artemave/workspace-diagnostics.nvim",

  {
    "folke/lazydev.nvim",
    cmd = "LazyDev",
    lazy = false,
    dependencies = { { "justinsgithub/wezterm-types", ft = { "wezterm" } } },
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim",        words = { "Snacks" } },
        { path = "lazy.nvim",          words = { "LazyVim" } },
        { path = "wezterm-types",      modes = { "wezterm" } },
        "neotest",
      },
    },
  },

  {
    --  TODO
    "rmagatti/goto-preview",
    event = { "BufEnter" },
    dependencies = "rmagatti/logger.nvim",
    opts = {
      default_mappings = true,
    },
  },

  {
    "LSP",
    virtual = true,
    config = function()
      local groups = {
        "scripting",
        "systems",
        "misc",
        "php",
        "infra",
        "typescript",
        "web",
      }
      local group = { "scripting", "systems", "misc", "php", "infra", "typescript", "web" }
      for _, group in ipairs(groups) do
        local servers = require("lsp.servers." .. group)
        for name, cfg in pairs(servers) do
          vim.lsp.config(name, cfg)
          vim.lsp.enable(name)
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_global_attach", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then
            return
          end

          vim.api.nvim_create_autocmd("LspDetach", {
            buffer = buf,
            once = true,
            callback = function()
              pcall(vim.api.nvim_del_augroup_by_name, "lsp_organize_" .. buf)
              pcall(vim.api.nvim_del_augroup_by_name, "lsp_format_" .. buf)
            end,
          })

          if client:supports_method "textDocument/codeAction" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = buf,
              group = vim.api.nvim_create_augroup("lsp_organize_" .. buf, { clear = true }),
              callback = function()
                local params = vim.lsp.util.make_range_params(vim.api.nvim_get_current_win(), client.offset_encoding)
                params.context = {
                  only = { "source.organizeImports" },
                  diagnostics = vim.diagnostic.get(buf),
                }
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
              end,
            })
          end

          if client:supports_method "textDocument/inlayHint" then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
          end

          local wd_ok, wd = pcall(require, "workspace-diagnostics")
          if wd_ok then
            wd.populate_workspace_diagnostics(client, buf)
          end

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, buffer = buf, desc = desc })
          end

          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
          map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
          map("n", "gt", vim.lsp.buf.type_definition, "Go to type definition")
          map("n", "gR", vim.lsp.buf.references, "References")
          map("n", "gO", vim.lsp.buf.document_symbol, "Document symbols")
          map("n", "K", vim.lsp.buf.hover, "Hover docs")
          map({ "n", "i" }, "<C-h>", vim.lsp.buf.signature_help, "Signature help")
          map({ "n", "v" }, "g..", vim.lsp.buf.code_action, "Code action")
          map("n", "<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbols")
        end,
      })
    end,
  },
}
