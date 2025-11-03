return function()
  require("image").setup({
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
  })
end
