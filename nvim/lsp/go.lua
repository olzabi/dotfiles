--- @type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "go.sum", "gowork", "gotmpl" },
  root_markers = { "go", ".git" },
  single_file_support = true,
  settings = {
    telemetry = false,
    gopls = {
      gofumpt = true,
      staticcheck = true,
      usePlaceholders = true,
      completeUnimported = true,
      directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
      semanticTokens = true,
      analyses = {
              unusedparams = true,
      },
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypesParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
  on_attach = require("configs.lsp.on_attach"),
  capabilities = require("configs.lsp.capabilities"),
}
