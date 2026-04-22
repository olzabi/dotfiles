return {

  {
    "folke/twilight.nvim",
    keys = require("keymaps").twilight,
  },

  {
    "3rd/image.nvim",
    dependencies = { "luarocks.nvim" },
    enabled = true,
    config = function()
      require("image").setup {
        backend = "kitty",
        -- backend = "viu",
        -- backend = "ueberzug",
        processor = "magick_rock",
        -- hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.svg" },
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
          },
          neorg = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
          },
        },
        -- max_width = nil,
        -- max_height = nil,
        -- max_width_window_percentage = math.huge,
        -- max_height_window_percentage = math.huge,
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
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
