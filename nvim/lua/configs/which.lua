local M = {}

M.init = function()
  vim.o.timeout = true
  vim.o.timeoutlen = 300
end

M.config = function()
  local wk = require("which-key")
  wk.setup()
  wk.add({
    { "<leader>b", group = "Buffer" },
    { "<leader>w", group = "Window" },
    { "<leader>d", group = "Debug" },
    { "<leader>f", group = "Find" },
    { "<leader>s", group = "Search" },
    { "<leader>n", group = "Notifications" },

    { "<leader>u", group = "UI" },
    { "<leader>uG", group = "Git" },
    { "<leader>uE", group = "Editor" },
    { "<leader>uC", group = "Code" },

    { "<leader>c", group = "Code" },
    { "<leader>cT", group = "Typescript" },
    { "<leader>cP", group = "PHP" },

    { "<leader>G", group = "Git" },
    { "<leader>R", group = "Refactoring" },
    -- { "<leader>t", group = "Trouble" },

    { ";", group = ";" },
    { ";c", group = "Code" },
    { ";G", group = "Git" },
    { ";Gw", group = "Git Worktree" },
    { ";s", group = "Search" },
    { ";f", group = "Find" },
    { ";x", group = "Diagnostic" },

    { "-", group = "PHP Easy" },
    { ";L", group = "Laravel" },

    { ";P", group = "PHP Tools" },
    { ";Ph", group = "Helpers" },
    { ";Pt", group = "Tests" },

    { "<leader>e", hidden = true },
    { "<leader>j", hidden = true },
    { "<leader>w", hidden = false },
    { "<leader>q", hidden = true },
    { "<leader>qf", hidden = true },
    { "<leader>W", hidden = true },
    { "<leader>Q", hidden = true },
    { "<leader><C-Down>", hidden = true },
  })
end

return M
