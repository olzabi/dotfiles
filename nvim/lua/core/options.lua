local opt = vim.opt
local g = vim.g

g.mapleader = " "
g.maplocalleader = "\\"

g.autoformat = true
g.snacks_animate = true
g.ai_cmp = true
g.lazyvim_picker = "auto"
g.lazyvim_cmp = "auto"
g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
g.root_lsp_ignore = { "copilot" }
g.deprecation_warnings = false
g.trouble_lualine = true
g.markdown_recommended_style = 0
g.loaded_perl_provider  = 0
g.loaded_ruby_provider  = 0

opt.swapfile = false -- no swap files
opt.backup = true
opt.backupdir = vim.fn.stdpath("data") .. "/backup//"
opt.backupskip = { "/tmp/*" }
opt.writebackup = true
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo//"
opt.undolevels = 10000

opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"

opt.expandtab = true -- spaces instead of tabs
opt.shiftwidth = 2
opt.tabstop = 2
opt.shiftround = true -- round indent to shiftwidth
opt.smartindent = true -- better autoindent for code

opt.formatoptions = "jqlnt"
opt.virtualedit = "block" -- free cursor in visual block mode          [IDEA]

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "nosplit" -- live preview for :s and similar
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

opt.title = true
opt.number = true -- [IDEA]
opt.relativenumber = true -- [IDEA]
opt.cursorline = true
opt.signcolumn = "yes" -- always show; prevents layout shift
opt.showmode = false -- statusline shows mode
opt.ruler = false -- statusline covers this
opt.list = true -- show invisible chars
opt.linebreak = true -- wrap at word boundaries
opt.wrap = false -- no soft-wrap by default                      [IDEA]
opt.scrolloff = 16
opt.sidescrolloff = 8
opt.pumheight = 10
opt.pumblend = 10
opt.termguicolors = true
opt.laststatus = 3 -- single global statusline
opt.conceallevel = 2 -- hide * markup for bold/italic

opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "cursor"
opt.winminwidth = 5

opt.completeopt = "menu,menuone,noselect"

opt.confirm = true -- ask instead of error on unsaved changes
opt.autowrite = true -- write before :make, :next, etc.
opt.updatetime = 200 -- faster CursorHold, faster sign updates
opt.timeoutlen = vim.g.vscode and 1000 or 300 -- which-key trigger speed
opt.jumpoptions = "view"
opt.spelllang = { "en" }
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.wildmode = "longest:full,full"
opt.shell = "zsh"
opt.path:append({ "**" })
opt.wildignore:append({ "/node_modules/" })
