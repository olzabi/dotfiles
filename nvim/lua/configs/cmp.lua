local M = {}
-- local function is_in_start_tag()
--   local ts_utils = require("nvim-treesitter.ts_utils")
--   local node = ts_utils.get_node_at_cursor()
--   if not node then
--     return false
--   end
--
--   local types = { "start_tag", "self_closing_tag", "directive_attribute" }
--   return vim.tbl_contains(types, node:type())
-- end
--
-- local vue_entry_filter = function(entry, ctx)
--   if ctx.filetype ~= "vue" then
--     return true
--   end
--
--   local bufnr = ctx.bufnr
--   -- Use a buffer-local cache to avoid rechecking Tree-sitter for every entry
--   local in_start_tag = vim.b[bufnr]._vue_ts_cached_is_in_start_tag
--   if in_start_tag == nil then
--     in_start_tag = is_in_start_tag()
--     vim.b[bufnr]._vue_ts_cached_is_in_start_tag = in_start_tag
--   end
--
--   -- If not in a start tag (e.g., inside script block), show everything
--   if not in_start_tag then
--     return true
--   end
--
--   local label = entry.completion_item.label
--   local text = ctx.cursor_before_line
--
--   -- Filtering for @ (events)
--   if text:sub(-1) == "@" then
--     return label:match("^@")
--   end
--
--   -- Filtering for : (props but not events)
--   if text:sub(-1) == ":" then
--     return label:match("^:") and not label:match("^:on%-")
--   end
--
--   return true
-- end

local format = function(entry, vim_item)
  local cmp_icons = require("utils.icons").cmp
  -- Setup icons and names depending on type
  vim_item.kind = string.format("%s %s", cmp_icons[vim_item.kind], vim_item.kind)
  vim_item.menu = ({
    nvim_lsp = "[LSP]",
    luasnip = "[Snippet]",
    buffer = "[Buffer]",
    path = "[Path]",
  })[entry.source.name]

  -- Remove duplicates entry
  vim_item.dup = ({
    buffer = 0,
    path = 0,
    nvim_lsp = 0,
    luasnip = 0,
  })[entry.source.name] or 0

  -- require("lspkind").cmp_format({
  --   before = require("tailwind-tools.cmp").lspkind_format,
  -- })

  return vim_item
end

local matching = {
  disallow_fuzzy_matching = true,
  disallow_fullfuzzy_matching = true,
  disallow_partial_fuzzy_matching = true,
  disallow_partial_matching = false,
  disallow_prefix_unmatching = true,
}

local get_bufnrs = function()
  local bufs = {}
  local mins = 20

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    bufs[vim.api.nvim_win_get_buf(win)] = true
  end

  local recentBufs = vim
    .iter(vim.fn.getbufinfo({ buflisted = 1 }))
    :filter(function(buf)
      return os.time() - buf.lastused < mins * 60
    end)
    :map(function(buf)
      return buf.bufnr
    end)
    :totable()

  for _, bufnr in ipairs(recentBufs) do
    bufs[bufnr] = true
  end

  return vim.tbl_keys(bufs)
end

M.dependencies = {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
    opts = {}
  },
  -- cmp sources
  { "hrsh7th/cmp-nvim-lsp-signature-help" },
  { "hrsh7th/cmp-nvim-lsp-document-symbol" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "hrsh7th/cmp-cmdline" },
  -- "hrsh7th/cmp-vsnip",
  -- "hrsh7th/vim-vsnip",
  {
    "hrsh7th/cmp-nvim-lsp",
    event = { "BufReadPre", "BufNewFile" },
    lazy = false,
  },
  {
    -- snippets
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    lazy = true,
    dependencies = {
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    opts = { history = true, updateevents = "TextChanged,TextChangedI" },
  },
  { "lukas-reineke/cmp-under-comparator" },
  {
    "petertriho/cmp-git",
    event = "InsertEnter",
    ft = { "gitcommit", "gitrebase" },
    opts = { filetypes = { "gitcommit", "octo", "markdown" } },
  },
  {
    "garymjr/nvim-snippets",
    opts = { friendly_snippets = true, create_cmp_source = true, highlight_preview = true },
  },
  -- {
  --   "roobert/tailwindcss-colorizer-cmp.nvim",
  --   -- optionally, override the default options:
  --   config = function()
  --     require("tailwindcss-colorizer-cmp").setup({
  --       color_square_width = 2,
  --     })
  --   end,
  -- },
}

