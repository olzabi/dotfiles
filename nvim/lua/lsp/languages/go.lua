return {

  {
    -- WARN: not updated since added
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "theHamsta/nvim-dap-virtual-text",
    },
    event = "CmdlineEnter",
    build = ':lua require("go.install").update_all_sync()',
    config = function()
      require("go").setup({
        lsp_cfg = true,
      })
    end,
    keys = {
      { mode = "n", "<leader>cGcm", "<cmd>GoCmt<cr>", desc = "Add comment" },

      { mode = "n", "<leader>cGta", "<cmd>GoAddTag<cr>", desc = "Add tags" },
      { mode = "n", "<leader>cGtr", "<cmd>GoRmTag<cr>", desc = "Remove tags" },
      { mode = "n", "<leader>cGte", "<cmd>GoTest<cr>", desc = "Run tests" },

      { mode = "n", "<leader>cGat", "<cmd>GoAlt!<cr>", desc = "Toggle test" },
      { mode = "n", "<leader>cGas", "<cmd>GoAltS!<cr>", desc = "Toggle split test" },
      { mode = "n", "<leader>cGav", "<cmd>GoAltV!<cr>", desc = "Toggle vsplit test" },
    },
  },
}
