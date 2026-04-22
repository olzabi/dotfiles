local map = vim.keymap.set
local nmap = require("keymaps.utils").nmap

-- join lines focus
nmap("J", "mzJ`z", "Join lines and keep in the same place the cursor")

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

nmap("<C-h>", "<C-w>h", "Go to Left Window")
nmap("<C-j>", "<C-w>j", "Go to Lower Window")
nmap("<C-k>", "<C-w>k", "Go to Upper Window")
nmap("<C-l>", "<C-w>l", "Go to Right Window")
nmap("<C-Up>", "<cmd>resize +2<cr>", "Increase Window Height")
nmap("<C-Down>", "<cmd>resize -2<cr>", "Decrease Window Height")
nmap("<C-Left>", "<cmd>vertical resize -2<cr>", "Decrease Window Width")
nmap("<C-Right>", "<cmd>vertical resize +2<cr>", "Increase Window Width")
nmap("<leader>w-", "<C-W>s", "Split Window Below")
nmap("<leader>w|", "<C-W>v", "Split Window Right")
nmap("<leader>wd", "<C-W>c", "Delete Window")

-- Move Lines
nmap("<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", "Move Down")
nmap("<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", "Move Up")
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", "<cmd><C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", "<cmd><C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers
nmap("<S-h>", "<cmd>bprevious<cr>", "Prev Buffer")
nmap("<S-l>", "<cmd>bnext<cr>", "Next Buffer")
nmap("<leader>bb", "<cmd>e #<cr>", "Switch to Other Buffer") -- save file

-- Save / quit
map({ "x", "n", "s" }, "<leader>w", "<cmd>w<cr><esc>", { desc = "Save File", silent = true })
nmap("<leader>q", "<cmd>q<cr>", "Exit vim")

map("x", "p", [["_dP]])
nmap("U", "<C-r>")
nmap("+", "<C-a>")
nmap("-", "<C-x>")
map({ "v", "x" }, ">", ">gv")
map({ "v", "x" }, "<", "<gv")
nmap("dw", 'vb"_d')
nmap("<C-a>", "gg<S-v>G")
nmap("<Esc>", "<cmd>noh<cr>")
nmap("<leader>j", "*``cgn")
map("v", "//", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])

nmap("<leader>rc", function()
  vim.cmd "luafile %"
  vim.notify("Reloaded Successfully", vim.log.levels.INFO, { title = "Neovim Config" })
end, "Reload Neovim (init.lua)")
