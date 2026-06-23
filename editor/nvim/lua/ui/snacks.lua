return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,

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

      picker = { enabled = true, ui_select = true },
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
          width = 0.6,
          height = 0.6,
          minimal = false,
          title = " Notification History ",
          title_pos = "center",
          ft = "markdown",
          bo = {
            filetype = "snacks_notif_history",
            modifiable = true,
            readonly = true,
          },
          keys = { q = "close" },
        },
      },
    },

    keys = {
      { "<leader>bd", function() Snacks.bufdelete() end,      desc = "Delete buffer" },
      { ";s<leader>", function() Snacks.scratch.select() end, desc = "Select scratch" },
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
