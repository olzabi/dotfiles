local obisidan_workspaces = {
  {
    name = "notes",
    path = "~/vaults/notes",
  },
  {
    name = "work",
    path = "~/vaults/work",
  },
}

return {
  {
    "epwalsh/obsidian.nvim",
    opts = {
      ui = { enable = false },
      workspaces = obisidan_workspaces,
    },
  },

  {
    -- Known limitations: it doesn't work around buffer preview (telescope, neo-tree)
    -- or the issue related that wezterm does not support rendering images yet
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = require("configs.markdown").dependencies,
    opts = require("configs.markdown").opts,
  },
}
