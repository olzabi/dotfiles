return {
  {
    "fatih/vim-go",
    build = ":GoUpdateBinaries",
  },

  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "theHamsta/nvim-dap-virtual-text",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    event = "CmdlineEnter",
    build = ':lua require("go.install").update_all_sync()',
    config = function()
      require("go").setup({
        lsp_cfg = true,
      })
    end,
    keys = {
      { mode = "n", "<leader>gcm", "<cmd>GoCmt<cr>", desc = "Add comment" },
      { mode = "n", "<leader>gta", "<cmd>GoAddTag<cr>", desc = "Add tags" },
      { mode = "n", "<leader>gtr", "<cmd>GoRmTag<cr>", desc = "Remove tags" },
      { mode = "n", "<leader>gte", "<cmd>GoTest<cr>", desc = "Run tests" },
      { mode = "n", "<leader>grn", vim.lsp.buf.rename, desc = "[r]e[n]ame" },
      { mode = "n", "<leader>gre", vim.lsp.buf.references, desc = "[r][e]ferences" },
      {
        mode = "n",
        "<leader>gre",
        "<Cmd>Fzf lsp_references<CR>",
        desc = "references",
      },
      { mode = "n", "<leader>gat", "<cmd>GoAlt!<cr>", desc = "Toggle test" },
      { mode = "n", "<leader>gas", "<cmd>GoAltS!<cr>", desc = "Toggle split test" },
      { mode = "n", "<leader>gav", "<cmd>GoAltV!<cr>", desc = "Toggle vsplit test" },
    },
  },
}
