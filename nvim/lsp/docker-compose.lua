--- @type vim.lsp.Config
return {
  cmd = { "docker-compose-langserver", "--stdio" },
  filetypes = { "yaml.docker-compose" },
  root_markers = {
    "docker-compose.yaml",
    "docker-compose.*.yaml",
    "docker-compose.yml",
    "docker-compose.*.yml",
    "compose.yaml",
    "compose.*.yaml",
    "compose.*.yml",
  },
}
