return {
  {
    "folke/lazydev.nvim",
    cmd = "LazyDev",
    lazy = false,
    dependencies = { { "justinsgithub/wezterm-types", ft = { "wezterm" } } },
    opts = { library = require("utils.packages").lazy_dev_libs },
    ft = "lua",
  },
}
