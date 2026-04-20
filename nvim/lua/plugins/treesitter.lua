local disable_hl = {
  enable = true,
  additional_vim_regex_highlighting = false,
  disable = function(_, buf)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
    if ok and stats and stats.size > 100 * 1024 then
      vim.notify("File >100KB: treesitter disabled", vim.log.levels.WARN)
      return true
    end
  end,
}

return {
  { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = { max_lines = 5, mode = "topline" },
    keys = require("keymaps").treesitter,
  },

  {
    -- popular language parser for syntax highlighting
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    event = { "BufReadPre" },
    build = ":TSUpdate",
    opts = {
      ensure_installed = require("utils.packages").treesitter,
      sync_install = false,
      auto_install = true,
      indent = { enable = true },
      highlight = disable_hl,
      incremental_selection = {
        enable = true,
        keymaps = { init_selection = "<C-space>", node_incremental = "<C-space>", scope_incremental = false },
      },
    },
    config = function(_, opts)
      local parser_config = require "nvim-treesitter.parsers"

      parser_config.blade = {
        install_info = {
          url = "https://github.com/EmranMR/tree-sitter-blade",
          files = { "src/parser.c" },
          branch = "main",
        },
        filetype = "blade",
      }

      parser_config.templ = {
        install_info = {
          url = "https://github.com/vrischmann/tree-sitter-templ.git",
          files = { "src/parser.c", "src/scanner.c" },
          branch = "master",
        },
      }

      parser_config.gotmpl = {
        install_info = {
          url = "https://github.com/ngalaiko/tree-sitter-go-template",
          files = { "src/parser.c" },
        },
        filetype = "gotmpl",
        used_by = { "gotext", "gotemplate", "yaml", "tpl", "gohtmltmpl" },
      }

     require("nvim-treesitter").setup(opts)

      -- select/swap keymaps are explicit vim.keymap.set calls
      local to_select = require "nvim-treesitter-textobjects.select"
      local to_move = require "nvim-treesitter-textobjects.move"
      local to_swap = require "nvim-treesitter-textobjects.swap"

      require("nvim-treesitter-textobjects").setup { move = { set_jumps = true } }

      -- Select text objects
      local select_maps = {
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
        ["at"] = "@comment.outer",
      }
      for key, query in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, function()
          to_select.select_textobject(query, "textobjects")
        end, { desc = "TS select " .. query })
      end

      -- Move between text objects
      local move_maps = {
        { key = "]f", method = "goto_next_start", query = "@function.outer" },
        { key = "]c", method = "goto_next_start", query = "@class.outer" },
        { key = "]F", method = "goto_next_end", query = "@function.outer" },
        { key = "]C", method = "goto_next_end", query = "@class.outer" },
        { key = "[f", method = "goto_previous_start", query = "@function.outer" },
        { key = "[c", method = "goto_previous_start", query = "@class.outer" },
        { key = "[F", method = "goto_previous_end", query = "@function.outer" },
        { key = "[C", method = "goto_previous_end", query = "@class.outer" },
      }
      for _, m in ipairs(move_maps) do
        vim.keymap.set({ "n", "x", "o" }, m.key, function()
          to_move[m.method](m.query, "textobjects")
        end, { desc = "TS " .. m.method .. " " .. m.query })
      end

      -- Swap parameters
      vim.keymap.set("n", "<leader>a", function()
        to_swap.swap_next "@parameter.inner"
      end, { desc = "Swap next parameter" })
      vim.keymap.set("n", "<leader>A", function()
        to_swap.swap_previous "@parameter.inner"
      end, { desc = "Swap prev parameter" })

      vim.filetype.add {
        extension = {
          mdx = "mdx",
          blade = "blade",
          ["blade.php"] = "blade",
        },
        pattern = { [".*%.blade%.php"] = "blade" },
      }
      vim.treesitter.language.register("markdown", "mdx")
    end,
  },
}
