local function session_finder()
  local dir = vim.fn.stdpath "state" .. "/sessions/"
  local files = vim.fn.glob(dir .. "*.vim", false, true)
  local items = {}
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t")
    local readable = name:gsub("%%", "/"):gsub("%.vim$", "")
    table.insert(items, { text = readable, file = f })
  end
  return items
end

local session_layout = {
  preset = "select",
  preview = false,
}

local function session_format(item)
  return { { item.text, "SnacksPickerLabel" } }
end

return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    dependencies = {
      "gbprod/yanky.nvim",
      "folke/todo-comments.nvim",
    },

    -- stylua: ignore start
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

      picker = {
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
              { win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
              { win = "list",  border = "none" },
            },
          },
        },
        projects = {
          pattern = { ".git", "package.json" }
        },
        matcher = {
          fuzzy = true,
          smartcase = true,
          ignorecase = true,
          filename_bonus = true,
          frecency = true,
        },
        exclude = { ".git", "node_modules" },
        sources = {
          persistence_delete = {
            title = "Delete Session",
            finder = session_finder,
            format = session_format,
            layout = session_layout,
            confirm = function(picker, item)
              picker:close()
              if item then
                vim.fn.delete(item.file)
                vim.notify("Deleted: " .. item.text)
              end
            end,
          },
          persistence_load = {
            title = "Load Session",
            finder = session_finder,
            format = session_format,
            layout = session_layout,
            confirm = function(picker, item)
              picker:close()
              if item then
                require("persistence").load({ session = item.file })
              end
            end,
          },
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
        notification_history = {
          border = "rounded",
          zindex = 100,
          width  = 0.6,
          height = 0.6,
          minimal = false,
          title = " Notification History ",
          title_pos = "center",
          ft = "markdown",
          bo = {
            filetype = "snacks_notif_history",
            modifiable = true,
            readonly = true
          },
          keys = { q = "close" },
        },
      },
    },

    keys = {
      { ";;",         function() Snacks.picker.grep() end,                                                                                   desc = "Grep" },
      { ";<leader>",  function() Snacks.picker.smart() end,                                                                                  desc = "Smart find files" },
      { "<leader>hp", function() Snacks.picker.yanky() end,                                                                                  mode = { "n", "x" }, desc = "Yank history" },
      { "<leader>sw", function() Snacks.picker.grep_word() end,                                                                              mode = { "n", "x" }, desc = "Visual selection or word" },
      { "<leader>hu", function() Snacks.picker.undo() end,                                                                                   desc = "Undo history" },
      { "<leader>bd", function() Snacks.bufdelete() end,                                                                                     desc = "Delete buffer" },
      { '<leader>"',  function() Snacks.picker.registers() end,                                                                              desc = "Registers" },
      { ";ff",        function() Snacks.picker.files() end,                                                                                  desc = "Find files" },
      { ";q",         function() Snacks.picker.qflist() end,                                                                                 desc = "Quickfix list" },
      { ";m",         function() Snacks.picker.marks() end,                                                                                  desc = "Marks" },
      { ";P",         function() Snacks.picker.projects() end,                                                                               desc = "Projects" },
      { ";s<leader>", function() Snacks.scratch.select() end,                                                                                desc = "Select scratch" },
      { ";r",         function() Snacks.picker.recent() end,                                                                                 desc = "Recent files" },
      { ";xT",        function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "WARN", "HACK", "PERF", "NOTE", "TEST" } }) end, desc = "Todo/Fix/Fixme" },
    },
    -- stylua: ignore end

    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd
        end,
      })
    end,
  },
}
