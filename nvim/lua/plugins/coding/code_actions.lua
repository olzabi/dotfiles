return {
  {
    -- TODO:
    "ckolkey/ts-node-action",
    config = function()
      vim.keymap.set({ "n" }, "F", require("ts-node-action").node_action, { desc = "Trigger Node Action" })
    end,
  },

  {
    "folke/ts-comments.nvim",
    enabled = false
  }, -- "gc" to comment visual regions/lines


}
