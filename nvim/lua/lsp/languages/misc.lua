return {
  {
    "saecki/crates.nvim",
    event = "BufRead Cargo.toml",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
    ft = { "rust", "Cargo" },
  },

  {
    "cuducos/yaml.nvim",
    ft = { "yaml", "yml" },
  },

  {
    "codethread/qmk.nvim",
    opts = {
      name = "corne",
      variant = "zmk",
      layout = {
        "x x x x x x _ x x x x x x",
        "x x x x x x _ x x x x x x",
        "x x x x x x _ x x x x x x",
        "_ _ _ x x x _ x x x _ _ _",
      },
    },
  },

  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    opts = {},
    keys = require "keymaps",
  },

  {
    "vidocqh/data-viewer.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "kkharji/sqlite.lua", -- Optional, sqlite support
    },
  },

  {
    "hat0uma/csvview.nvim",
    opts = {
      parser = { comments = { "#", "//" } },
      keymaps = {
        -- Text objects for selecting fields
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        -- Excel-like navigation:
        -- Use <Tab> and <S-Tab> to move horizontally between fields.
        -- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
        -- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
  },

  {
    -- Known limitations: it doesn't work around buffer preview (telescope, neo-tree)
    -- or the issue related that wezterm does not support rendering images yet
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-mini/mini.nvim",
      "nvim-tree/nvim-web-devicons",
      { "3rd/image.nvim", lazy = true, opts = {} },
      -- { "OXY2DEV/markview.nvim", priority = 1000},
      -- {
      --           "lukas-reineke/headlines.nvim",
      --   opts = { markdown = {disable = true}}
      --
      -- }
    },
    opts = {
      enabled = true,
      render_modes = { "n", "v", "i", "c" },
      latex = { enabled = false },
      bullet = {
        enabled = true,
      },
      checkbox = {
        enabled = true,
        position = "inline",
        unchecked = {
          raw = "[-]",
          icon = "   󰄱 ",
          highlight = "RenderMarkdownUnchecked",
          scope_highlight = nil,
        },
        checked = {
          -- raw = "[x]",
          icon = "   󰱒 ",
          highlight = "RenderMarkdownChecked",
          scope_highlight = nil,
        },
        custom = {
          doing = {
            raw = "[_]",
            rendered = "󰄮",
            highlight = "RenderMarkdownDoing",
          },
          wontdo = {
            raw = "[~]",
            rendered = "󰅗",
            highlight = "RenderMarkdownWontdo",
          },
        },
      },
      html = { enabled = true },
      -- css = { enabled = true },
      file_types = { "markdown", "FzfPreview", "Avante" },
    },
  },
}
