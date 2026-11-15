return {
  "kdheepak/monochrome.nvim",
  "slugbyte/lackluster.nvim",
  "robertmeta/nofrils",

  {
    "aliqyan-21/darkvoid.nvim",
    lazy = false,
    config = function()
      require("darkvoid").setup {
        glow = true,
        transparent = true,
        colors = {
          plugins = { lualine = true },
        },
      }

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
    end,
  },
}
