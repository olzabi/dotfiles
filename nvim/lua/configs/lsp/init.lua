local M = {}

M.setup_lsp = function()
  local capabilities = require("configs.lsp.capabilities")
  local on_attach = require("configs.lsp.on_attach")
  local setup_servers = require("configs.lsp.servers").setup_servers

  setup_servers(capabilities, on_attach)

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
      local bufopts = { noremap = true, silent = true, buffer = event.buf }
      -- common keymaps
      local buf = vim.lsp.buf
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
end

M.mason_setup = function()
  local mason_lspconfig = require("mason-lspconfig")
  local mason = require("mason")
  local server_list = require("configs.lsp.servers").servers
  mason.setup({
    registries = { "github:crashdummyy/mason-registry", "github:mason-org/mason-registry" },
  })

  mason_lspconfig.setup({
    automatic_enable = false,
    automatic_installation = true,
    ensure_installed = vim.tbl_keys(server_list),
    handlers = server_list,
  })
end

return M
