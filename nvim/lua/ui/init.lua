return {

  {
    "folke/twilight.nvim",
    keys = require("keymaps").twilight,
  },

  {
    "3rd/image.nvim",
    enabled = true,
    config = function()
      require("image").setup {
        backend = "kitty",
        processor = "magick_rock",
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = true,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { "markdown", "mdx", "quarto" },
          },
        },
        max_width = 80,
        max_height = 20,
        max_width_window_percentage = 50,
        max_height_window_percentage = 40,
        window_overlap_clear_enabled = true,
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif" },
        editor_only_render_when_focused = true,
        tmux_show_only_in_active_window = true,
      }
    end,
  },

  { "3rd/diagram.nvim", ft = { "markdown" } },
  {
    "folke/zen-mode.nvim",
    keys = require("keymaps").zen_mode,
  },

  {
    -- Helps to hide data in envs
    "laytan/cloak.nvim",
    lazy = false,
    opts = {
      enabled = true,
      cloak_character = "*",
      cloak_telescope = true,
      highlight_group = "Comment",
      patterns = {
        {
          -- Match any file starting with ".env".
          -- This can be a table to match multiple file patterns.
          file_pattern = {
            ".env*",
            "wrangler.toml",
            ".dev.vars",
          },
          -- Match an equals sign and any character after it.
          -- This can also be a table of patterns to cloak,
          -- example: cloak_pattern = { ":.+", "-.+" } for yaml files.
          cloak_pattern = "=.+",
          replace = nil,
        },
      },
    },
    keys = require("keymaps").cloak,
  },
}
