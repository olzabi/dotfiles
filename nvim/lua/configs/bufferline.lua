local M = {}

local opts = {
  options = {
    themable = true,
    hover = { enabled = true, reveal = { "close" }, delay = 50 },
    offsets = {
      { filetype = "NvimTree", text = "File Explorer", highlight = "Directory", text_align = "left" },
      { filetype = "NvimTree", highlight = "NvimTreeNormal" },
      { filetype = "Outline", text = "Symbols Outline", highlight = "TSType", text_align = "left" },
      { filetype = "neo-tree", text = "Explorer", highlight = "Directory", text_align = "center", separator = true },
      { filetype = "dbui", text = "Database Manager", text_align = "center", separator = true },
    },

    show_buffer_close_icons = false,
  },
}

M.config = function()
  local bufferline = require("bufferline")
  bufferline.setup(opts)

  vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
    callback = function()
      vim.schedule(function()
        pcall(nvim_bufferline)
      end)
    end,
  })
end

return M
