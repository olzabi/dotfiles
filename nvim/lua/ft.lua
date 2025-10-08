vim.filetype.add({
  pattern = { [".*%.overlay"] = "c", [".*%.dts"] = "c" },
})
vim.cmd([[autocmd BufNewFile,BufRead *.keymap setfiletype c]])

vim.filetype.add({
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
})

vim.filetype.add({
  filename = {
    [".env"] = "sh",
    [".envrc"] = "sh",
  },
  pattern = {
    ["%.env"] = "sh",
    ["%.envrc"] = "sh",
  },
})
