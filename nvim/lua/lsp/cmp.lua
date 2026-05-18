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
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "rafamadriz/friendly-snippets",
      "Kaiser-Yang/blink-cmp-dictionary",
      {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
        opts = {},
      },
      {
        "saghen/blink.compat",
        version = "2.*",
        lazy = true,
        opts = {},
      },
      {
        "petertriho/cmp-git",
        ft = { "gitcommit", "gitrebase" },
        opts = { filetypes = { "gitcommit", "octo", "markdown" } },
      },
      {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        config = function()
          local luasnip = require "luasnip"

          -- Loads all the snippets installed by extensions in vscode.
          -- require('luasnip.loaders.from_vscode').lazy_load()
          require("luasnip.loaders.from_vscode").load { paths = "~/.config/nvim/snippets" }

          luasnip.config.set_config {
            region_check_events = "InsertEnter",
            delete_check_events = "InsertLeave",
          }

          luasnip.config.setup {}
        end,
      },
    },

    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      completion = {
        ghost_text = { enabled = true },
        documentation = { auto_show = true, window = { border = "rounded" } },
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
              kind_icon = {
                text = function(ctx) return " " .. ctx.kind_icon .. " " end,
                highlight = function(ctx) return "BlinkCmpKindIcon" .. ctx.kind end,
              },
              kind = { text = function(ctx)return" " .. ctx.kind .. " "end,  },
            },
          },
        },
      },
      sources = {
        default = { "lsp", "snippets", "path", "buffer", "lazydev", "dictionary" },
        per_filetype = {
          sql = { "buffer" },
          gitcommit = { "git", "buffer" },
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
            opts = { filetypes = { "gitcommit", "octo", "markdown", "gitrebase" } },
          },
          buffer = { min_keyword_length = 3, max_items = 4, opts = { get_bufnrs = get_bufnrs } },
          dictionary = { module = "blink-cmp-dictionary", min_keyword_length = 3 },
        },
      },
      snippets = { preset = "luasnip" },
      appearance = { nerd_font_variant = "mono" },
      fuzzy = { implementation = "prefer_rust" },
      keymap = {
        -- stylua: ignore start
        preset = "default",
        ["<C-Space>"] = { "show", "hide" },
        ["<C-s>"] = { "snippet_forward", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-p>"] = { function(cmp) cmp.show { providers = { "path", "buffer" } } end, },
        ["<C-d>"] = { function(cmp) cmp.show { providers = { "dictionary"     } } end, },
        ["K"] = { "show_signature", "fallback" },
        --stylua: ignore end
      },
    },
    opts_extend = { "sources.default" },
  },
}
