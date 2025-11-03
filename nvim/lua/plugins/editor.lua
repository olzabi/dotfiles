return {
  { "zeioth/garbage-day.nvim" },
  { "tpope/vim-sleuth", event = "BufReadPre" }, -- auto tab space
  { "b0o/SchemaStore.nvim", lazy = false, version = false }, -- json, yaml schemas

  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    opts = {},
    keys = require("keymaps"),
  },

  {
    "mikavilpas/yazi.nvim",
    keys = require("keymaps").yazi,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      "3rd/image.nvim",
    },
    opts = require("configs.neo-tree").opts,
    keys = require("keymaps").neo_tree,
  },

  {
    -- color highlighter for hexcodes (e.g. #fff)
    -- NOTE: config = true, opts = {} does not initalize plugin
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end,
  },

  {
    -- TODO: sessions manager
    "folke/persistence.nvim",
    event = "BufReadPre",
    lazy = false,
    config = require("configs.persistence").config,
    keys = require("keymaps").persistence,
  },

  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = require("configs.telescope").dependencies,
    config = require("configs.telescope").config,
    keys = require("keymaps").telescope,
  },

  {
    "rachartier/tiny-code-action.nvim",
    event = "LspAttach",
    keymaps = {
      {
        { "n", "x" },
        "..",
        function()
          require("tiny-code-action").code_action()
        end,
        { noremap = true, silent = true },
      },
    },
  },

  {
    -- TODO:
    "Wansmer/symbol-usage.nvim",
    -- event = "LspAttach", -- need run before LspAttach if you use nvim 0.9. On 0.10 use 'LspAttach'
    enabled = false,
    config = require("configs.symbol-usage").config,
    keymaps = require("keymaps").symbol_usage(),
  },

  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },

  {
    -- TODO:
    "numToStr/Comment.nvim",
    event = { "CursorHold" },
    config = function()
      require("Comment").setup()
    end,
  },

  {
    "folke/todo-comments.nvim",
    lazy = false,
    enabled = false,
    event = { "CursorHold", "CursorHoldI" },
    cmd = { "TodoTrouble", "TodoTelescope" },
    opts = require("configs.todo-comments").opts,
    keys = require("keymaps").todo_comments,
  },

  {
    -- TODO: integrate on neo-tree
    "simrat39/symbols-outline.nvim",
    keys = require("keymaps").symbols_outline,
    cmd = "SymbolsOutline",
    opts = { position = "right" },
  },

  {
    "smoka7/multicursors.nvim",
    dependencies = "Cathyprime/hydra.nvim",
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    keys = require("keymaps").multicursors,
    config = true,
  },

  {
    -- Folding
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    requires = "kevinhwang91/promise-async",
    config = require("configs.ufo").config,
  },

  {
    "akinsho/bufferline.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    event = { "BufReadPre", "BufAdd", "BufNewFile" },
    opts = require("configs.bufferline").opts,
    config = require("configs.bufferline").config,
    keys = require("keymaps").bufferline,
  },

  {
    --  TODO
    "rmagatti/goto-preview",
    event = { "BufEnter" },
    dependencies = "rmagatti/logger.nvim",
    opts = {
      default_mappings = true,
    },
  },

  {
    -- Search & replace
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    keys = require("keymaps").grug_far,
  },

  {
    "folke/twilight.nvim",
    keys = require("keymaps").twilight,
  },

  {
    -- Helps to hide data in envs
    "laytan/cloak.nvim",
    lazy = false,
    opts = require("configs.cloak"),
    keys = require("keymaps").cloak,
  },

  {
    "folke/zen-mode.nvim",
    keys = require("keymaps").zen_mode,
  },

  {
    -- TODO:
    "stevearc/overseer.nvim",
    opts = {
      task_list = {
        direction = "left",
        bindings = {
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
          ["L"] = "IncreaseDetail",
          ["H"] = "DecreaseDetail",
          ["<PageUp>"] = "ScrollOutputUp",
          ["<PageDown>"] = "ScrollOutputDown",
        },
      },
    },
    keys = require("keymaps").overseer,
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
    "vidocqh/data-viewer.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "kkharji/sqlite.lua", -- Optional, sqlite support
    },
  },

  {
    "folke/which-key.nvim",
    event = { "CursorHold", "CursorHoldI" },
    init = require("configs.which").init,
    config = require("configs.which").config,
  },

  {
    -- TODO: research how useful SOPS is
    "lucidph3nx/nvim-sops",
    event = { "BufEnter" },
    keys = {
      -- { "<leader>ef", vim.cmd.SopsEncrypt, desc = "Encrypt File" },
      -- { "<leader>df", vim.cmd.SopsDecrypt, desc = "Decrypt File" },
    },
  },

  {
    -- Peek line on <cmd>number
    "nacro90/numb.nvim",
    config = function()
      require("numb").setup()
    end,
  },

  {
    "Wansmer/treesj",
    lazy = false,
    enabled = false,
    opts = { use_default_keymaps = false },
    config = function(_, opts)
      require("treesj").setup(opts)
    end,
    keys = require("keymaps").treesj,
  },

  {
    "ibhagwan/fzf-lua",
    config = require("configs.fzf").config,
  },

  {
    "gbprod/yanky.nvim",
    enabled = false,
    event = "BufReadPost",
    opts = {},
    dependencies = { "folke/snacks.nvim" },
    keys = require("keymaps").yanky,
  },

  {
    enabled = false,
    -- macros
    "chrisgrieser/nvim-recorder",
    dependencies = "rcarriga/nvim-notify", -- optional
    opts = {
      slots = { "a", "b", "c", "d", "e", "f", "g" },
      mapping = {
        startStopRecording = "q",
        playMacro = "@",
      },
      lessNotifications = false,
      clear = false,
      logLevel = vim.log.levels.INFO,
      dapSharedKeymaps = false,
    },
  },

  {
    "coffebar/neovim-project",
    enabled = false,
    opts = {
      projects = {
        "~/dev/*",
      },
      picker = {
        type = "telescope",
      },
    },
    init = function()
      -- enable saving the state of plugins in the session
      vim.opt.sessionoptions:append("globals") -- save global variables that start with an uppercase letter and contain at least one lowercase letter.
    end,
    dependencies = {
      -- optional picker
      { "nvim-telescope/telescope.nvim", tag = "0.1.4" },
      -- optional picker
      { "ibhagwan/fzf-lua" },
      -- optional picker
      { "folke/snacks.nvim" },
      { "Shatur/neovim-session-manager" },
    },
    lazy = false,
    priority = 100,
  },

  {
    enabled = false,
    "m4xshen/hardtime.nvim",
    lazy = false,
    config = function()
      require("hardtime").setup()
    end,
  },
}
