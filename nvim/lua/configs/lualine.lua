return {
  extensions = {
    "lazy",
    "mason",
    "fugitive",
    "nvim-dap-ui",
    "quickfix",
    "trouble",
  },
  sections = {
    lualine_x = {
      "encoding",
      "fileformat",
      "filetype",
      "cdate",
      "ctime",
      "conform-lualine-status",
      "lsp_client_name",
    },
  },
  winbar = {
    lualine_c = {
      {
        "navic",
        color_correction = nil,
        -- navic_opts = nil,
        -- padding = { left = 1, right = 0 },
      },
    },
  },
  inactive_sections = {
    lualine_c = { "pretty_path" },
    lualine_x = { "location" },
  },
}
