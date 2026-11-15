return {
  -- vim-tmux-navigator dropped (herdr, not tmux): same keys, nvim windows only
  {
    "window-nav",
    virtual = true,
    keys = {
      -- stylua: ignore start
      { "<c-h>", "<c-w>h", desc = "Window left" },
      { "<c-j>", "<c-w>j", desc = "Window down" },
      { "<c-k>", "<c-w>k", desc = "Window up" },
      { "<c-l>", "<c-w>l", desc = "Window right" },
      -- stylua: ignore end
    },
  },

  {
    "chrisgrieser/nvim-spider",
    config = function()
      require("spider").setup({
        skipInsignificantPunctuation = true,
        subwordMovement = true,
        customPatterns = {},
      })

      for _, key in ipairs { "w", "e", "b", "ge" } do
        vim.keymap.set({ "n", "o", "x" }, key, function() require("spider").motion(key) end, { desc = "Spider-" .. key })
      end
    end,
  },
}
