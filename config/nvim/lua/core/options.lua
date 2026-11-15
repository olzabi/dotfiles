local opt = vim.opt
local g = vim.g

g.mapleader = " "
g.maplocalleader = "\\"

-- general
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.scrolloff = 16
opt.sidescrolloff = 8

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true
opt.shiftround = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true

-- Visual settings
opt.termguicolors = true
opt.signcolumn = "yes"
opt.showmatch = true
opt.matchtime = 2
opt.cmdheight = 1
opt.showmode = false
opt.pumheight = 10
opt.pumblend = 10
opt.pumborder = "rounded" -- 0.12: native popup (cmdline completion) gets a border too
opt.winblend = 0
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 2
opt.confirm = true
opt.concealcursor = ""
opt.synmaxcol = 300
opt.ruler = false
opt.virtualedit = "block"
opt.winminwidth = 5

-- File handling
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undodir = vim.fn.stdpath("data") .. "/undo//"
opt.undolevels = 10000
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = vim.g.vscode and 1000 or 300
opt.ttimeoutlen = 0
opt.autoread = true

-- Behavior settings
opt.hidden = true
opt.errorbells = false
opt.backspace = "indent,eol,start"
opt.autochdir = false
opt.iskeyword:append("-")
opt.path:append("**")
opt.selection = "inclusive"
opt.mouse = "a"
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
opt.modifiable = true
opt.encoding = "UTF-8"

-- Folding settings
opt.smoothscroll = true
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldmethod = "expr"
opt.foldtext = "" -- folded line keeps its syntax highlighting
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.fillchars = { foldopen = "", foldclose = "", fold = " ", foldsep = " ", diff = "╱", eob = " " }
-- opt.formatoptions = "jcroqlnt" -- tcqj
opt.formatoptions = "jqlnt"
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"

-- Split behavior
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"
opt.jumpoptions:append "view" -- <C-o>/<C-i> restore the scroll position too, not just the line

-- Command-line completion
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.wildignore:append({ "*.o", "*.obj", "*.pyc", "*.class", "*.jar", "/node_modules/" })

-- Better diff options
opt.diffopt:append("linematch:60,inline:word") -- 0.12: word-level changed text, adjacent blocks merged

-- Performance improvements
opt.redrawtime = 10000
opt.maxmempattern = 20000

g.markdown_recommended_style = 0

opt.spelllang = { "en", "uk", "ru" }
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "winpos", "help", "globals", "skiprtp", "folds" }
opt.shell = "zsh"

opt.inccommand = "split"

g.loaded_perl_provider = 0
