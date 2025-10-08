return {
  {
    -- Better packages info for npm/yarn/pnpm
    "vuki656/package-info.nvim",
    opts = {
      package_manager = "npm",
      autostart = true,
    },
    config = function()
      require("package-info").setup()
    end,
    ft = { "npm", "js" },
  },

  {
    "saecki/crates.nvim",
    event = "BufRead Cargo.toml",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
    ft = { "rust", "Cargo" },
  },

  {
    "gennaro-tedesco/nvim-jqx",
    enabled = true,
    event = { "BufReadPost" },
    ft = { "json", "yaml" },
  },

  {
    "Redoxahmii/json-to-types.nvim",
    build = "sh install.sh npm", -- Replace `npm` with your preferred package manager (e.g., yarn, pnpm).
    ft = "json",
    keys = {
      {
        "<leader>cjU",
        "<CMD>ConvertJSONtoLang typescript<CR>",
        desc = "Convert JSON to TS",
      },
      {
        "<leader>cjt",
        "<CMD>ConvertJSONtoLangBuffer typescript<CR>",
        desc = "Convert JSON to TS Buffer",
      },
    },
  },

  {
    "cuducos/yaml.nvim",
    ft = { "yaml", "yml" },
  },
}
