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
    { import = "try" }, -- opt-in trial plugins, see lua/try/init.lua

    {
      "williamboman/mason.nvim",
      build = ":MasonUpdate",
      cmd = { "Mason", "MasonInstall" },
      opts = {},
    },

    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      opts = {
        -- CLIs also used by hk, agents or the shell (ast-grep, gh, jq, shellcheck, shfmt, stylua,
        -- yamllint, gitleaks, lua-language-server, markdownlint-cli2, taplo, typos) come from mise.
        ensure_installed = {
          "angular-language-server",
          "bash-language-server",
          "clang-format",
          "clangd",
          "cmake-language-server",
          "css-lsp",
          "css-variables-language-server",
          "cssmodules-language-server",
          "docker-compose-language-service",
          "docker-language-server",
          "dockerfile-language-server",
          "emmet-language-server",
          "gh-actions-language-server",
          "gofumpt",
          "goimports",
          "golines",
          "gopls",
          "golangci-lint",
          "html-lsp",
          "json-lsp",
          "markdown-toc",
          "postgres-language-server",
          "pyright",
          "ruff",
          "sql-formatter",
          "tailwindcss-language-server",
          "vtsls",
          "vue-language-server",
          "yaml-language-server",
          "yamlfmt",
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
        "tutor",
        "zipPlugin",
      },
    },
  },
  change_detection = { enabled = true, notify = false },
}
