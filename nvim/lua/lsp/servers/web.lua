local M = {}

M.html = {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = {
    "html",
    "htmlangular",
    "blade",
    "erb",
    "eruby",
    "gohtml",
    "handlebars",
    "svelte",
    "vue",
    "templ",
  },
  root_markers = { "package.json", ".git" },
  init_options = {
    provideFormatter = true,
    configurationSection = { "html", "css", "javascript" },
    embeddedLanguages = { css = true, javascript = true },
  },
}

M.eslint = {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
  },
  root_markers = {
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    "eslint.config.js",
    "eslint.config.mjs",
    "package.json",
  },
  settings = {
    format = true,
    run = "onType",
    validate = "on",
    workingDirectory = { mode = "location" },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
  },
}

M.emmet_ls = {
  cmd = { "emmet-ls", "--stdio" },
  filetypes = {
    "html",
    "css",
    "scss",
    "less",
    "sass",
    "javascriptreact",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
  },
  root_markers = { ".git", "package.json" },
}

M.css_variables = {
  cmd = { "css-variables-language-server", "--stdio" },
  filetypes = { "css", "scss", "less", "svelte" },
  root_markers = { "package.json", ".git" },
  settings = {
    cssVariables = {
      blacklistFolders = {
        "**/.cache",
        "**/.git",
        "**/.next",
        "**/dist",
        "**/node_modules",
        "**/tmp",
      },
      lookupFiles = { "**/*.less", "**/*.scss", "**/*.sass", "**/*.css" },
    },
  },
}

M.cssls = {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  root_markers = { "package.json", ".git" },
  init_options = { provideFormatter = true },
  settings = {
    css = { validate = true, lint = { unknownAtRules = "ignore" } },
    less = { validate = true, lint = { unknownAtRules = "ignore" } },
    scss = { validate = true, lint = { unknownAtRules = "ignore" } },
  },
}

M.graphql = {
  cmd = { "graphql-lsp", "server", "-m", "stream" },
  filetypes = { "graphql", "typescriptreact", "javascriptreact" },
  root_markers = { ".graphqlrc", ".graphqlrc.json", "graphql.config.js", ".git" },
}

return M
