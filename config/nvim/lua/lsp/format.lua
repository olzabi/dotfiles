-- oxfmt when the project has an oxfmt config (conform's oxfmt builtin knows the file names),
-- prettier otherwise. eslint_d is gone: lint comes from the oxlint / eslint LSPs.
local web = { "oxfmt", "prettier", stop_after_first = true }
local oxfmt_configs = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }

return {

  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    config = function()
      local lint = require "lint"
      lint.linters_by_ft = {
        go = { "golangcilint" },
        rust = { "clippy" },

        yaml = { "yamllint" },
        python = { "ruff" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = {},
      }

      lint.linters.shellcheck.args = {
        "-e",
        "SC2016",
        "--format=json",
        "-x",
        "-",
      }

      lint.linters.golangcilint = {
        cmd = "golangci-lint",
        stdin = false,
        stream = "stdout",
        ignore_exitcode = true,
        args = {
          "run",
          "--output.json.path=stdout",
          -- silence all other output formats
          "--output.text.path=",
          "--output.tab.path=",
          "--output.html.path=",
          "--output.checkstyle.path=",
          "--output.code-climate.path=",
          "--output.junit-xml.path=",
          "--output.teamcity.path=",
          "--output.sarif.path=",
          "--issues-exit-code=0",
          "--show-stats=false",
          "--path-mode=abs",
          function()
            -- lint the directory of the current file so module-level
            -- linters (e.g. unused, depguard) work correctly
            return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
          end,
        },
        parser = function(output, bufnr)
          if output == "" then return {} end
          local ok, decoded = pcall(vim.json.decode, output)
          if not ok or not decoded or not decoded.Issues then return {} end
          local diagnostics = {}
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          for _, issue in ipairs(decoded.Issues) do
            -- only report issues that belong to this file
            if issue.Pos and vim.fn.fnamemodify(issue.Pos.Filename, ":p") == bufname then
              table.insert(diagnostics, {
                lnum = (issue.Pos.Line or 1) - 1,
                col = (issue.Pos.Column or 1) - 1,
                message = ("[%s] %s"):format(issue.FromLinter, issue.Text),
                severity = vim.diagnostic.severity.WARN,
                source = "golangci-lint",
              })
            end
          end
          return diagnostics
        end,
      }

      lint.linters.clippy = {
        cmd = "cargo",
        stdin = false,
        stream = "stderr", -- cargo emits JSON on stderr
        ignore_exitcode = true,
        args = {
          "clippy",
          "--message-format=json",
          "--quiet",
          "--",
          "-W",
          "clippy::pedantic",
          "-W",
          "clippy::nursery",
          "-A",
          "clippy::missing_docs_in_private_items",
        },
        parser = function(output, bufnr)
          if output == "" then return {} end
          local diagnostics = {}
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          for line in output:gmatch "[^\n]+" do
            local ok, msg = pcall(vim.json.decode, line)
            if ok and msg and msg.reason == "compiler-message" then
              local m = msg.message
              -- skip `help` and `note` spans (too noisy)
              if m and m.level ~= "help" and m.level ~= "note" then
                for _, span in ipairs(m.spans or {}) do
                  if span.is_primary and vim.fn.fnamemodify(span.file_name, ":p") == bufname then
                    local severity = vim.diagnostic.severity.HINT
                    if m.level == "error" then
                      severity = vim.diagnostic.severity.ERROR
                    elseif m.level == "warning" then
                      severity = vim.diagnostic.severity.WARN
                    end
                    table.insert(diagnostics, {
                      lnum = span.line_start - 1,
                      col = span.column_start - 1,
                      end_lnum = span.line_end - 1,
                      end_col = span.column_end - 1,
                      message = m.message,
                      severity = severity,
                      source = "clippy",
                      code = m.code and m.code.code or nil,
                    })
                  end
                end
              end
            end
          end
          return diagnostics
        end,
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = function() lint.try_lint(nil, { ignore_errors = true }) end,
      })
      lint.try_lint(nil, { ignore_errors = true }) -- the buffer whose event loaded the plugin

      -- stylua: ignore start
      vim.keymap.set("n", "<leader>cl", function() lint.try_lint() end, { desc = "Trigger linting" })
      -- stylua: ignore end
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre", "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    opts = {
      format_on_save = false,
      formatters = {
        shfmt = { prepend_args = { "-i", "2" } },
        oxfmt = {
          condition = function(_, ctx) return vim.fs.root(ctx.dirname, oxfmt_configs) ~= nil end,
        },
        golines = {
          command = "golines",
          args = { "--max-len=120", "--base-formatter=gofumpt" },
          stdin = true,
        },
        kdlfmt = {
          args = { "format", "--kdl-version", "v1", "-" },
        },
      },

      formatters_by_ft = {
        ["*"] = { "trim_whitespace" },
        go = { "goimports", "golines" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        javascript = web,
        javascriptreact = web,
        typescript = web,
        typescriptreact = web,
        vue = web,
        css = web,
        scss = web,
        html = web,
        htmlangular = web,
        json = { "oxfmt", "jq", stop_after_first = true },
        jsonc = { "oxfmt", "prettier", stop_after_first = true },
        yaml = { "oxfmt", "yamlfmt", stop_after_first = true },
        toml = { "taplo" },
        lua = { "stylua" },
        kdl = { "kdlfmt" },
        python = { "ruff_format" },
        sql = { "sql_formatter" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        markdown = { "oxfmt", "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "markdownlint-cli2", "markdown-toc" },
      },
    },
    config = function(_, opts)
      local conform = require "conform"
      conform.setup(opts)

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function() conform.format { bufnr = vim.api.nvim_get_current_buf(), timeout_ms = 3000 } end,
      })
    end,
    keys = {
      -- stylua: ignore start
      { "<leader>cp", function() require("conform").format { notify_on_error = true, async = true, lsp_format = "fallback" } end, mode = { "n", "v" }, desc = "Format" },
      -- stylua: ignore end
    },
  },
}
