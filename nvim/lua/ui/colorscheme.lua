return {
      "kdheepak/monochrome.nvim",
  "slugbyte/lackluster.nvim",
  "robertmeta/nofrils",


  {
    "aliqyan-21/darkvoid.nvim",
    lazy = false,
    config = function()
      vim.api.nvim_set_hl(0, "TabLine", { reverse = false })
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.schedule(function()
            vim.api.nvim_set_hl(0, "TabLine", { reverse = false })
          end)
        end,
      })

      vim.cmd [[
      colorscheme darkvoid
      ]]

      require("darkvoid").setup {
        glow = true,
        colors = {
          plugins = {
            lualine = true,
          },
        },
      }
    end,
    -- NOTE: TabLine is temporary fix after switching from nvim 0.10 to 0.11
  },
}
