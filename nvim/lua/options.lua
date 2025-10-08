local opt = vim.opt
local g = vim.g

g.lazyvim_php_lsp = "intelephense"

g.mapleader = " "
g.maplocalleader = "\\"

opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

g.autoformat = true
g.snacks_animate = true
g.ai_cmp = true
g.lazyvim_picker = "auto"
g.lazyvim_cmp = "auto"

g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
g.root_lsp_ignore = { "copilot" }
g.deprecation_warnings = false
-- Show the current document symbols location from Trouble in lualine
-- You can disable this for a buffer by setting `vim.b.trouble_lualine = false`
g.trouble_lualine = true

opt.title = true
opt.autoindent = true
opt.autowrite = true

opt.backup = true
opt.backupskip = { "/tmp/" }
opt.swapfile = false
opt.directory = vim.fn.stdpath("data") .. "/swp//"

opt.writebackup = true
opt.backupdir = vim.fn.stdpath("data") .. "/backup//"

vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo//"

-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically. Requires Neovim >= 0.10.0
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
opt.confirm = true -- Confirm to save changes before exiting modified buffer

opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs

opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true -- Ignore case
opt.inccommand = "nosplit" -- preview incremental substitute

opt.jumpoptions = "view"
opt.laststatus = 3 -- global statusline
opt.linebreak = true -- Wrap lines at convenient points
opt.list = true -- Show some invisible characters (tabs...
opt.mouse = "a" -- Enable mouse mode

opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.ruler = false -- Disable the default ruler

-- opt.scrolloff = 999 -- Centered Lines of context
opt.scrolloff = 8 -- Lines of context
opt.sidescrolloff = 8 -- Columns of context
opt.shiftwidth = 2 -- Size of an indent
opt.tabstop = 2 -- Number of spaces tabs count for

opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
opt.shiftround = true -- Round indent
opt.shortmess:append({ W = true, I = true, c = true, C = true })

opt.showmode = false -- Dont show mode since we have a statusline
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time

opt.smartcase = true -- Don't ignore case with capitals
opt.smartindent = true -- Insert indents automatically
opt.smarttab = true

opt.spelllang = { "en" }
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "cursor"

opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]

opt.termguicolors = true -- True color support
opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
opt.undofile = true
opt.undolevels = 10000

opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width

opt.wrap = false
opt.shell = "zsh"

opt.hlsearch = true
opt.path:append({ "**" })
opt.wildignore:append({ "/node_modules/" })

if vim.fn.has("nvim-0.10") == 1 then
  opt.smoothscroll = true
  opt.foldmethod = "expr"
  opt.foldtext = ""
else
  opt.foldmethod = "indent"
end

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- Add asterisks in block comments
vim.opt.formatoptions:append({ "r" })

--- !
-- vim.o.clipboard = 'unnamedplus'                      -- Sync clipboard between OS and Neovim.
-- vim.o.breakindent = true                             -- Enable break indent
-- vim.o.undofile = true                                -- Save undo history
-- vim.o.ignorecase = true                              -- Case-insensitive searching UNLESS \C or capital in search
-- vim.o.smartcase = true                               -- smart case
-- vim.wo.signcolumn = 'yes'                            -- Keep signcolumn on by default
-- vim.o.updatetime = 250                               -- Decrease update time
-- vim.o.timeoutlen = 300                               -- time to wait for a mapped sequence to complete (in milliseconds)
-- vim.o.backup = false                                 -- creates a backup file
-- vim.o.writebackup = false                            -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
-- vim.o.completeopt = 'menuone,noselect'               -- Set completeopt to have a better completion experience
-- vim.opt.termguicolors = true                         -- set termguicolors to enable highlight groups
-- vim.o.whichwrap = 'bs<>[]hl'                         -- which "horizontal" keys are allowed to travel to prev/next line
-- vim.o.wrap = false                                   -- display lines as one long line
-- vim.o.linebreak = true                               -- companion to wrap don't split words
-- vim.o.scrolloff = 4                                  -- minimal number of screen lines to keep above and below the cursor
-- vim.o.sidescrolloff = 8                              -- minimal number of screen columns either side of cursor if wrap is `false`
-- vim.o.relativenumber = true                          -- set relative numbered lines
-- vim.o.numberwidth = 4                                -- set number column width to 2 {default 4}
-- vim.o.shiftwidth = 4                                 -- the number of spaces inserted for each indentation
-- vim.o.tabstop = 4                                    -- insert n spaces for a tab
-- vim.o.softtabstop = 4                                -- Number of spaces that a tab counts for while performing editing operations
-- vim.o.expandtab = true                               -- convert tabs to spaces
-- vim.o.cursorline = false                             -- highlight the current line
-- vim.o.splitbelow = true                              -- force all horizontal splits to go below current window
-- vim.o.splitright = true                              -- force all vertical splits to go to the right of current window
-- vim.o.swapfile = false                               -- creates a swapfile
-- vim.o.smartindent = true                             -- make indenting smarter again
-- vim.o.showmode = false                               -- we don't need to see things like -- INSERT -- anymore
-- vim.o.showtabline = 2                                -- always show tabs
-- vim.o.backspace = 'indent,eol,start'                 -- allow backspace on
-- vim.o.pumheight = 10                                 -- pop up menu height
-- vim.o.conceallevel = 0                               -- so that `` is visible in markdown files
-- vim.o.fileencoding = 'utf-8'                         -- the encoding written to a file
-- vim.o.cmdheight = 1                                  -- more space in the neovim command line for displaying messages
-- vim.o.autoindent = true                              -- copy indent from current line when starting new one
-- vim.opt.shortmess:append 'c'                         -- don't give |ins-completion-menu| messages
-- vim.opt.iskeyword:append '-'                         -- hyphenated words recognized by searches
-- vim.opt.formatoptions:remove { 'c', 'r', 'o' }       -- don't insert the current comment leader automatically for auto-wrapping comments using 'textwidth', hitting <Enter> in insert mode, or hitting 'o' or 'O' in normal mode.
-- vim.opt.runtimepath:remove '/usr/share/vim/vimfiles' -- separate vim plugins from neovim in case vim still in use
