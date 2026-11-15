-- stylua: ignore start
local map = vim.keymap.set
local nmap = function(keys, func, desc, buf)
  if desc then desc = desc end
  if buf then buf = buf end
  vim.keymap.set("n", keys, func, { noremap = true, silent = true, desc = desc, buffer = buf })
end

-- better up/down
map({ "n", "x" }, "j",      "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k",      "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Up>",   "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
nmap("<C-Up>",     "<cmd>resize +2<cr>",          "Increase Window Height")
nmap("<C-Down>",   "<cmd>resize -2<cr>",          "Decrease Window Height")
nmap("<C-Left>",   "<cmd>vertical resize -2<cr>", "Decrease Window Width")
nmap("<C-Right>",  "<cmd>vertical resize +2<cr>", "Increase Window Width")
nmap("<leader>w-", "<C-W>s",                      "Split Window Below")
nmap("<leader>w|", "<C-W>v",                      "Split Window Right")
nmap("<leader>wd", "<C-W>c",                      "Delete Window")

-- buffers
nmap("<S-h>", "<cmd>bprevious<cr>", "Prev Buffer")
nmap("<S-l>", "<cmd>bnext<cr>", "Next Buffer")

-- Move Lines
nmap("<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", "Move Down")
nmap("<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", "Move Up")
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", "<cmd>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", "<cmd>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

map("x", "p", [["_dP]])
nmap("U", "<C-r>")
nmap("+", "<C-a>")
nmap("-", "<C-x>")
map({ "v", "x" }, ">", ">gv")
map({ "v", "x" }, "<", "<gv")
nmap("dw", 'vb"_d')
nmap("<C-a>", "gg<S-v>G")
nmap("<Esc>", "<cmd>noh<cr>")
--nmap("<leader>j", "*``cgn")
map("v", "//", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])

nmap("<leader>w", "<cmd>w<cr><esc>", "Save File")
nmap("<leader>q", "<cmd>q<cr>", "Exit vim")
nmap("<leader>rs", "<cmd>restart<cr>", "Reload Neovim (init.lua)")
-- stylua: ignore end
