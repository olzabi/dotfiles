return {
  {
    "bennypowers/nvim-regexplainer",
    config = function()
      require("regexplainer").setup()
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "MunifTanjim/nui.nvim",
    },
  },

  {
    "Redoxahmii/json-to-types.nvim",
    build = "sh install.sh npm",
    keys = {
      { "<leader>cCU", "<CMD>ConvertJSONtoLang typescript<CR>", desc = "Convert JSON to TS" },
      { "<leader>cCt", "<CMD>ConvertJSONtoLangBuffer typescript<CR>", desc = "Convert JSON to TS Buffer" },
    },
  },

  {
    "vuki656/package-info.nvim",
    event = "BufReadPre package.json",
    opts = {
      package_manager = "npm",
      autostart = true,
    },
    config = function(_, opts)
      local package_info = require("package-info")
      package_info.setup(opts)

      -- vim.api.nvim_create_autocmd("BufReadPost", {
      --   pattern = "package.json",
      --   callback = function()
      --     local buffer = vim.fn.bufnr()
      --
      --     vim.keymap.set("n", "<leader>pp", package_info.toggle, { desc = "Package Info", buffer = buffer })
      --     vim.keymap.set("n", "<leader>pd", package_info.delete, { desc = "Delete package", buffer = buffer })
      --     vim.keymap.set("n", "<leader>pc", package_info.change_version, { desc = "Change version", buffer = buffer })
      --   end,
      --   group = vim.api.nvim_create_augroup("PackageInfoMappings", { clear = true }),
      -- })
    end,
    keys = {
      { "<leader>us", "<cmd>lua require('package-info').show({ force = true })<cr>" },
    },
  },
}
