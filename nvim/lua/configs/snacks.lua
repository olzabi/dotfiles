local M = {}

M.init = function()
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      -- Setup some globals for debugging (lazy-loaded)
      _G.dd = function(...)
        Snacks.debug.inspect(...)
      end
      _G.bt = function()
        Snacks.debug.backtrace()
      end
      vim.print = _G.dd -- Override print to use snacks for `:=` command

      -- Create some toggle mappings
      Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>uCs")
      Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uCw")
      Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uEL")
      Snacks.toggle.diagnostics():map("<leader>uCD")
      Snacks.toggle.line_number():map("<leader>uEl")
      Snacks.toggle
        .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
        :map("<leader>uEcl")
      Snacks.toggle.treesitter():map("<leader>uET")
      -- Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
      Snacks.toggle.inlay_hints():map("<leader>uEh")
    end,
  })
end

---@type snacks.Config
M.opts = {
  win = { enabled = false },
  notify = { enabled = false },
  notifier = { enabled = false },
  statuscolumn = { enabled = false }, -- we set this in options.lua
  words = { enabled = false }, -- show lsp-references
  scroll = { enabled = false },
  image = {
    enabled = false,
    formats = { "png", "jpg", "jpeg", "gif", "webp", "pdf" },
  },
  scope = { enabled = false },
  profiler = { enabled = false },
  quickfile = { enabled = false },

  bigfile = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  scratch = { enabled = true },
  rocks = { enabled = true },

  terminal = {
    enabled = true,
    -- wo = {},
    -- bo = {
    --   filetype = "snacks_terminal",
    -- },
    win = {
      style = "terminal",
      border = vim.g.border_style,
    },
  },

  picker = {
    enabled = true,
    ui_select = true,
    layout = {
      cycle = true,
      -- preset = "telescope",
      preset = "vertical",
    },
    previewers = {},
    layouts = {
      dropdown = {
        -- layout = {
        --   backdrop = false,
        --   width = 0.8,
        --   min_width = 80,
        --   height = 0.8,
        --   min_height = 30,
        --   box = "vertical",
        --   border = "rounded",
        --   title = "{title} {live} {flags}",
        --   title_pos = "center",
        --   { win = "input", height = 1, border = "bottom" },
        --   { win = "list", border = "none" },
        --   { win = "preview", height = 0.6, border = "top" },
        -- },
        layout = {
          backdrop = false,
          row = 1,
          width = 0.4,
          min_width = 80,
          height = 0.8,
          border = "none",
          box = "vertical",
          { win = "preview", title = "{preview}", height = 0.4, border = "rounded" },
          {
            box = "vertical",
            border = "rounded",
            title = "{title} {live} {flags}",
            title_pos = "center",
            { win = "input", height = 1, border = "bottom" },
            { win = "list", border = "none" },
          },
        },
      },
      vertical = {
        layout = {
          box = "vertical",
          width = 0.8,
          min_width = 120,
          height = 0.8,
          min_height = 10,
          { win = "input", height = 1, border = "rounded" },
          { win = "list", title = "{title}", border = "rounded" },
          { win = "preview", title = "{preview}", border = "rounded" },
        },
      },
      explorer = {
        fullscreen = true,
        preview = true,
        layout = {
          backdrop = true,
          width = 40,
          min_width = 40,
          height = 0,
          position = "right",
          border = "none",
          box = "vertical",
          {
            win = "input",
            height = 1,
            border = "rounded",
            title = "{title} {live} {flags}",
            title_pos = "center",
          },
          { win = "list", border = "none" },
          -- { win = "preview", title = "{preview}", height = 0.4, border = "top" },
        },
      },
    },
    projects = {
      pattern = {
        ".git",
        "package.json",
      },
    },
    matcher = {
      fuzzy = true,
      smartcase = true,
      ignorecase = true,
      filename_bonus = true,
    },
  },

  styles = {
    terminal = {
      relative = "editor",
      border = "rounded",
      position = "float",
      backdrop = 60,
      height = 0.65,
      width = 0.65,
      zindex = 50,
    },
  },
}

return M
