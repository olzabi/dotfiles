local is_php_enabled = false

return {
  {
    "ccaglak/phptools.nvim",
    enabled = is_php_enabled,
    cond = function()
      return vim.fn.executable "php" == 1
    end,
    config = function()
      require("phptools").setup {
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
        custom_toggles = { enable = false },
      }
    end,
    keys = {
      -- stylua: ignore start
      { ";Pl", "<cmd>PhpTools Method<cr>", desc = "Method" },
      { ";Pc", "<cmd>PhpTools Class<cr>", desc = "Class" },
      { ";Ps", "<cmd>PhpTools Scripts<cr>", desc = "Scripts" },
      { ";Pn", "<cmd>PhpTools Namespace<cr>", desc = "Namespace" },
      { ";Pg", "<cmd>PhpTools GetSet<cr>", desc = "GetSet" },
      { ";Pf", "<cmd>PhpTools Create<cr>", desc = "Create" },
      { ";Pd", "<cmd>PhpTools DrupalAutoLoader<cr>", desc = "DrupalAutoLoader" },
      { ";Pr", mode = "v", "<cmd>PhpTools Refactor<cr>", desc = "Refactor" },
      { ";Pha", function() require("phptools.ide_helper").generate_all() end, desc = "Generate all IDE helpers", },
      { ";Phm", function() require("phptools.ide_helper").generate_models() end, desc = "Generate model helpers", },
      { ";Phf", function() require("phptools.ide_helper").generate_facades() end, desc = "Generate facade helpers", },
      { ";Pht", function() require("phptools.ide_helper").generate_meta() end, desc = "Generate meta helper", },
      { ";Phi", function() require("phptools.ide_helper").install() end, desc = "Install IDE Helper", },
      { ";Plta", function() require("phptools.tests").test.all() end, desc = "Run all tests", },
      { ";Ptf", function() require("phptools.tests").test.file() end, desc = "Run file tests", },
      { ";Ptl", function() require("phptools.tests").test.line() end, desc = "Run test at cursor", },
      { ";Pts", function() require("phptools.tests").test.filter() end, desc = "Search and run test", },
      { ";Ptp", function() require("phptools.tests").test.parallel() end, desc = "Run in parallel", },
      { ";Ptr", function() require("phptools.tests").test.rerun() end, desc = "Rerun last test", },
      { ";Pti", function() require("phptools.tests").test.selected() end, desc = "Run selected test", },
      -- stylua: ignore end
    },
  },

  {
    -- Add the blade-nav.nvim plugin which provides Goto File capabilities
    -- for Blade files.
    "ricardoramirezr/blade-nav.nvim",
    enabled = is_php_enabled,
    cond = function()
      return vim.fn.executable "php" == 1
    end,
    dependencies = "saghen/blink.cmp",
    opts = { close_tag_on_complete = true },
  },

  {
    "adalessa/laravel.nvim",
    enabled = false,
    cond = function()
      return vim.fn.filereadable(vim.fn.getcwd() .. "/artisan") == 1 and vim.fn.executable "php" == 1
    end,
    dependencies = { "tpope/vim-dotenv", "MunifTanjim/nui.nvim", "kevinhwang91/promise-async", "nvim-neotest/nvim-nio", "saghen/blink.cmp" },
    opts = {
      lsp_server = "intelephense",
      features = {
        pickers = {
          provider = "snacks", -- "snacks | telescope | fzf-lua | ui-select"
        },
        route_info = { enable = true, position = "top" },
      },
      register = { views = false, configs = true, model_field_completion = true, routes = true },
    },
    config = function(_, opts)
      require("laravel").setup(opts)

      vim.lsp.config("laravel-ls", {
        cmd = { "laravel-ls" },
        filetypes = { "php", "blade" },
        root_dir = vim.fn.getcwd,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "php", "blade" },
        callback = function()
          vim.lsp.enable "laravel-ls"
        end,
      })
    end,
    keys = {
      -- stylua: ignore start
      { ";Li", "<cmd>Laravel install<cr>", desc = "Laravel Install" },
      { ";LR", "<cmd>Laravel related<cr>", desc = "Laravel Related" },
      { ";Ll", function() Laravel.pickers.laravel() end, desc = "Laravel Picker", },
      { ";La", function() Laravel.pickers.artisan() end, desc = "Laravel Artisan", },
      { ";Lr", function() Laravel.pickers.routes() end, desc = "Laravel Routes", },
      { ";Lm", function() Laravel.pickers.make() end, desc = "Laravel Make", },
      { ";Lc", function() Laravel.pickers.commands() end, desc = "Laravel Commands", },
      { ";Lo", function() Laravel.pickers.resources() end, desc = "Laravel Resources", },
      { ";Lt", function() Laravel.commands.run "actions" end, desc = "Laravel Actions", },
      { ";Lp", function() Laravel.commands.run "command_center" end, desc = "Laravel Command Center", },
      { ";Lh", function() Laravel.run "artisan docs" end, desc = "Laravel Docs", },
      { "<C-g>", function() Laravel.commands.run "view:finder" end, desc = "Laravel View Finder", },
      -- stylua: ignore end
    },
  },

  {
    "ta-tikoma/php.easy.nvim",
    enabled = is_php_enabled,
    cond = function()
      return vim.fn.executable "php" == 1
    end,
    opts = { onAppend = { engine = "LuaSnip" } },
    config = true,
    keys = {
      { "-#", "<CMD>PHPEasyAttribute<CR>", desc = "Attribute" },
      { "-b", "<CMD>PHPEasyDocBlock<CR>", desc = "DocBlock" },
      { "-r", "<CMD>PHPEasyReplica<CR>", desc = "Replica" },
      { "-y", "<CMD>PHPEasyCopy<CR>", desc = "Copy" },
      { "-d", "<CMD>PHPEasyDelete<CR>", desc = "Delete" },
      { "-uu", "<CMD>PHPEasyRemoveUnusedUses<CR>", desc = "Remove unused uses" },
      { "-e", "<CMD>PHPEasyExtends<CR>", desc = "Extends" },
      { "-i", "<CMD>PHPEasyImplements<CR>", desc = "Implements" },
      { "--i", "<CMD>PHPEasyInitInterface<CR>", desc = "Init interface" },
      { "--c", "<CMD>PHPEasyInitClass<CR>", desc = "Init class" },
      { "--ac", "<CMD>PHPEasyInitAbstractClass<CR>", desc = "Init abstract class" },
      { "--t", "<CMD>PHPEasyInitTrait<CR>", desc = "Init trait" },
      { "--e", "<CMD>PHPEasyInitEnum<CR>", desc = "Init enum" },
      { "-c", "<CMD>PHPEasyAppendConstant<CR>", mode = { "n", "v" }, desc = "Append constant" },
      { "-p", "<CMD>PHPEasyAppendProperty<CR>", mode = { "n", "v" }, desc = "Append property" },
      { "-m", "<CMD>PHPEasyAppendMethod<CR>", mode = { "n", "v" }, desc = "Append method" },
      { "__", "<CMD>PHPEasyAppendConstruct<CR>", desc = "Append construct" },
      { "_i", "<CMD>PHPEasyAppendInvoke<CR>", desc = "Append invoke" },
      { "-a", "<CMD>PHPEasyAppendArgument<CR>", desc = "Append argument" },
    },
  },

  {
    "barryvdh/laravel-ide-helper",
    enabled = is_php_enabled,
    cond = function()
      return vim.fn.filereadable(vim.fn.getcwd() .. "/artisan") == 1 and vim.fn.executable "php" == 1
    end,
  },

  {
    "phpactor/phpactor",
    enabled = is_php_enabled,
    cond = function()
      return vim.fn.executable "php" == 1 and vim.fn.executable "composer" == 1
    end,
    build = "composer install --no-dev --optimize-autoloader",
    ft = "php",
    keys = {
      { ";Pm", "<cmd>PhpactorContextMenu<CR>", ft = "php", desc = "Contexmenu" },
      { ";Pn", "<cmd>PhpactorClassNew<CR>", ft = "php", desc = "New class" },
    },
  },
}
