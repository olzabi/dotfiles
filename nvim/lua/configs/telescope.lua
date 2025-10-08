local M = {}

local defaults = {
  -- color_devicons = true,
  -- file_ignore_patterns = {
  --   "node_modules/",
  --   ".git/",
  --   "dist/",
  --   "build/",
  --   "package-lock.json",
  --   "yarn.lock",
  --   "bun.lockb",
  --   ".*_virt/.*",
  --   ".*__pycache__/.*",
  --   "*env*",
  --   ".venv",
  --   "*undo*",
  --   ".cache",
  -- },
  -- path_display = {
  --   "smart",
  --   -- filename_first = {
  --   --   reverse_directories = false,
  --   -- },
  -- },
  -- scroll_strategy = "cycle",
  -- layout_strategy = "vertical",
  -- sorting_strategy = "descending",
  -- borders = true,
  --
  -- vimgrep_arguments = {
  --   "rg",
  --   "--color=never",
  --   "--no-heading",
  --   "--with-filename",
  --   "--line-numbre",
  --   "--column",
  --   "--smart-case",
  -- },
  --
  -- layout_config = {
  --   horizontal = {
  --     -- mirror = false,
  --     prompt_position = "bottom",
  --     preview_width = 0.55,
  --     results_width = 0.8,
  --   },
  --   vertical = {
  --     -- mirror = false,
  --   },
  --   width = 0.85,
  --   height = 0.92,
  --   preview_cutoff = 120,
  -- },
}

local pickers = {
  -- find_files = {
  --   hidden = true,
  -- },
}

local extensions = {
  ["ui-select"] = {
    -- require("telescope.themes").get_dropdown({}),
  },
  fzf = {
    fuzzy = true, -- false will only do exact matching
    override_generic_sorter = true, -- override the generic sorter
    override_file_sorter = true, -- override the file sorter
    case_mode = "smart_case",
  },
  undo = {
    use_delta = true,
    use_custom_command = nil, -- setting this implies `use_delta = false`. Accepted format is: { "bash", "-c", "echo '$DIFF' | delta" }
    side_by_side = false,
    vim_diff_opts = {
      ctxlen = vim.o.scrolloff,
    },
    entry_format = "state #$ID, $STAT, $TIME",
    time_format = "",
    saved_only = false,
  },
  media_files = {
    filetypes = { "png", "webp", "jpg", "jpeg" },
    find_cmd = "rg",
  },
  file_browser = {
    theme = "dropdown",
    hijack_netrw = true,
  },
}

M.dependencies = {
  { "nvim-telescope/telescope-dap.nvim" },
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  { "nvim-telescope/telescope-file-browser.nvim" },
  { "nvim-telescope/telescope-frecency.nvim" },
  { "nvim-telescope/telescope-fzy-native.nvim" },
  { "nvim-telescope/telescope-github.nvim" },
  { "nvim-telescope/telescope-ui-select.nvim" },
  { "nvim-telescope/telescope-media-files.nvim" },
  { "chip/telescope-software-licenses.nvim" },
  { "debugloop/telescope-undo.nvim" },
  { "benfowler/telescope-luasnip.nvim" },
  { "crispgm/telescope-heading.nvim" },
  { "LinArcX/telescope-env.nvim" },
  { "mrloop/telescope-git-branch.nvim" },
  -- { "cljoly/telescope-repo.nvim" },
  { "nvim-lua/popup.nvim" },
  { "ahmedkhalf/project.nvim", event = { "CursorHold", "CursorHoldI" } },
  { "piersolenski/telescope-import.nvim" },
}

M.config = function()
  local telescope = require("telescope")
  telescope.setup({
    defaults = defaults,
    pickers = pickers,
    extensions = extensions,
  })

  -- NOTE: not works
  -- WARN: check rm or not
  telescope.load_extension("fzf") -- NOTE
  telescope.load_extension("git_worktree")
  telescope.load_extension("noice")
  telescope.load_extension("fidget") -- WARN
  telescope.load_extension("projects")
  telescope.load_extension("notify") -- WARN
  telescope.load_extension("ui-select") -- NOTE
  telescope.load_extension("refactoring") -- NOTE:
  telescope.load_extension("git_branch") -- WARN
  telescope.load_extension("undo")
  telescope.load_extension("import") -- WARN ??
  telescope.load_extension("luasnip") -- WARN  rm?
  telescope.load_extension("software-licenses")
  -- telescope.load_extension("repo")
  telescope.load_extension("heading") -- NOTE
  telescope.load_extension("env")
  telescope.load_extension("dap") -- NOTE:
  telescope.load_extension("frecency") -- WARN ?
  telescope.load_extension("fzy_native") -- NOTE
  telescope.load_extension("gh") -- NOTE
  telescope.load_extension("media_files")
  telescope.load_extension("file_browser") -- NOTE:

  -- keys
  -- vim.keymap.set("n", ";sw", function()
  --   local word = vim.fn.expand("<cword>")
  --   require("telescope.builtin").grep_string({ search = word })
  -- end)
  -- vim.keymap.set("n", ";sW", function()
  --   local word = vim.fn.expand("<cWORD>")
  --   require("telescope.builtin").grep_string({ search = word })
  -- end)
end

return M
