local M = {}

M.ansiblels = {
  cmd = { "ansible-language-server", "--stdio" },
  filetypes = { "yaml.ansible" },
  root_markers = { "ansible.cfg", ".ansible-lint" },
  settings = {
    ansible = {
      ansible = { path = "ansible" },
      executionEnvironment = { enabled = false },
      python = { interpreterPath = "python" },
      validation = {
        enabled = true,
        lint = { enabled = true, path = "ansible-lint" },
      },
    },
  },
}

M.dockerls = {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile" },
}

M.docker_compose_language_service = {
  cmd = { "docker-compose-langserver", "--stdio" },
  filetypes = { "yaml.docker-compose" },
  root_markers = {
    "docker-compose.yaml",
    "docker-compose.yml",
    "compose.yaml",
    "compose.yml",
  },
}

M.gh_actions_ls = {
  cmd = { "gh-actions-language-server", "--stdio" },
  filetypes = { "yaml" },
  root_dir = function(bufnr, on_dir)
    local parent = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
    if vim.endswith(parent, "/.github/workflows") then
      on_dir(parent)
    end
  end,
  init_options = {},
}

M.terraformls = {
  cmd = { "terraform-ls", "serve" },
  filetypes = { "terraform", "tf", "terraform-vars" },
  root_markers = { ".terraform", ".terraform.lock.hcl", ".git" },
}

M.nginx_language_server = {
  cmd = { "nginx-language-server" },
  filetypes = { "nginx" },
  root_markers = { "nginx.conf", ".git" },
}

return M
