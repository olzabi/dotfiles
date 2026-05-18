return {
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
    keys = {
      -- stylua: ignore start
      { ";xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
      { ";xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
      { ";xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols" },
      { ";xS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP (Trouble)" },
      { ";xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
      { ";xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").prev { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Prev trouble/quickfix",
      },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cnex)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Next trouble/quickfix",
      },
    },
    -- stylua: ignore end
  },
}
