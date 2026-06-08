local check_llama_cpp_host = function(host)
  local cmd = 'curl -s -o /dev/null -w "%{http_code}\n" -m 0.1 -I ' .. host
  return string.match(vim.fn.system(cmd), "200")
end
local host = "http://localhost:11435"
local is_llama_cpp_running = check_llama_cpp_host(host)

return {
  {
    "ggml-org/llama.vim",
    enabled = false,
    init = function()
      vim.g.llama_config = {
        endpoint = host .. "/infill",
        api_key = " ",
        model = " ",
        n_predict = 128,
        stop_strings = {},
        t_max_prompt_ms = 500,
        t_max_predict_ms = 500,
        show_info = 2,
        max_line_suffix = 8,
        max_cache_keys = 250,
        ring_n_chunks = 16,
        ring_chunk_size = 64,
        ring_scope = 1024,
        ring_update_ms = 1000,
        keymap_trigger = "<c-e>",
        keymap_accept_full = "<c-e>",
        keymap_accept_line = "",
        keymap_accept_word = "",
        n_prefix = 1024,
        n_suffix = 1024,
        auto_fim = false,
        enable_at_startup = is_llama_cpp_running,
      }
    end,
  },

  {
    "piersolenski/wtf.nvim",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
    },
    opts = {},
    keys = {
      -- {  "<leader>wd", mode = { "n", "x" }, function() require("wtf").diagnose() end, desc = "Debug diagnostic with AI", },
      -- {  "<leader>wf", mode = { "n", "x" }, function() require("wtf").fix() end, desc = "Fix diagnostic with AI", },
      -- {  "<leader>ws", mode = { "n" },      function() require("wtf").search() end, desc = "Search diagnostic with Google", },
      -- {  "<leader>wp", mode = { "n" },      function() require("wtf").pick_provider() end, desc = "Pick provider", },
      -- {  "<leader>wh", mode = { "n" },      function() require("wtf").history() end, desc = "Populate the quickfix list with previous chat history", },
      -- {  "<leader>wg", mode = { "n" },      function() require("wtf").grep_history() end, desc = "Grep previous chat history with Telescope", },
      -- {  "<leader>wy", mode = { "n", "x" }, function() require("wtf").yank() end, desc = "Yank diagnostic to clipboard", },
    },
  },

  {
    "greggh/claude-code.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("claude-code").setup({
        window = {
          enter_insert = false,
        },
      })
      vim.keymap.set("n", ";a", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })
    end,
  },
}
