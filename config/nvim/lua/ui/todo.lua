return {

  {
    "folke/todo-comments.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local todo_comments = require "todo-comments"

      todo_comments.setup {
        signs = true,
        keywords = {
          FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
          TODO = { icon = " ", color = "info" },
          HACK = { icon = " ", color = "warning" },
          WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
          PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
          NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
          TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
        },
        highlight = {
          multiline = true,
          multiline_pattern = "^.",
          multiline_context = 10,
          before = "",
          keyword = "wide",
          after = "fg",
          comments_only = false,
          pattern = {
            [[.*<(KEYWORDS)\s*:]], -- default pattern
            [[<!--\s*(KEYWORDS)\s*:.*-->]], -- HTML comments with colon
            [[<!--\s*(KEYWORDS)\s*.*-->]], -- HTML comments without colon
          },
        },
        search = {
          command = "rg",
          args = {
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
          },
          pattern = [[\b(KEYWORDS)\b]],
        },
      }

      vim.keymap.set("n", "]t", function()
        todo_comments.jump_next()
      end, { desc = "Next todo comment" })

      vim.keymap.set("n", "[t", function()
        todo_comments.jump_prev()
      end, { desc = "Previous todo comment" })
    end,
  },
}
