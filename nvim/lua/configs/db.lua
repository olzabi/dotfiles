local M = {}

M.config = function()
  vim.g.db_ui_execute_on_save = 1 --do not execute on save
  vim.g.db_ui_win_position = "left"
  vim.g.db_ui_use_nerd_fonts = 1
  vim.g.db_ui_use_nvim_notify = 1

  vim.g.db_ui_table_helpers = {
    mysql = {
      Count = "select count(1) from {optional_schema}{table}",
      Explain = "EXPLAIN {last_query}",
    },
    sqlite = {
      Describe = "PRAGMA table_info({table})",
    },
  }

  vim.g.db_ui_icons = require('utils.icons').dbui

  vim.api.nvim_create_autocmd("FileType", {
    pattern = {
      "sql",
    },
    command = [[setlocal omnifunc=vim_dadbod_completion#omni]],
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = {
      "sql",
      "mysql",
      "plsql",
    },
    callback = function()
      vim.schedule(require("cmp").setup.buffer({ sources = { { name = "vim-dadbod-completion" } } }))
    end,
  })
end

return M
