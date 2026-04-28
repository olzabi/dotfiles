return {

  {
    "folke/which-key.nvim",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      local wk = require "which-key"
      wk.setup()
      wk.add {
        { ";", group = ";" },
        { ";x", group = "Diagnostic" },

        { "<leader>b", group = "Buffer" },
        { "<leader>w", group = "Window" },

        { "<leader>f", group = "Find" },
        { "<leader>s", group = "Search" },
        { "<leader>n", group = "Notifications" },
        { "<leader>G", group = "Git" },
        { "<leader>R", group = "Refactoring" },

        { "<leader>u", group = "UI" },
        { "<leader>uE", group = "Editor" },
        { "<leader>uC", group = "Code" },

        { "<leader>c", group =  "Code" },
        { "<leader>cT", group = "Typescript" },

        { "<leader>cG", group = "Go Language" },
        { "<leader>cGa", group = "Go: test" },
        { "<leader>cGt", group = "Go: tags" },

        -- Parameter swap
        { "<leader>a", hidden = true },
        { "<leader>A", hidden = true },

        { "<leader>q", hidden = true },
        { "<leader>qf", hidden = true },

        -- Multicursors
        { "<up>", hidden = true },
        { "<down>", hidden = true },
        { "<leader><up>", hidden = true },
        { "<leader><down>", hidden = true },
        { "<c-q>", hidden = true },
      }
    end,
  },
}
