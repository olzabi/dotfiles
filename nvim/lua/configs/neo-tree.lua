local M = {}

local commands = {
  delete = function(state)
    local inputs = require("neo-tree.ui.inputs")
    local path = state.tree:get_node().path
    local msg = "Are you sure you want to trash " .. path
    inputs.confirm(msg, function(confirmed)
      if not confirmed then
        return
      end
      -- it gonna broke if trash-cli is not installed
      -- https://github.com/sindresorhus/trash-cli
      vim.fn.system({ "trash", vim.fn.fnameescape(path) })
      require("neo-tree.sources.manager").refresh(state.name)
    end)
  end,
  image_preview = function(state)
    local node = state.tree:get_node()
    if node.type == "file" then
      require("image_preview").PreviewImage(node.path)
    end
  end,
}

local filesystem = {
  commands = commands,
  filtered_items = {
    visible = false,
    show_hidden_count = true,
    hide_dotfiles = false,
    hide_gitignored = false,
  },
  hide_by_name = {
    ".gitignore",
    ".gitattributes",
  },
  never_show = { ".git"},
  bind_to_cwd = true,
  follow_current_file = { enabled = false, leave_dirs_open = true },
  always_show = { ".gitignore" },
  hijack_netrw = true,
  window = {
    mappings = {
      -- ["pi"] = "image_preview", -- " or another map
    },
  },
}

local nesting_rules = {
  ["go"] = {
    pattern = "(.*)%.go$",
    files = { "%1_test.go" },
  },
  [".env"] = {
    pattern = "^%.env$",
    files = { "*.env", ".env.*", ".envrc", "env.d.ts" },
  },
  ["docker"] = {
    pattern = "^dockerfile$",
    ignore_case = true,
    files = { ".dockerignore", "docker-compose.*", "dockerfile*" },
  },
  ["ts"] = {
    pattern = "(.+)%.ts$",
    files = { "%1.test.ts", "%1.spec.ts" },
  },
  ["js"] = {
    pattern = "(.+)%.js$",
    files = { "%1.js.map", "%1.min.js", "%1.d.ts" },
  },
  ["next-config"] = {
    pattern = "next.config.js",
    files = {
      "next-env.d.ts",
      ".next",
    },
  },
  ["tsconfig"] = {
    pattern = "^tsconfig%.json$",
    files = {
      "tsconfig.*.json",
    },
  },
  ["package"] = {
    pattern = "^package%.json$",
    files = {
      "package-lock.json",
      "pnpm*",
      "yarn*",
      ".eslint*",
      ".prettier*",
      "*.config.json",
      ".npm*",
      "bun.lockb",
      ".nvmrc",
      ".php-version",
    },
  },
  ["php"] = {
    pattern = "^composer%.json$",
    files = {
      "composer.lock",
      "composer.phar",
      "artisan",
    }
  },
  ["lazy"] = {
    pattern = "^lazy%.json$",
    files = {
      "lazy-lock.json",
      "lazyvim.json",
    },
  },
}

local default_component_configs = {
  preview = { use_image_nvim = true },
  icon = { enabled = true, name = false, use_nerd_font = true },
  indent = {
    padding = 0,
    with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
    expander_collapsed = "",
    expander_expanded = "",
    expander_highlight = "NeoTreeExpander",
    highlight = "NeoTreeIndentMarker",
  },
  git_status = {
    symbols = require("utils.icons").neo_tree.git_status_symbols,
    window = {
      position = "float",
      mappings = {
        ["A"] = "git_add_all",
        ["gu"] = "git_unstage_file",
        ["ga"] = "git_add_file",
        ["gr"] = "git_revert_file",
        ["gc"] = "git_commit",
        ["gp"] = "git_push",
        ["gg"] = "git_commit_and_push",
      },
    },
  },
}

M.opts = {
  window = { position = "right", width = 30 },
  filesystem = filesystem,
  buffers = { follow_current_file = { enabled = true } },
  sources = {
    "filesystem",
    "buffers",
    "git_status",
  }, -- NOTE: sources not work well as well as winbar is lagging
  source_selector = {
    winbar = true,
    statusline = false,
    sources = {
      { source = "filesystem", display_name = "Files" },
      { source = "buffers", display_name = "Buf" },
      { source = "git_status", display_name = "Git" },
    },
  },
  open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
  default_component_configs = default_component_configs,
  nesting_rules = nesting_rules,
}

return M
