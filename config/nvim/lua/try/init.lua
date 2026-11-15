-- Trial plugins: installed and pinned in lazy-lock.json, but only loaded when asked for.
--   NVIM_TRY=all nvim             everything below
--   NVIM_TRY=flash,harpoon nvim   just those (names = the keys of `enabled` below)
-- Plain `nvim` is untouched. Keep what earns its place by moving its spec into editor/ or ui/.
local want = {}
for name in (vim.env.NVIM_TRY or ""):gmatch "[^,%s]+" do
  want[name] = true
end
local function on(name) return want.all or want[name] or false end

return {
  -- Jump anywhere on screen by typing 2 chars + a label; S selects a syntax node by label.
  {
    "folke/flash.nvim",
    cond = on "flash",
    event = "VeryLazy",
    opts = { modes = { search = { enabled = false } } }, -- leave / and ? untouched
    keys = {
      -- stylua: ignore start
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash select node" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash remote (e.g. yr<label>iw)" },
      -- stylua: ignore end
    },
  },

  -- Text objects (q quotes, b brackets, a args, f calls, ...) + surround on gs*, exchange on cx.
  -- The prefixes avoid flash's `s`, LSP's `gr*`, gx (open) and yanky's put keys.
  {
    "nvim-mini/mini.nvim",
    cond = on "mini",
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup { n_lines = 200 }
      require("mini.surround").setup {
        mappings = { add = "gsa", delete = "gsd", replace = "gsr", find = "gsf", find_left = "gsF", highlight = "gsh" },
      }
      require("mini.operators").setup {
        exchange = { prefix = "cx" },
        evaluate = { prefix = "g=" },
        multiply = { prefix = "gm" },
        replace = { prefix = "" }, -- yanky already owns paste-over
        sort = { prefix = "" },
      }
    end,
  },

  -- grn shows the rename live in every occurrence while you type.
  {
    "smjonas/inc-rename.nvim",
    cond = on "inc-rename",
    cmd = "IncRename",
    opts = {},
    keys = {
      -- stylua: ignore start
      { "grn", function() return ":IncRename " .. vim.fn.expand "<cword>" end, expr = true, desc = "Rename (live preview)" },
      -- stylua: ignore end
    },
  },

  -- A short per-project list of files you keep returning to; one key each.
  {
    "ThePrimeagen/harpoon",
    cond = on "harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("harpoon"):setup() end,
    keys = {
      -- stylua: ignore start
      { "<leader>h", function() require("harpoon"):list():add() end, desc = "Harpoon: pin file" },
      { "<leader>H", function() local h = require "harpoon" h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon: list" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
      -- stylua: ignore end
    },
  },

  -- snacks is already installed: highlight + jump between uses of the word under the cursor, and zen mode.
  {
    "snacks-extras",
    virtual = true,
    cond = on "snacks",
    event = "VeryLazy",
    config = function() Snacks.words.enable() end,
    keys = {
      -- stylua: ignore start
      { "]]", function() Snacks.words.jump(1, true) end, desc = "Next reference" },
      { "[[", function() Snacks.words.jump(-1, true) end, desc = "Prev reference" },
      { "<leader>z", function() Snacks.zen() end, desc = "Zen mode" },
      -- stylua: ignore end
    },
  },
}
