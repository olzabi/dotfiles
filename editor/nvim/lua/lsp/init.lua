local function find_fn(t, path, server, seen)
  seen = seen or {}
  if seen[t] then
    return
  end
  seen[t] = true
  for k, v in pairs(t) do
    local p = path .. "." .. tostring(k)
    if type(v) == "function" then
      vim.notify(("LSP %s: function in %s"):format(server, p), vim.log.levels.ERROR)
    elseif type(v) == "table" then
      find_fn(v, p, server, seen)
    end
  end
end

local function init_servers()
  -- "*" is merged under every server config (blink caps no longer override per-server caps)
  vim.lsp.config("*", {
    capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), require("blink.cmp").get_lsp_capabilities()),
  })
  local srv_path = vim.api.nvim_get_runtime_file("lua/lsp/servers", false)[1]
  if not srv_path then
    return
  end

  local enabled = {}
  for name, type in vim.fs.dir(srv_path) do
    if type == "file" and name:match "%.lua$" then
      local mod = "lsp.servers." .. name:gsub("%.lua$", "")
      local ok, servers = pcall(require, mod)
      if ok then
        for server, cfg in pairs(servers) do
          vim.lsp.config(server, cfg)
          find_fn(cfg.settings or {}, "settings", server)
          enabled[#enabled + 1] = server
        end
      else
        vim.notify(mod .. ": " .. tostring(servers), vim.log.levels.ERROR)
      end
    end
  end
  vim.lsp.enable(enabled)
end

local function set_ref_hl()
  -- LspReference* specifically for darkvoid.nvim; re-applied on ColorScheme
  vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#1c1c1c", underline = true })
  vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#1c1c1c", sp = "#707070", underline = true })
  vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#1c1c1c", sp = "#aaaaaa", undercurl = true })
end

local function cursor_highlight(buf)
  -- clear = true => a second client attaching doesn't duplicate autocmds
  local g = vim.api.nvim_create_augroup("lsp-highlight-" .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    buffer = buf,
    group = g,
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    group = g,
    callback = vim.lsp.buf.clear_references,
  })
end

local function lsp_keymaps(buf)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { silent = true, buffer = buf, desc = desc })
  end

  -- Already built in on 0.11+: K (hover), gO (symbols), grn (rename), gra (code action),
  -- grr (references), gri (implementation), grt (type def), <C-S> (insert signature help)
  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "gt", vim.lsp.buf.type_definition, "Go to type definition")
  map("n", "gR", vim.lsp.buf.references, "References")
  map({ "n", "v" }, "g..", vim.lsp.buf.code_action, "Code action")
  map("n", "<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbols")
end

return {
  {
    "LSP",
    virtual = true,
    config = function()
      vim.o.winborder = "rounded"
      vim.diagnostic.config { severity_sort = true, float = { source = true } }
      vim.lsp.log.set_level "warn"

      set_ref_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("lsp_ref_hl", { clear = true }),
        callback = set_ref_hl,
      })

      init_servers()

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_global_attach", { clear = true }),
        callback = function(e)
          local buf = e.buf
          local c = vim.lsp.get_client_by_id(e.data.client_id)
          if not c then
            return
          end

          if c:supports_method("textDocument/inlayHint", buf) then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
          end
          if c:supports_method("textDocument/documentHighlight", buf) then
            cursor_highlight(buf)
          end

          lsp_keymaps(buf)
        end,
      })

      -- One global detach handler; only tears down highlight when no other
      -- client on the buffer still provides it.
      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("lsp_global_detach", { clear = true }),
        callback = function(e)
          local left = vim.tbl_filter(function(c)
            return c.id ~= e.data.client_id and c:supports_method("textDocument/documentHighlight", e.buf)
          end, vim.lsp.get_clients { bufnr = e.buf })
          if #left == 0 and vim.api.nvim_buf_is_valid(e.buf) then
            vim.api.nvim_buf_call(e.buf, vim.lsp.buf.clear_references)
            pcall(vim.api.nvim_del_augroup_by_name, "lsp-highlight-" .. e.buf)
          end
        end,
      })
    end,
  },
}
