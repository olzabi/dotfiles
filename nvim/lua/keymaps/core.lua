local map = vim.keymap
local nmap = require("keymaps.utils").nmap

-- join lines focus
nmap("J", "mzJ`z", "Join lines and keep in the same place the cursor")

-- better up/down
map.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map.set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map.set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
nmap("<C-h>", "<C-w>h", "Go to Left Window")
nmap("<C-j>", "<C-w>j", "Go to Lower Window")
nmap("<C-k>", "<C-w>k", "Go to Upper Window")
nmap("<C-l>", "<C-w>l", "Go to Right Window")

-- Resize window using <ctrl> arrow keys
nmap("<C-Up>", "<cmd>resize +2<cr>", "Increase Window Height")
nmap("<C-Down>", "<cmd>resize -2<cr>", "Decrease Window Height")
nmap("<C-Left>", "<cmd>vertical resize -2<cr>", "Decrease Window Width")
nmap("<C-Right>", "<cmd>vertical resize +2<cr>", "Increase Window Width")

-- Move Lines
nmap("<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", "Move Down")
nmap("<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", "Move Up")
map.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map.set("v", "<A-j>", "<cmd><C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map.set("v", "<A-k>", "<cmd><C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers
nmap("<S-h>", "<cmd>bprevious<cr>", "Prev Buffer")
nmap("<S-l>", "<cmd>bnext<cr>", "Next Buffer")
nmap("<leader>bb", "<cmd>e #<cr>", "Switch to Other Buffer") -- save file

-- Save / quit
map.set({ "x", "n", "s" }, "<leader>w", "<cmd>w<cr><esc>", { desc = "Save File", silent = true })
nmap("<leader>q", "<cmd>q<cr>", "Exit vim")

-- windows
nmap("<leader>w-", "<C-W>s", "Split Window Below")
nmap("<leader>w|", "<C-W>v", "Split Window Right")
nmap("<leader>wd", "<C-W>c", "Delete Window")

map.set("x", "p", [["_dP]])

--- redo
nmap("U", "<C-r>")

-- Increment/decrement
nmap("+", "<C-a>")
nmap("-", "<C-x>")

-- better indenting
map.set({ "v", "x" }, ">", ">gv")
map.set({ "v", "x" }, "<", "<gv")

-- Delete a word backwards
nmap("dw", 'vb"_d')

-- Select all
nmap("<C-a>", "gg<S-v>G")

-- clear highlights
nmap("<Esc>", "<cmd>noh<cr>")

-- Replace word under cursor
nmap("<leader>j", "*``cgn")

--Search for visually selected word
map.set("v", "//", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])

nmap("<leader>rc", function()
  vim.cmd("luafile %")
  vim.notify("Reloaded Successfully", vim.log.levels.INFO, { title = "Neovim Config" })
end, "Reload Neovim (init.lua)")
