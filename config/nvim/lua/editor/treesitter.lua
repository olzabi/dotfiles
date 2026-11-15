-- nvim-treesitter `main` branch: no lazy-loading, no highlight/indent opts.
-- Incremental selection is native in 0.12: `an` / `in` (and ]n [n) in visual mode.
-- Parsers are installed with ts.install(), highlighting/indent are started
-- from a FileType autocmd.

-- The single parser list (init.lua's old `ensure_installed` did nothing on `main`).
local parsers_to_install = {
  -- nvim
  "lua",
  "luadoc",
  "luap",
  "vim",
  "vimdoc",
  "query",
  -- docs / data
  "markdown",
  "markdown_inline",
  "json",
  "json5",
  "yaml",
  "toml",
  "xml",
  "kdl",
  "regex",
  "diff",
  -- shell / infra
  "bash",
  "dockerfile",
  "make",
  "sql",
  -- git
  "gitcommit",
  "git_rebase",
  "git_config",
  "gitattributes",
  "gitignore",
  -- web (Angular / NestJS)
  "javascript",
  "typescript",
  "tsx",
  "jsdoc",
  "html",
  "css",
  "scss",
  "angular",
  "graphql",
  "vue",
  -- systems
  "go",
  "gomod",
  "gosum",
  "gowork",
  "rust",
  "c",
  "cpp",
  "cmake",
  "python",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" } },
    config = function()
      local ts = require "nvim-treesitter"
      ts.setup {}
      ts.install(parsers_to_install) -- async, skips what's already installed

      vim.filetype.add {
        extension = { mdx = "mdx" },
      }
      vim.treesitter.language.register("markdown", "mdx")

      -- Highlighting + indent (replaces the old `highlight` / `indent` opts)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ts-start", { clear = true }),
        callback = function(args)
          local buf = args.buf
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then return end

          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > 100 * 1024 then
            vim.notify("File >100KB: treesitter disabled", vim.log.levels.WARN)
            return
          end

          -- fails silently if the parser isn't installed yet (first run, async install)
          if pcall(vim.treesitter.start, buf, lang) then vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
        end,
      })

      -- Textobjects (main-branch API) -------------------------------------
      require("nvim-treesitter-textobjects").setup {
        select = { lookahead = true },
        move = { set_jumps = true },
      }
      local to_select = require "nvim-treesitter-textobjects.select"
      local to_move = require "nvim-treesitter-textobjects.move"
      local to_swap = require "nvim-treesitter-textobjects.swap"

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
        vim.keymap.set({ "x", "o" }, key, function() to_select.select_textobject(query, "textobjects") end, { desc = "TS select " .. query })
      end

      -- ]c / [c are Neovim's diff-hunk motions, so classes use ]k / [k instead
      local move_maps = {
        { key = "]f", method = "goto_next_start", query = "@function.outer" },
        { key = "]k", method = "goto_next_start", query = "@class.outer" },
        { key = "]F", method = "goto_next_end", query = "@function.outer" },
        { key = "]K", method = "goto_next_end", query = "@class.outer" },
        { key = "[f", method = "goto_previous_start", query = "@function.outer" },
        { key = "[k", method = "goto_previous_start", query = "@class.outer" },
        { key = "[F", method = "goto_previous_end", query = "@function.outer" },
        { key = "[K", method = "goto_previous_end", query = "@class.outer" },
      }
      for _, m in ipairs(move_maps) do
        vim.keymap.set({ "n", "x", "o" }, m.key, function() to_move[m.method](m.query, "textobjects") end, { desc = "TS " .. m.method .. " " .. m.query })
      end

      -- stylua: ignore start
      vim.keymap.set("n", "<leader>a", function() to_swap.swap_next "@parameter.inner" end, { desc = "Swap next parameter" })
      vim.keymap.set("n", "<leader>A", function() to_swap.swap_previous "@parameter.inner" end, { desc = "Swap prev parameter" })
      -- stylua: ignore end
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = { max_lines = 5, mode = "topline" },
  },
}
