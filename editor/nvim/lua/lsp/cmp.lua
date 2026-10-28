local get_bufnrs = function()
  local bufs = {}
  local mins = 20
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    bufs[vim.api.nvim_win_get_buf(win)] = true
  end
  for _, buf in ipairs(vim.fn.getbufinfo { buflisted = 1 }) do
    if os.time() - buf.lastused < mins * 60 then
      bufs[buf.bufnr] = true
    end
  end
  return vim.tbl_keys(bufs)
end

return {
  -- autopairs as its own spec (was a blink dependency)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      enable_check_bracket_line = true,
      ts_config = { javascript = { "string", "template_string" } },
    },
  },

  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "rafamadriz/friendly-snippets",
      "Kaiser-Yang/blink-cmp-dictionary",
      { "saghen/blink.compat", version = "2.*", lazy = true, opts = {} },
      {
        "petertriho/cmp-git",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = { filetypes = { "gitcommit", "gitrebase" } },
      },
      {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        config = function()
          local luasnip = require "luasnip"
          luasnip.config.set_config {
            region_check_events = "InsertEnter",
            delete_check_events = "InsertLeave",
          }
          -- With snippets.preset = "luasnip", blink does NOT load friendly-snippets for you.
          require("luasnip.loaders.from_vscode").lazy_load()
          require("luasnip.loaders.from_vscode").lazy_load { paths = { vim.fn.stdpath "config" .. "/snippets" } }
        end,
      },
    },

    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      completion = {
        ghost_text = { enabled = true },
        documentation = { auto_show = true, window = { border = "rounded" } },
        -- If <CR> inserting a completion when you wanted a newline annoys you:
        -- list = { selection = { preselect = false, auto_insert = false } },
        -- (ghost text then only shows after you pick an item with <C-j>/<C-k>)
        list = { selection = { auto_insert = false } },
        accept = { auto_brackets = { enabled = true } },
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "kind_icon", gap = 1 },
              { gap = 1, "label" },
              { "kind", gap = 2 },
            },
            components = {
              -- no custom `highlight`: the default keeps per-kind / devicon colours
              kind_icon = {
                text = function(ctx)
                  return " " .. ctx.kind_icon .. " "
                end,
              },
              kind = {
                text = function(ctx)
                  return " " .. ctx.kind .. " "
                end,
              },
            },
          },
        },
      },

      -- signature help now actually enabled (shows on "(" and ","); the old `K` mapping is gone
      signature = { enabled = true, window = { border = "rounded" } },

      sources = {
        -- lazydev removed from default; scoped to lua below.
        -- (requires folke/lazydev.nvim to be installed in your config)
        default = { "lsp", "snippets", "path", "buffer" },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
          sql = { "buffer" },
          markdown = { "lsp", "snippets", "path", "buffer", "dictionary" },
          gitcommit = { "git", "buffer", "dictionary" },
          gitrebase = { "git", "buffer" },
        },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
          lsp = { score_offset = 10 },
          snippets = { score_offset = 6 },
          path = { score_offset = 3, opts = { trailing_slash = true, label_trailing_slash = true } },
          git = {
            name = "git",
            module = "blink.compat.source",
            opts = { filetypes = { "gitcommit", "gitrebase" } },
          },
          buffer = { min_keyword_length = 3, max_items = 4, opts = { get_bufnrs = get_bufnrs } },
          dictionary = {
            name = "Dict",
            module = "blink-cmp-dictionary",
            min_keyword_length = 3,
            -- Without a word list this provider returns nothing.
            -- Point it at a real file (check the plugin README for current option names / deps).
            opts = { dictionary_files = { "/usr/share/dict/words" } },
          },
        },
      },
      snippets = { preset = "luasnip" },
      appearance = { nerd_font_variant = "mono" },
      fuzzy = { implementation = "prefer_rust" },
      keymap = {
        -- stylua: ignore start
        preset = "default",
        ["<C-CR>"] = { "show", "hide" },
        ["<C-s>"] = { "snippet_forward", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-p>"] = { function(cmp) cmp.show { providers = { "path", "buffer" } } end, },
        ["<C-d>"] = { function(cmp) cmp.show { providers = { "dictionary" } } end, },
        --stylua: ignore end
      },
    },
    opts_extend = { "sources.default" },
  },
}