M.config = function()
  local luasnip = require("luasnip")
  local cmp = require("cmp")
  local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  local cmp_compare = require("cmp.config.compare")

  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  cmp.event:on("menu_closed", function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.b[bufnr]._vue_ts_cached_is_in_start_tag = nil
  end)

  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_snipmate").lazy_load()
  require("luasnip.loaders.from_lua").lazy_load()

  local auto_select = true

  local cmp_sorting = {
    -- sorting = {
    --   priority_weight = 1,
    --   comparators = {
    --     require("cmp-under-comparator").under,
    --     cmp.config.compare.locality,
    --     cmp.config.compare.offset,
    --     cmp.config.compare.order,
    --     cmp.config.compare.score,
    --     cmp.config.compare.recently_used,
    --     cmp.config.compare.exact,
    --   },
    -- },

    priority_weight = 2,
    comparators = {
      function(...)
        return require("cmp_buffer"):compare_locality(...)
      end,
      cmp_compare.offset,
      cmp_compare.exact,
      cmp_compare.score,
      cmp_compare.sort_text,
      cmp_compare.recently_used,
      require("cmp-under-comparator").under,
      -- compare.locality,
      cmp_compare.kind,
      cmp_compare.length,
      cmp_compare.order,
    },
    matching = matching,
  }
  local cmp_sources = cmp.config.sources({
    { name = "lazydev", group_index = 0 },
    {
      name = "nvim_lsp",
      priority = 10,
      -- entry_filter = vue_entry_filter,
    },
    { name = "luasnip", priority = 6 },
    { name = "path", priority = 3 },
    { name = "treesitter" },
    { name = "render-markdown" },
    { name = "vim-dadbod-completion", priority = 1 },
    { name = "nvim_lsp_signature_help" },
  }, {
    {
      name = "buffer",
      priority = 8,
      option = {
        get_bufnrs = get_bufnrs,
        max_item_count = 4,
        max_indexed_line_length = 100,
      },
      keyword_length = 3,
    },
  })

  cmp.setup({
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    formatting = {
      expandable_indicator = true,
      fields = {
        cmp.ItemField.Abbr,
        cmp.ItemField.Kind,
        cmp.ItemField.Menu,
      },
      format = format,
    },
    performance = {
      filtering_context_budget = 3,
      debounce = 0,
      throttle = 0,
      fetching_timeout = 200,
      confirm_resolve_timeout = 80,
      async_budget = 1,
      max_view_entries = 200,
    },
    preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.none,
    completion = { completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect") },
    sorting = cmp_sorting,
    mapping = cmp.mapping.preset.insert(require("keymaps").cmp_mapping()),
    sources = cmp_sources,
    experimental = {
      ghost_text = true,
    },
  })

  cmp.setup.filetype("gitcommit", {
    sources = cmp.config.sources({
      { name = "git" },
      -- { name = "cmp_git" },
      -- { name = "conventionalcommits" },
    }, {
      { name = "buffer" },
    }),
  })

  cmp.setup.filetype({ "sql" }, {
    sources = {
      { name = "vim-dadbod-completion" },
      { name = "buffer" },
    },
  })

  cmp.setup.cmdline(":", {
    mapping = require("keymaps").cmdline_mapping(),
    sources = cmp.config.sources({
      {
        name = "path",
        option = {
          label_trailing_slash = true,
          trailing_slash = true,
        },
      },
      { "lazydev" },
    }, {
      { name = "cmdline", option = { ignore_cmds = { "Man", "!" } } },
    }),
    matching = matching,
  })

  cmp.setup.cmdline({ "/", "?" }, {
    mapping = require("keymaps").cmdline_mapping(),
    sources = {
      { name = "buffer" },
    },
    matching = matching,
  })

  -- cmp.setup.cmdline("/", {
  --   sources = cmp.config.sources({
  --     { name = "nvim_lsp_document_symbol" },
  --   }, {
  --     { name = "buffer" },
  --   }),
  -- })

  vim.api.nvim_create_autocmd("BufRead", {
    desc = "Setup cmp buffer crates source",
    pattern = "Cargo.toml",
    callback = function()
      cmp.setup.buffer({
        sources = {
          { name = "crates" },
        },
      })
    end,
  })
end

return M
