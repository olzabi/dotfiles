---@diagnostic disable: inject-field
return {
  { "b0o/SchemaStore.nvim", lazy = false, version = false },
  { "artemave/workspace-diagnostics.nvim" },

---@diagnostic disable-next-line: inject-field
  {
    "williamboman/mason.nvim",
    dependencies = {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      opts = {
        ensure_installed = require("utils.packages").mason_tools,
      },
    },
    build = ":MasonUpdate",
    cmd = { "Mason", "MasonInstall" },
    opts = {},
  },

  {
    "folke/lazydev.nvim",
    cmd = "LazyDev",
    lazy = false,
    dependencies = { { "justinsgithub/wezterm-types", ft = { "wezterm" } } },
    opts = { library = require("utils.packages").lazy_dev_libs },
    ft = "lua",
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
    dependencies = "williamboman/mason.nvim",
    virtual = true,
    config = function()
      require "utils.servers"
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_global_attach", { clear = true }),
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
            group = vim.api.nvim_create_augroup("lsp_organize_" .. buf, { clear = true }),
            callback = function()
              if not client:supports_method "textDocument/codeAction" then
                return
              end
              local params = vim.lsp.util.make_range_params(
                vim.api.nvim_get_current_win(), -- window handle, not 0
                client.offset_encoding
              )
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

          require("keymaps.lsp").attach(buf)
        end,
      })

    end,
  },
}
