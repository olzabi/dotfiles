require "core"

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup {
  spec = {
    { import = "editor" },
    { import = "lsp" },
    { import = "lsp.languages" },
    { import = "ui" },

    {
      "williamboman/mason.nvim",
      build = ":MasonUpdate",
      cmd = { "Mason", "MasonInstall" },
      opts = {},
    },

    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      opts = {
        ensure_installed = {
          "angular-language-server",
          "ansible-language-server",
          "ansible-lint",
          "ast-grep",
          "arduino-language-server",
          "bash-language-server",
          "blade-formatter",
          "buf",
          "clang-format",
          "clangd",
          "cmake-language-server",
          "cmakelang",
          "cmakelint",
          "cpptools",
          "cspell",
          "css-lsp",
          "css-variables-language-server",
          "cssmodules-language-server",
          "delve",
          "docker-compose-language-service",
          "docker-language-server",
          "dockerfile-language-server",
          "emmet-language-server",
          "eslint_d",
          "gh",
          "gh-actions-language-server",
          "gitlab-ci-ls",
          "gitleaks",
          "gofumpt",
          "goimports",
          "golines",
          "gopls",
          "golangci-lint",
          "gomodifytags",
          "gotests",
          "gotestsum",
          "json-to-struct",
          "html-lsp",
          "htmx-lsp",
          "jq",
          "jq-lsp",
          "json-lsp",
          "jsonlint",
          "laravel-ls",
          "lua-language-server",
          "markdown-toc",
          "markdownlint-cli2",
          "php-cs-fixer",
          "phpactor",
          "phpcs",
          "phpstan",
          "postgres-language-server",
          "prettierd",
          "pydocstyle",
          "pylint",
          "pyright",
          "ruff",
          "shellcheck",
          "shfmt",
          "sql-formatter",
          "sqlls",
          "stylua",
          "svelte-language-server",
          "tailwindcss-language-server",
          "terraform",
          "terraform-ls",
          "tflint",
          "vtsls",
          "vue-language-server",
          "yaml-language-server",
          "yamlfmt",
          "yamllint",
        },
      },
    },

    {
      "nvim-treesitter/nvim-treesitter",
      opts = {
        ensure_installed = {
          -- Shell
          "bash",
          -- C / C++
          "c",
          "cpp",
          "cmake",
          -- CSS / HTML
          "css",
          "html",
          -- Docker
          "dockerfile",
          -- Go
          "go",
          "gomod",
          "gosum",
          "gowork",
          -- Git
          "git_config",
          "git_rebase",
          "gitattributes",
          "gitcommit",
          "gitignore",
          -- JSON / YAML / TOML
          "json",
          "json5",
          "yaml",
          "toml",
          -- Lua
          "lua",
          "luadoc",
          "luap",
          -- Markdown
          "markdown",
          "markdown_inline",
          -- PHP
          "php",
          "phpdoc",
          -- Python
          "python",
          -- SQL
          "sql",
          -- Terraform / HCL
          "terraform",
          "hcl",
          -- TypeScript / JavaScript
          "javascript",
          "typescript",
          "tsx",
          "jsdoc",
          -- Vue / Svelte / Angular
          "vue",
          "svelte",
          "angular",
          -- Web
          "graphql",
          "scss",
          -- Vim / Neovim
          "vim",
          "vimdoc",
          "query",
          -- Misc
          "diff",
          "regex",
          "xml",
        },
      },
    },

  },
  checker = { enabled = false },
  performance = {
    cache = { enabled = true },
    rtp = {
      -- Required in NixOS
      reset = false,
      disabled_plugins = {
        "gzip",
        -- "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  change_detection = { enabled = true, notify = false },
}
