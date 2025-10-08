local M = {}

local file_exists = function(path)
  local exists = vim.fn.filereadable(path) == 1
  return exists
end

local prettier = { "prettierd", "prettier", stop_after_first = true }
M.lint = function()
  local lint = require("lint")
  local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
  local eslint = lint.linters.eslint_d
  local php_linters = {}

  -- if file_exists("./vendor/bin/phpcs") then
  --   -- configure phpcs
  --   lint.linters.phpcs.cmd = "./vendor/bin/phpcs"
  --   table.insert(php_linters, "phpcs")
  -- end

  -- Use either composer or phive tools.
  if vim.fn.filereadable("./tools/psalm") == 1 then
    lint.linters.psalm.cmd = "./tools/psalm"
    table.insert(php_linters, "psalm")
  elseif vim.fn.filereadable("./vendor/bin/psalm") == 1 then
    lint.linters.psalm.cmd = "./vendor/bin/psalm"
    table.insert(php_linters, "psalm")
  end

  -- if Eslint error configuration not found : change MasonInstall eslint@version or npm i -g eslint at a specific version
  lint.linters_by_ft = {
    javascript = { "eslint_d" },
    typescript = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    typescriptreact = { "eslint_d" },
    terraform = {},
    cmake = { "cmakelint", "cmakelang" },
    json = { "eslint_d" },
    yaml = { "yamllint" },
    vue = {},

    php = php_linters,
    python = { "ruff", "pylint" },
    sh = { "shellcheck" },
    -- markdown = { "markdownlint-cli2" },
  }

  eslint.args = {
    "--no-warn-ignored",
    "--format",
    "json",
    "--stdin",
    "--stdin-filename",
    function()
      return vim.api.nvim_buf_get_name(0)
    end,
  }

  lint.linters.phpcs.args = {
    -- "--tab-width=2",
    "-q",
    "--report=json",
    "-",
  }

  -- Auto-lint
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = lint_augroup,
    callback = function()
      lint.try_lint()
    end,
  })

  vim.keymap.set("n", "<leader>cl", function()
    lint.try_lint()
  end, { desc = "Trigger linting" })
end

M.conform = {
  formatters = {
    ["shfmt"] = { prepend_args = { "-i", "2" } },
    prettier = {
      command = "prettier",
      args = {
        "--stdin-filepath",
        "$FILENAME",
        "--tab-width",
        "2",
        "--use-tabs",
        "false",
      },
    },
  },

  formatters_by_ft = {
    go = { "gofumpt", "golines" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    javascrspt = prettier,
    javascriptreact = prettier,
    typescript = prettier,
    typescriptreact = prettier,
    css = prettier,
    html = prettier,
    json = { "jq", "prettier", "prettierd" },
    -- json = { "jq" },
    yaml = { "prettier", "yamlfmt" },
    xml = { "xmlformatter" },
    lua = { "stylua" },
    python = { "isort" },
    php = { "pint", "php_cs_fixer" },
    rust = { "rustfmt" },
    sql = { "sqlfluff" },
    sh = { "shfmt" },
    vue = prettier,
    markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
    ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
    ["*"] = { "trim_whitespace" },
  },

  -- format_on_save = function(n)
  --   if vim.b[n].conform_disable then
  --     return
  --   end
  --   return {
  --     timeout_ms = 500,
  --     lsp_format = "fallback",
  --     lsp_fallback = true,
  --   }
  -- end,
}

return M
