local function init_servers()
  -- WARN: tmp, but crucial fix;
  -- (?) client.is_closing() is broken in nvim0.12, thus some lsp doesn't work at all.
  vim.lsp.start = (function(original)
    return function(config, opts)
      local ok, err = pcall(original, config, opts)
      if not ok then
        vim.notify(err, vim.log.levels.WARN)
      end
    end
  end)(vim.lsp.start)
  --

  local capabilities = require("blink.cmp").get_lsp_capabilities()
  local srv_path = vim.api.nvim_get_runtime_file("lua/lsp/servers", false)[1]

  for name, type in vim.fs.dir(srv_path) do
    if type ~= "file" or not name:match("%.lua$") then
      goto continue
    end
    local ok, servers = pcall(require, "lsp.servers." .. name:gsub("%.lua$", ""))
    if ok then
      for server, cfg in pairs(servers) do
        cfg.capabilities = vim.tbl_deep_extend("force", cfg.capabilities or {}, capabilities)
        vim.lsp.config(server, cfg)
        vim.lsp.enable(server)
      end
    end
    ::continue::
  end
end

local function cursor_highlight(buf)
  local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    buffer = buf,
    group = highlight_augroup,
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    group = highlight_augroup,
    callback = vim.lsp.buf.clear_references,
  })
  -- LspReference specifically for darkvoid.nvim
  vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#1c1c1c", underline = true })
  vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#1c1c1c", sp = "#707070", underline = true })
  vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#1c1c1c", sp = "#aaaaaa", undercurl = true })
end

local function lsp_keymaps(buf)
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
end

return {
  {
    "LSP",
    virtual = true,
    config = function()
      init_servers()

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_global_attach", { clear = true }),
        callback = function(e)
          local buf = e.buf
          local c = vim.lsp.get_client_by_id(e.data.client_id)
          if not c then
            return
          end

          if c:supports_method "textDocument/inlayHint" then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
          end
          if c.supports_method "workspace/diagnostic" then
            vim.lsp.buf.workspace_diagnostics()
          end
          if c.supports_method "textDocument/documentHighlight" then
            cursor_highlight(buf)
          end

          lsp_keymaps(buf)

          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("lsp-detach-" .. buf, { clear = true }),
            buffer = buf,
            callback = function(cb_e)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = "lsp-highlight", buffer = cb_e.buf }
            end,
          })
        end,
      })
    end,
  },

  "b0o/SchemaStore.nvim",
  {
    "folke/lazydev.nvim",
    cmd = "LazyDev",
    lazy = false,
    dependencies = {
      {
        "justinsgithub/wezterm-types",
        enabled = false,
      },
    },
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
        { path = "wezterm-types", modes = { "wezterm" } },
        "neotest",
      },
    },
  },
}
