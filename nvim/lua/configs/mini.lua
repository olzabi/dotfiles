local M = {}

M.dependencies = {
  {
    "nvim-mini/mini.ai",
    opts = {
      -- custom_textobjects = {
      --   o = require("mini.ai").gen_spec.treesitter({
      --     a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      --     i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      --   }, {}),
      --   f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
      --   c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
      --   t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
      -- },
      --       config = function()
      --   local treesitter = require('mini.ai').gen_spec.treesitter
      --
      --   require('mini.ai').setup {
      --     custom_textobjects = {
      --       -- Whole buffer
      --       e = function()
      --         local from = { line = 1, col = 1 }
      --         local to = {
      --           line = vim.fn.line '$',
      --           col = math.max(vim.fn.getline('$'):len(), 1),
      --         }
      --         return { from = from, to = to }
      --       end,
      --
      --       -- Current line
      --       j = function(args)
      --         local index_of_first_non_whitespace_character = string.find(vim.fn.getline '.', '%S')
      --         local col = args == 'i' and index_of_first_non_whitespace_character or 1
      --
      --         return {
      --           from = { line = vim.fn.line '.', col = col },
      --           to = { line = vim.fn.line '.', col = math.max(vim.fn.getline('.'):len(), 1) },
      --         }
      --       end,
      --
      --       -- Function definition (needs treesitter queries with these captures)
      --       m = treesitter { a = '@function.outer', i = '@function.inner' },
      --
      --       o = treesitter {
      --         a = { '@conditional.outer', '@loop.outer' },
      --         i = { '@conditional.inner', '@loop.inner' },
      --       },
      --     },
      --   }
      -- end,
    },
  },

  {
    -- TODO:
    -- alt nvim-surround
    -- https://github.com/kylechui/nvim-surround
    "nvim-mini/mini.surround",
    event = { "CursorHold", "CursorHoldI" },
    opts = {
      highlight_duration = 500,
      silent = false,
      search_method = "cover",
      mappings = {
        highlight = "sh",
        find = "sf",
        add = "sa",
        delete = "sd",
      },
    },
  },

  { "nvim-mini/mini.operators" },

  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    keys = require("keymaps").mini_pairs,
    opts = {
      mappings = {
        ["<"] = { action = "open", pair = "<>", neigh_pattern = "[%a:]." },
        [">"] = { action = "close", pair = "<>", neigh_pattern = "[^\\]." },
        ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^<&]." },
      },
    },
  },

  { "nvim-mini/mini.bracketed" },

  { "nvim-mini/mini.snippets", event = "InsertEnter" },

  {
    "nvim-mini/mini.files",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-mini/mini.icons" },
    enabled = false,
    opts = {
      show_dotfiles = true,
      windows = {
        preview = true,
        width_preview = 30,
        width_focus = 30,
      },
      options = {
        permanent_delete = false,
        use_as_default_explorer = false,
      },
    },
  },

  {
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {
      file = {
        [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
        ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
        [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
        [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
        [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
        ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
      },
      filetype = {
        dotenv = { glyph = "", hl = "MiniIconsYellow" },
      },
    },
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  {
    "nvim-mini/mini.statusline",
    enabled = false,
    config = function()
      require("mini.statusline").setup({ set_vim_settings = false })
    end,
  },

  {
    "nvim-mini/mini.bufremove",
    enabled = false,
    keys = {
      -- Smart bufremove
      -- reference: https://github.com/LazyVim/LazyVim/blob/7f9219162b54a717b7da5cb543ab1e778c9a124b/lua/lazyvim/plugins/editor.lua#L423-L434
      {
        "<leader>bd",
        function()
          local bd = require("mini.bufremove").delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = "Delete Buffer",
      },
    },
  },

  { "nvim-mini/mini.comment" },

  {
    -- WARN: mini.pairs unexpected behavior was replaced by "windwp/nvim-autopairs"
    "nvim-mini/mini.pairs",
    enabled = true,
  },

  { "nvim-mini/mini.splitjoin" },
  { "nvim-mini/mini.operators" },
  { "nvim-mini/mini.jump" },
  { "nvim-mini/mini.clue" },
  { "nvim-mini/mini.deps" },
  { "nvim-mini/mini.diff" },
  { "nvim-mini/mini-git" },
  { "nvim-mini/mini.pick" },
  { "nvim-mini/mini.visits" },
  { "nvim-mini/mini.sessions" },
  { "nvim-mini/mini.basics" },
}

return M
