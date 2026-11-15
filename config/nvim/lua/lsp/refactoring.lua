return {
  -- Refactoring tool
  {
    "ThePrimeagen/refactoring.nvim",
    cmd = "Refactor",
    keys = {
      -- stylua: ignore start
      { "<leader>Rs", function() require("refactoring").select_refactor() end, mode = { "n", "v" }, desc = "Select refactor" },
      { "<leader>Re", "<cmd>Refactor extract<cr>", mode = "x", desc = "Extract function" },
      { "<leader>Rf", "<cmd>Refactor extract_to_file<cr>", mode = "x", desc = "Extract to file" },
      { "<leader>Rv", "<cmd>Refactor extract_var<cr>", mode = "x", desc = "Extract variable" },
      { "<leader>Ri", "<cmd>Refactor inline_var<cr>", mode = { "x", "n" }, desc = "Inline variable" },
      { "<leader>RI", "<cmd>Refactor inline_func<cr>", mode = "n", desc = "Inline function" },
      { "<leader>Rb", "<cmd>Refactor extract_block<cr>", mode = "n", desc = "Extract block" },
      { "<leader>RB", "<cmd>Refactor extract_block_to_file<cr>", mode = "n", desc = "Extract block to file" },
      -- stylua: ignore end
    },
    config = function()
      require("refactoring").setup {
        prompt_func_return_type = {
          go = true,
          java = true,
          cpp = true,
          c = true,
          h = true,
          hpp = true,
          cxx = true,
        },
        prompt_func_param_type = {
          go = true,
          java = true,
          cpp = true,
          c = true,
          h = true,
          hpp = true,
          cxx = true,
        },
        show_success_message = true,
      }
    end,
  },
}
