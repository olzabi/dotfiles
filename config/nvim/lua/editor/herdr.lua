-- herdr-nvim (Herdr app sidebar) puts its runtime on rtp; only then set it up.
-- Prefix <leader>m: <leader>a is treesitter's swap-parameter (editor/treesitter.lua).
return {
  {
    "herdr-nvim",
    virtual = true,
    cond = function() return #vim.api.nvim_get_runtime_file("lua/herdr-nvim/init.lua", false) > 0 end,
    config = function() require("herdr-nvim").setup { prefix = "<leader>m" } end,
  },
}
