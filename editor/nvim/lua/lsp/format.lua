local prettier = { "prettierd" }

return {

  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    config = function()
      local lint = require "lint"
      local php_linters = {}

      -- Use either composer or phive tools.
      if vim.fn.filereadable "./tools/psalm" == 1 then
        lint.linters.psalm.cmd = "./tools/psalm"
        table.insert(php_linters, "psalm")
      elseif vim.fn.filereadable "./vendor/bin/psalm" == 1 then
        lint.linters.psalm.cmd = "./vendor/bin/psalm"
        table.insert(php_linters, "psalm")
      end

      lint.linters_by_ft = {
        go = { "golangcilint" },
        rust = { "clippy" },

        terraform = { "terraform_validate", "tflint", "tfsec" },
        cmake = { "cmakelint", "cmakelang" },
        yaml = { "yamllint" },
        php = php_linters,
        python = { "ruff", "pylint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "zsh" },
      }

      lint.linters.eslint_d.args = {
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
        "-q",
        "--report=json",
        "-",
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
          if output == "" then
            return {}
          end
          local ok, decoded = pcall(vim.json.decode, output)
          if not ok or not decoded or not decoded.Issues then
            return {}
          end
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
          if output == "" then
            return {}
          end
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

      -- stylua: ignore start
      vim.keymap.set("n", "<leader>cl", function() lint.try_lint() end, { desc = "Trigger linting" })
      -- stylua: ignore end
    end,
  },

  {
    "stevearc/conform.nvim",
    dependencies = { "MunifTanjim/prettier.nvim", "mcauley-penney/tidy.nvim", "bennypowers/svgo.nvim" },
    event = { "BufWritePre", "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    opts = {
      format_on_save = false,
      formatters = {
        shfmt = { prepend_args = { "-i", "2" } },
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
        taplo = {
          command = "taplo",
          args = { "format", "-" },
          stdin = true,
        },
        golines = {
          command = "golines",
          args = { "--max-len=120", "--base-formatter=gofumpt" },
          stdin = true,
        },
      },

      formatters_by_ft = {
        ["*"] = { "trim_whitespace" },
        go = { "goimports", "golines" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        javascript = prettier,
        javascriptreact = prettier,
        typescript = prettier,
        typescriptreact = prettier,
        vue = prettier,
        css = prettier,
        html = prettier,
        json = { "jq" },
        yaml = { "yamlfmt" },
        xml = { "xmlformatter" },
        toml = { "taplo" },
        lua = { "stylua" },
        python = { "isort", "ruff_format" },
        php = { "pint" },
        sql = { "sqlfluff" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
      },
    },
    config = function(_, opts)
      local conform = require "conform"
      conform.setup(opts)

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          conform.format { bufnr = vim.api.nvim_get_current_buf(), timeout_ms = 3000 }
        end,
      })
    end,
    keys = {
      -- stylua: ignore start
      { "<leader>cp", function() require("conform").format { notify_on_error = true, async = true, lsp_fallback = true } end, mode = { "n", "v" }, desc = "Format", },
      -- stylua: ignore end
    },
  },
}
