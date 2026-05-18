vim.filetype.add {
  pattern = {
    [".*%.overlay"] = "c",
    [".*%.dts"] = "c",
    [".*%.dtsi"] = "devicetree",
    [".*%.keymap"] = "devicetree"
  },
}

vim.filetype.add {
  extension = {
    es6 = "javascript",
    mts = "typescript",
    cts = "typescript",
  },
  filename = {
    [".eslintrc"] = "json",
    [".prettierrc"] = "json",
    [".babelrc"] = "json",
    [".stylelintrc"] = "json",
  },
  pattern = {
    [".*config/git/config"] = "gitconfig",
    [".env.*"] = "sh",
  },
}

vim.filetype.add {
  filename = {
    [".env"] = "sh",
    [".envrc"] = "sh",
  },
  pattern = {
    ["%.env"] = "sh",
    ["%.envrc"] = "sh",
  },
}

vim.filetype.add {
  pattern = {
    [".*/%.github[%w/]+workflows[%w/]+.*%.ya?ml"] = "yaml.github",
  },
}

vim.filetype.add {
  extension = {
    mdx = "mdx",
    blade = "blade",
    ["blade.php"] = "blade",
  },
  pattern = { [".*%.blade%.php"] = "blade" },
}

vim.filetype.add {
  extension = {
    keymap = "devicetree",
    dtsi = "devicetree",
  },
}
