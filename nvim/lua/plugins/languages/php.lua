return {
  {
    "ccaglak/phptools.nvim",
    lazy = false,
    keys = require("keymaps").phptools,
    config = function()
      require("phptools").setup({
        ui = {
          enable = true, -- default:true; false only if you have a UI enhancement plugin
          fzf = false, -- default:false; tests requires fzf used only in tests module otherwise there might long list  of tests
        },
        drupal_autoloader = { -- delete if you dont use it
          enable = false, -- default:false
          scan_paths = { "/web/modules/contrib/" }, -- Paths to scan for modules
          root_markers = { ".git" }, -- Project root markers
          autoload_file = "/vendor/composer/autoload_psr4.php", -- Autoload file path
        },
        custom_toggles = { -- delete if you dont use it
          enable = false, -- default:false
          -- { "foo", "bar", "baz" }, -- Add more custom toggle groups here
        },
      })
      require("keymaps").phptools_ide_helper_mapping()
      require("keymaps").phptools_test_mapping()
    end,
  },

  {
    -- Add the blade-nav.nvim plugin which provides Goto File capabilities
    -- for Blade files.
    "ricardoramirezr/blade-nav.nvim",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
    ft = { "blade", "php" },
    opts = {
      close_tag_on_complete = true,
    },
  },

  {
    "adalessa/laravel.nvim",
    lazy = false,
    event = { "VeryLazy" },
    cmd = { "Laravel", "Artisan", "Composer", "Sail", "Npm", "Yarn" },
    filetypes = { "blade", "php" },
    dependencies = {
      "tpope/vim-dotenv",
      "MunifTanjim/nui.nvim",
      "kevinhwang91/promise-async",
      "nvim-neotest/nvim-nio",
    },
    opts = {
      lsp_server = "intelephense",
      features = {
        pickers = {
          provider = "snacks", -- "snacks | telescope | fzf-lua | ui-select"
        },
      },
    },
    keys = require("keymaps").laravel,
  },

  {
    "ta-tikoma/php.easy.nvim",
    opts = {
      onAppend = {
        engine = "LuaSnip",
      },
    },
    config = true,
    keys = require("keymaps").php_easy,
  },

  "barryvdh/laravel-ide-helper",

  -- {
  --   "phpactor/phpactor",
  --   build = "composer install --no-dev --optimize-autoloader",
  --   ft = "php",
  --   keys = require("keymaps").phpactor,
  -- },
}
