return {}

-- https://github.com/svermeulen/vim-easyclip
-- https://github.com/takac/vim-hardtime
-- https://github.com/terryma/vim-expand-region
-- https://github.com/guns/vim-sexp
-- https://github.com/tpope/vim-unimpaired
-- https://github.com/andrewferrier/wrapping.nvim
-- https://github.com/amitds1997/remote-nvim.nvim
-- https://github.com/albingroen/quick.nvim
-- https://github.com/xeluxee/competitest.nvim
--

-- https://github.com/piersolenski/wtf.nvim -- TODO:

--  { "tpope/vim-repeat",       lazy = false },
--  { "tpope/vim-speeddating",  lazy = false },
--  {    "airblade/vim-rooter"},

-- {
--   -- TODO:
--   "https://codeberg.org/esensar/nvim-dev-container",
--   dependencies = "nvim-treesitter/nvim-treesitter",
-- },

-- {
--   "RishabhRD/nvim-lsputils",
--   dependencies = { "RishabhRD/popfix" },
--   config = function()
--     vim.g.lsp_utils_location_opts = { mode = "editor" }
--     vim.g.lsp_utils_codeaction_opts = { mode = "editor" }
--     vim.lsp.handlers["textDocument/codeAction"] = require("lsputil.codeAction").code_action_handler
--     vim.lsp.handlers["textDocument/references"] = require("lsputil.locations").references_handler
--     vim.lsp.handlers["textDocument/definition"] = require("lsputil.locations").definition_handler
--     vim.lsp.handlers["textDocument/declaration"] = require("lsputil.locations").declaration_handler
--     vim.lsp.handlers["textDocument/typeDefinition"] = require("lsputil.locations").typeDefinition_handler
--     vim.lsp.handlers["textDocument/implementation"] = require("lsputil.locations").implementation_handler
--     vim.lsp.handlers["textDocument/documentSymbol"] = require("lsputil.symbols").document_handler
--     vim.lsp.handlers["workspace/symbol"] = require("lsputil.symbols").workspace_handler
--   end,
-- },
