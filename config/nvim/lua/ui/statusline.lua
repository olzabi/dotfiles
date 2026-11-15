return {
  {
    "nvim-lualine/lualine.nvim",
    event = { "BufReadPost", "BufAdd", "BufNewFile" },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "bwpge/lualine-pretty-path",
    },
    opts = {
      extensions = {
        "lazy",
        "mason",
        "fugitive",
        "nvim-dap-ui",
        "quickfix",
        "trouble",
      },
      -- cdate / ctime / conform-lualine-status / lsp_client_name / navic were never installed components.
      -- 0.12 exposes the same data natively: LSP & other progress, and LSP client names via "lsp_status".
      sections = {
        lualine_x = {
          function() return vim.ui.progress_status() end,
          "lsp_status",
          "encoding",
          "fileformat",
          "filetype",
        },
      },
      inactive_sections = {
        lualine_c = { "pretty_path" },
        lualine_x = { "location" },
      },
    },
  },
}
