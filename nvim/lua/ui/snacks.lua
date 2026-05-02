return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    dependencies = {
      "gbprod/yanky.nvim",
      "folke/todo-comments.nvim",
      "kdheepak/lazygit.nvim",
    },

    opts = {
      bigfile   = { enabled = true, notify = false, size = 1.5 * 1024 * 1024 },
      indent    = { enabled = true },
      input     = { enabled = true },
      scratch   = { enabled = true },
      quickfile = { enabled = true },
      terminal  = { enabled = false, win = { style = "terminal", border = vim.g.border_style } },
      lazygit   = { enabled = true, configure = true, win = { style = "lazygit" } },
      notifier  = {
        enabled = true,
        timeout = 5000,
        width = { min = 40, max = 0.4 },
        height = { min = 1, max = 0.6 },
        margin = { top = 0, right = 1, bottom = 0 },
        padding = true,
        sort = { "level", "added" },
        level = vim.log.levels.TRACE,
        style = "minimal", -- "compact" | "fancy" | "minimal"
        top_down = true,
        -- Mirror the skip/mini routes from noice for vim.notify traffic
        filter = function(notif)
          local msg = notif.msg or ""
          local skip = {
            "No signature help",
            "No code actions available",
            "^Already at %a+ change$",
            "All parsers are up%-to%-date",
          }
          for _, pat in ipairs(skip) do
            if msg:find(pat) then
              return false
            end
          end
          return true
        end,
      },

      picker    = {
        enabled = true,
        ui_select = true,
        layout = { cycle = true, preset = "vertical" },
        previewers = {},
        layouts = {
          dropdown = {
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
                { win = "input", height = 1,     border = "bottom" },
                { win = "list",  border = "none" },
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
              { win = "input",   height = 1,          border = "rounded" },
              { win = "list",    title = "{title}",   border = "rounded" },
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
              { win = "input", height = 1,     border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
              { win = "list",  border = "none" },
            },
          },
        },
        projects = { pattern = { ".git", "package.json" } },
        matcher = {
          fuzzy = true,
          smartcase = true,
          ignorecase = true,
          filename_bonus = true,
          frecency = true,
        },
        exclude = { ".git", "node_modules", }
      },
      styles    = {
        terminal = {
          relative = "editor",
          border = "rounded",
          position = "float",
          backdrop = 60,
          height = 0.65,
          width = 0.65,
          zindex = 50,
        },
        notification_history = {
          border = "rounded",
          zindex = 100,
          width = 0.6,
          height = 0.6,
          minimal = false,
          title = " Notification History ",
          title_pos = "center",
          ft = "markdown",
          bo = { filetype = "snacks_notif_history", modifiable = false },
        },
      },
    },

    init = function()
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
          Snacks.toggle.option("spell", { name = "Spelling" }):map "<leader>uCs"
          Snacks.toggle.option("wrap", { name = "Wrap" }):map "<leader>uCw"
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map "<leader>uEL"
          Snacks.toggle.diagnostics():map "<leader>uCD"
          Snacks.toggle.line_number():map "<leader>uEl"
          Snacks.toggle
              .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
              :map "<leader>uEcl"
          Snacks.toggle.treesitter():map "<leader>uET"
          -- Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
          Snacks.toggle.inlay_hints():map "<leader>uEh"
        end,
      })
    end,

    keys = {
      { ";;",         function() Snacks.picker.grep() end,                                                                            desc = "Grep" },
      { ";<leader>",  function() Snacks.picker.smart() end,                                                                           desc = "Smart find files" },
      { "<leader>hp", function() Snacks.picker.yanky() end,                                                                           mode = { "n", "x" },      desc = "Yank history" },
      { "<leader>sw", function() Snacks.picker.grep_word() end,                                                                       mode = { "n", "x" },      desc = "Visual selection or word" },
      { "<leader>hu", function() Snacks.picker.undo() end,                                                                            desc = "Undo history" },
      { "<leader>bd", function() Snacks.bufdelete() end,                                                                              desc = "Delete buffer" },
      { '<leader>"',  function() Snacks.picker.registers() end,                                                                       desc = "Registers" },
      { ";ff",        function() Snacks.picker.files() end,                                                                           desc = "Find files" },
      { ";q",         function() Snacks.picker.qflist() end,                                                                          desc = "Quickfix list" },
      { ";m",         function() Snacks.picker.marks() end,                                                                           desc = "Marks" },
      { ";P",         function() Snacks.picker.projects() end,                                                                        desc = "Projects" },
      { ";s<leader>", function() Snacks.scratch.select() end,                                                                         desc = "Select scratch" },
      { ";r",         function() Snacks.picker.recent() end,                                                                          desc = "Recent files" },
      { ";xT",        function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "WARN", "HACK", "PERF", "NOTE", "TEST" } }) end, desc = "Todo/Fix/Fixme" },
    },
  },
}
