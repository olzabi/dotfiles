local M = {}

M.config = function()
      require("persistence").setup(opts)

      vim.api.nvim_create_user_command("PersistenceLoad", function()
        require("persistence").load()
      end, {})

      vim.api.nvim_create_user_command("PersistenceSelect", function()
        require("persistence").select()
      end, {})

      vim.opt.sessionoptions = "buffers"

      local group = vim.api.nvim_create_augroup("user-persistence", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "PersistenceLoadPost",
        callback = function()
          vim.cmd("Neotree show")
        end,
      })
end

return M
