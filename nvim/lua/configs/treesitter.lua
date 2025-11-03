local M = {}

local highlight_disable = function(lang, buf)
  if lang == "html" then
    print("disabled")
    return true
  end

  local max_filesize = 100 * 1024 -- 100 KB
  local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
  if ok and stats and stats.size > max_filesize then
    vim.notify(
      "File larger than 100KB treesitter disabled for performance",
      vim.log.levels.WARN,
      { title = "Treesitter" }
    )
    return true
  end
end

local opts = {
  ensure_installed = require("utils.packages").treesitter,
  modules = {},
  sync_install = false,
  auto_install = true,
  indent = { enable = true },
  highlight = {
    -- `false` will disable the whole extension
    enable = true,
    disable = highlight_disable,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = false,
    },
    additional_vim_regex_highlighting = { "markdown" },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["ii"] = "@conditional.inner",
        ["ai"] = "@conditional.outer",
        ["il"] = "@loop.inner",
        ["al"] = "@loop.outer",
        ["at"] = "@comment.outer",
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]f"] = "@function.outer",
        ["]c"] = "@class.outer",
      },
      goto_next_end = {
        ["]F"] = "@function.outer",
        ["]C"] = "@class.outer",
      },
      goto_previous_start = {
        ["[f"] = "@function.outer",
        ["[c"] = "@class.outer",
      },
      goto_previous_end = {
        ["[F"] = "@function.outer",
        ["[C"] = "@class.outer",
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ["<leader>a"] = "@parameter.inner",
      },
      swap_previous = {
        ["<leader>A"] = "@parameter.inner",
      },
    },
    additional_vim_regex_highlighting = false,
  },
}

M.dependencies = {
  "nvim-treesitter/nvim-treesitter-textobjects",
  "tree-sitter-grammars/tree-sitter-markdown",
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = { max_lines = 5, mode = "topline" },
    keys = require("keymaps").treesitter,
  },
  {
    "windwp/nvim-ts-autotag",
    enabled = false,
    after = "nvim-treesitter",
    event = "InsertEnter",
    filetype = { "typescriptreact", "typescript", "javascript", "markdown", "html", "jsx", "tsx", "xml" },
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },
}

M.config = function()
  require("nvim-treesitter.configs").setup(opts)

  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  ---@diagnostic disable-next-line: inject-field
  parser_config.templ = {
    install_info = {
      url = "https://github.com/vrischmann/tree-sitter-templ.git",
      files = { "src/parser.c", "src/scanner.c" },
      branch = "master",
    },
  }
  vim.treesitter.language.register("templ", "templ")

  ---@diagnostic disable-next-line: inject-field
  parser_config.gotmpl = {
    install_info = {
      url = "https://github.com/ngalaiko/tree-sitter-go-template",
      files = { "src/parser.c" },
    },
    filetype = "gotmpl",
    used_by = { "gotext", "gotemplate", "yaml", "tpl", "gohtmltmpl" },
  }
  parser_config.tsx.filetype = { "javascript", "typescript" }

  ---@diagnostic disable-next-line: inject-field
  parser_config.blade = {
    install_info = {
      url = "https://github.com/EmranMR/tree-sitter-blade",
      files = { "src/parser.c" },
      branch = "main",
    },
    filetype = "blade",
  }
  vim.filetype.add({
    extension = {
      blade = "blade",
      ["blade.php"] = "blade",
    },
    pattern = { [".*%.blade%.php"] = "phtml" },
  })

  local bladeGrp
  vim.api.nvim_create_augroup("BladeFiltypeRelated", { clear = true })
  vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    pattern = "*.blade.php",
    group = bladeGrp,
    callback = function()
      vim.opt.filetype = "blade"
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "blade",
    callback = function()
      vim.bo.filetype = "html"
    end,
  })

  -- MDX
  vim.filetype.add({ extension = { mdx = "mdx" } })
  vim.treesitter.language.register("markdown", "mdx")
end

return M
