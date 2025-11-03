---@type vim.lsp.Config
return {
	cmd = { "bash-language-server", "start" },
	filetypes = { "bash", "sh", "zsh" },
	root_markers = { ".git" },
  single_file_support = true,
	settings = {
		bashIde = {
			globPattern = "*@(.sh|.inc|.bash|.command)",
		},
	},
}
