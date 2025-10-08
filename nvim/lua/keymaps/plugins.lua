local M = {}
local nmap = require("keymaps.utils").nmap

-- PHP
-------------
M.laravel = {
  { ";La", "<cmd>Laravel artisan<cr>", desc = "Laravel - Artisan" },
  { ";Lr", "<cmd>Laravel routes<cr>", desc = "Laravel - Routes" },
  { ";Li", "<cmd>Laravel install<cr>", desc = "Laravel Install" },
  { ";LR", "<cmd>Laravel related<cr>", desc = "Laravel - Related" },
}

M.phptools_ide_helper_mapping = function()
  -- Laravel IDE Helper keymaps
  local ide_helper = require("phptools.ide_helper") -- delete if you dont use it
  nmap(";Pha", ide_helper.generate_all, "Generate all IDE helpers")
  nmap(";Phm", ide_helper.generate_models, "Generate model helpers")
  nmap(";Phf", ide_helper.generate_facades, "Generate facade helpers")
  nmap(";Pht", ide_helper.generate_meta, "Generate meta helper")
  nmap(";Phi", ide_helper.install, "Install IDE Helper package")
end

M.phptools_test_mapping = function()
  local tests = require("phptools.tests") -- delete if you have a test plugin
  nmap(";Plta", tests.test.all, "Run all tests")
  nmap(";Ptf", tests.test.file, "Run current file tests")
  nmap(";Ptl", tests.test.line, "Run test at cursor")
  nmap(";Pts", tests.test.filter, "Search and run test")
  nmap(";Ptp", tests.test.parallel, "Run tests in parallel")
  nmap(";Ptr", tests.test.rerun, "Rerun last test")
  nmap(";Pti", tests.test.selected, "Run selected test file")
end

M.phptools = {
  { ";Pl", "<cmd>PhpTools Method<cr>", desc = "Method" },
  { ";Pc", "<cmd>PhpTools Class<cr>", desc = "Class" },
  { ";Ps", "<cmd>PhpTools Scripts<cr>", desc = "Scripts" },
  { ";Pn", "<cmd>PhpTools Namespace<cr>", desc = "Namespace" },
  { ";Pg", "<cmd>PhpTools GetSet<cr>", desc = "GetSet" },
  { ";Pf", "<cmd>PhpTools Create<cr>", desc = "Create" },
  { ";Pd", "<cmd>PhpTools DrupalAutoLoader<cr>", desc = "DrupalAutoLoader" },
  { mode = "v", ";Pr", "<cmd>PhpTools Refactor<cr>", desc = "Refactor" },
}

M.php_easy = {
  { "-#", "<CMD>PHPEasyAttribute<CR>", ft = "php" },
  { "-b", "<CMD>PHPEasyDocBlock<CR>", ft = "php" },
  { "-r", "<CMD>PHPEasyReplica<CR>", ft = "php" },
  { "-c", "<CMD>PHPEasyCopy<CR>", ft = "php" },
  { "-d", "<CMD>PHPEasyDelete<CR>", ft = "php" },
  { "-uu", "<CMD>PHPEasyRemoveUnusedUses<CR>", ft = "php" },
  { "-e", "<CMD>PHPEasyExtends<CR>", ft = "php" },
  { "-i", "<CMD>PHPEasyImplements<CR>", ft = "php" },
  { "--i", "<CMD>PHPEasyInitInterface<CR>", ft = "php" },
  { "--c", "<CMD>PHPEasyInitClass<CR>", ft = "php" },
  { "--ac", "<CMD>PHPEasyInitAbstractClass<CR>", ft = "php" },
  { "--t", "<CMD>PHPEasyInitTrait<CR>", ft = "php" },
  { "--e", "<CMD>PHPEasyInitEnum<CR>", ft = "php" },
  { "-c", "<CMD>PHPEasyAppendConstant<CR>", ft = "php", mode = { "n", "v" } },
  { "-p", "<CMD>PHPEasyAppendProperty<CR>", ft = "php", mode = { "n", "v" } },
  { "-m", "<CMD>PHPEasyAppendMethod<CR>", ft = "php", mode = { "n", "v" } },
  { "__", "<CMD>PHPEasyAppendConstruct<CR>", ft = "php" },
  { "_i", "<CMD>PHPEasyAppendInvoke<CR>", ft = "php" },
  { "-a", "<CMD>PHPEasyAppendArgument<CR>", ft = "php" },
}

M.phpactor = {
  { ";Pm", "<cmd>PhpactorContextMenu<CR>", ft = "php" },
  { ";Pn", "<cmd>PhpactorClassNew<CR>", ft = "php" },
}

-------------
M.neo_tree = {
  { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" },
  { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Toggle Explorer (curr)" },
}

M.multicursors = {
  {
    "<leader>m",
    "<CMD>MCstart<CR>",
    desc = "multicursor",
  },
  {
    "<leader>m",
    "<CMD>MCvisual<CR>",
    mode = "v",
    desc = "multicursor",
  },
  {
    "<leader><C-Down>",
    "<CMD>MCunderCursor<CR>",
    desc = "multicursor down",
  },
}

M.grug_far = {
  {
    "<leader>sr",
    function()
      local grug = require("grug-far")
      local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
      grug.open({
        transient = true,
        prefills = {
          filesFilter = ext and ext ~= "" and "*." .. ext or nil,
        },
      })
    end,
    mode = { "n", "v" },
    desc = "Search and Replace",
  },
}

-- UI
-------------
M.cloak = { { "<leader>uc", "<cmd>CloakToggle<cr>", desc = "Toggle Cloak (Hide .env)" } }
M.symbols_outline = { { "<leader>uCo", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } }
M.transparent = { { "<leader>uEt", "<cmd>TransparentToggle<cr>", desc = "Toggle Transparency" } }
M.zen_mode = { { "<leader>uEz", "<cmd>ZenMode<cr>", desc = "Toggle ZenMode" } }
M.twilight = { { "<leader>uEc", "<cmd>Twilight<cr>", desc = "Toggle Twilight" } }

M.vim_dadbod = {
  { "<leader>ud", "<cmd>DBUIToggle<cr>", desc = "Open Database UI" },
}

M.symbol_usage = function()
  nmap("<leader>uCs", "<cmd>lua require('symbol-usage').toggle_globally()<cr>", "Toggle Symbol Usage")
end

M.lazydocker = {
  { "<leader>ul", "<cmd>Lazydocker<cr>", desc = "Open LazyDocker" },
}
-------------

M.venv_selector = {
  { "<leader>vs", "<cmd>VenvSelector<cr>", "Venv Selector" },
  { "<leader>vc", "<cmd>VenvSelectCached<cr>", "Select Venv (Cached)" },
}

-- GIT
-------------
M.git_pipeline = { { "<leader>GP", "<cmd>Pipeline toggle<cr>" } }

M.gitsigns = {
  { "<leader>Gp", "<cmd>Gitsigns preview_hunk<cr>" },
  { "<leader>GB", "<cmd>lua require('gitsigns').blame()<cr>", desc = "Blame" }, -- NOTE: doesn't work
}

M.git_blame = {
  { "<leader>uGb", "<cmd>GitBlameToggle<cr>", desc = "Toggle Blame" },
}

M.lazygit = {
  {
    "<leader>Gl",
    "<cmd>LazyGit<cr><cmd>hi LazyGitFloat guibg=NONE guifg=NONE<cr><cmd>setlocal winhl=NormalFloat:LazyGitFloat<cr>",
    desc = "LazyGit",
  },
}

M.git_worktree = {
  {
    ";Gwl",
    "<cmd>lua require('telescope').extensions.git_worktree.git_worktrees()<cr>",
    desc = "List Git Worktree",
  },
  {
    ";Gwc",
    "<cmd>lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>",
    desc = "Create Git Worktree Branches",
  },
}

M.git_fzf = function()
  -- nmap("<leader>f", "<cmd>FzfLua files<CR>")
  nmap("<leader>rg", "<cmd>FzfLua grep_project<CR>")
  nmap("<leader>bb", "<cmd>FzfLua buffers<CR>")
  nmap("<leader>Gs", "<cmd>FzfLua git_status<CR>")
end
-------------

M.overseer = {
  {
    "<leader>ot",
    "<cmd>OverseerToggle<CR>",
    desc = "Toggle Overseer Task List",
  },
  { "<leader>or", "<cmd>OverseerRun<CR>", desc = "Run Overseer Task" },
  {
    "<leader>ol",
    "<cmd>OverseerRunCmd<CR>",
    desc = "Run Command in Overseer",
  },
  {
    "<leader>oq",
    "<cmd>OverseerQuickAction<CR>",
    desc = "Quick Action for Overseer Task",
  },
  {
    "<leader>oa",
    "<cmd>OverseerTaskAction<CR>",
    desc = "Select and Act on Overseer Task",
  },
  {
    "<leader>oc",
    "<cmd>OverseerClearCache<CR>",
    desc = "Clear Overseer Task Cache",
  },
  {
    "<leader>os",
    "<cmd>OverseerSaveBundle<CR>",
    desc = "Save Overseer Task Bundle",
  },
  {
    "<leader>ob",
    "<cmd>OverseerLoadBundle<CR>",
    desc = "Load Overseer Task Bundle",
  },
}

M.trouble = {
  { ";xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
  { ";xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
  { ";xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
  { ";xS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },
  { ";xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
  { ";xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
  {
    "[q",
    function()
      if require("trouble").is_open() then
        require("trouble").prev({ skip_groups = true, jump = true })
      else
        local ok, err = pcall(vim.cmd.cprev)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end
    end,
    desc = "Previous Trouble/Quickfix Item",
  },
  {
    "]q",
    function()
      if require("trouble").is_open() then
        require("trouble").next({ skip_groups = true, jump = true })
      else
        local ok, err = pcall(vim.cmd.cnext)
        if not ok then
          vim.notify(err, vim.log.levels.ERROR)
        end
      end
    end,
    desc = "Next Trouble/Quickfix Item",
  },
}

M.treesj = {
  { "gJ", "<cmd>require('treesj').join()<cr>", desc = "Join lines" },
  { "gS", "<cmd>require('treesj').split()<cr>", desc = "Split lines" },
}

M.yazi = {
  { "<f6>", "<cmd>Yazi cwd<cr>", desc = "Open File Manager (cwd)" },
  { "<f11>", "<cmd>Yazi<cr>", desc = "Open yazi at the current file" },
}

M.yanky = {
  {
    "<leader>p",
    function()
      Snacks.picker.yanky()
    end,
    mode = { "n", "x" },
    desc = "Open Yank History",
  },
}

M.todo_comments = {
  {
    "[t",
    function()
      require("todo-comments").jump_prev()
    end,
    desc = "Previous Todo Comment",
  },
  {
    "]t",
    function()
      require("todo-comments").jump_next()
    end,
    desc = "Next Todo Comment",
  },
  { ";xt", "<cmd>TodoTelescope<cr>", desc = "Todo" },
  { ";xT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
}

M.snacks = {
  -- buffer
  {
    "<leader>bd",
    function()
      Snacks.bufdelete()
    end,
    desc = "Delete Buffer",
  },
  -- search
  {
    ";;",
    function()
      Snacks.picker.grep()
    end,
    desc = "Grep",
  },
  {
    "<leader>sw",
    function()
      Snacks.picker.grep_word()
    end,
    desc = "Visual selection or word",
    mode = { "n", "x" },
  },
  {
    "<leader>sB",
    function()
      Snacks.picker.grep_buffers()
    end,
    desc = "Grep Open Buffers",
  },
  {
    "<leader>su",
    function()
      Snacks.picker.undo()
    end,
    desc = "Undo History",
  },
  {
    '<leader>"',
    function()
      Snacks.picker.registers()
    end,
    desc = "Registers",
  },
  {
    ";ff",
    function()
      Snacks.picker.files()
    end,
    desc = "Find Files",
  },

  -- Git
  {
    ";Gb",
    function()
      Snacks.picker.git_branches()
    end,
    desc = "Git Branches",
  },
  {
    ";Gl",
    function()
      Snacks.picker.git_log()
    end,
    desc = "Git Log",
  },
  {
    ";GL",
    function()
      Snacks.picker.git_log_line()
    end,
    desc = "Git Log Line",
  },
  {
    ";Gs",
    function()
      Snacks.picker.git_status()
    end,
    desc = "Git Status",
  },
  {
    ";GS",
    function()
      Snacks.picker.git_stash()
    end,
    desc = "Git Stash",
  },
  {
    ";Gd",
    function()
      Snacks.picker.git_diff()
    end,
    desc = "Git Diff (Hunks)",
  },
  {
    ";Ggf",
    function()
      Snacks.picker.git_log_file()
    end,
    desc = "Git Log File",
  },
  --
  {
    ";q",
    function()
      Snacks.picker.qflist()
    end,
    desc = "Quickfix List",
  },
  {
    ";m",
    function()
      Snacks.picker.marks()
    end,
    desc = "Marks",
  },
  {
    ";P",
    function()
      Snacks.picker.projects()
    end,
    desc = "Projects",
  },
  {
    "<leader><leader>",
    function()
      Snacks.scratch()
    end,
    desc = "Scratch",
  },
  {
    ";s<leader>",
    function()
      Snacks.scratch.select()
    end,
    desc = "Select Scratch",
  },
  {
    ";r",
    function()
      Snacks.picker.recent()
    end,
    desc = "Recent files",
  },
  {
    ";<leader>",
    function()
      Snacks.picker.smart()
    end,
    desc = "Smart Find Files",
  },

  {
    -- double \ to enter
    "\\\\",
    function()
      Snacks.terminal()
    end,
    desc = "Toggle Terminal",
  },
}

M.treesitter = { { "<leader>ts", "<cmd>TSContextToggle<cr>", desc = "Treesitter Context" } }

M.noice = {
  { "<leader>nn", "<cmd>NoiceDismiss<cr>", desc = "Dismiss Notifications" },
  { "<leader>nH", "<cmd>Noice history<cr>", desc = "Notifications History" },
  { "<leader>nl", "<cmd>Noice last<cr>", desc = "Show Last Message" },
}

M.refactoring = {
  {
    "<leader>Rs",
    function()
      require("refactoring").select_refactor()
    end,
    mode = { "n", "v" },
    noremap = true,
    silent = true,
    expr = false,
  },
  { "<leader>Re", "<cmd>Refactor extract<cr>", mode = "x", desc = "Extract function" },
  { "<leader>Rf", "<cmd>Refactor extract_to_file<cr>", mode = "x", desc = "Extract function to file" },
  { "<leader>Rv", "<cmd>Refactor extract_var<cr>", mode = "x", desc = "Extract variable" },
  { "<leader>Ri", "<cmd>Refactor inline_var<cr>", mode = { "x", "n" }, desc = "Inline variable" },
  { "<leader>RI", "<cmd>Refactor inline_func<cr>", mode = "n", desc = "Inline function" },
  { "<leader>Rb", "<cmd>Refactor extract_block<cr>", mode = "n", desc = "Extract block" },
  { "<leader>Rf", "<cmd>Refactor extract_block_to_file<cr>", mode = "n", desc = "Extract block to file" },
}

M.mini_pairs = {
  {
    -- https://github.com/LazyVim/LazyVim/blob/7f9219162b54a717b7da5cb543ab1e778c9a124b/lua/lazyvim/plugins/coding.lua#L122C1-L134C9
    "<leader>uCp",
    function()
      vim.g.minipairs_disable = not vim.g.minipairs_disable
      if vim.g.minipairs_disable then
        vim.notify("Disabled autopairs", vim.log.levels.INFO, { title = "Option" })
      else
        vim.notify("Enabled autopairs", vim.log.levels.INFO, { title = "Option" })
      end
    end,
    desc = "Toggle Autopairs",
  },
}

M.bufferline = {
  { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
  { "<A-S-Right>", "<cmd>+tabmove<cr>", desc = "Move tab to next" },
  { "<A-S-Left>", "<cmd>-tabmove<cr>", desc = "Move tab to previous" },
}

M.debug = {
  -- Basic debugging keymaps, feel free to change to your liking!
  {
    "<leader>dc",
    function()
      require("dap").continue()
    end,
    desc = "Continue",
  },
  {
    "<leader>di",
    function()
      require("dap").step_into()
    end,
    desc = "Step Into",
  },
  {
    "<leader>dO",
    function()
      require("dap").step_over()
    end,
    desc = "Step Over",
  },
  {
    "<leader>do",
    function()
      require("dap").step_out()
    end,
    desc = "Step Out",
  },
  {
    "<leader>dg",
    function()
      require("dap").goto_()
    end,
    desc = "Got to line (no execute)",
  },
  {
    "<leader>dt",
    function()
      require("dap").terminate()
    end,
    desc = "Terminate",
  },
  {
    "<leader>dC",
    function()
      require("dap").run_to_cursor()
    end,
    desc = "Run to Cursor",
  },
  {
    "<leader>dp",
    function()
      require("dap").pause()
    end,
    desc = "Pause",
  },
  {
    "<leader>da",
    function()
      require("dap").continue({ before = get_args })
    end,
    desc = "Run with Args",
  },
  {
    "<leader>db",
    function()
      require("dap").toggle_breakpoint()
    end,
    desc = "Toggle Breakpoint",
  },
  {
    "<leader>dB",
    function()
      require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end,
    desc = "Set Breakpoint",
  },
  -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
  {
    "<F7>",
    function()
      require("dapui").toggle()
    end,
    desc = "See last session result.",
  },
}

-- Coding
-------------
M.formatter = {
  {
    "<leader>cp",
    function()
      require("conform").format({
        notify_on_error = true,
        lsp_fallback = true,
        async = true,
        format_on_save = {
          timeout_ms = 500,
          lsp_format = "fallback",
        },
      })
    end,
    desc = "Trigger Prettier Format (full/visual)",
  },
}

M.typescript = {
  { "<leader>cT", name = "Typescript Tools", desc = "Typescript Tools" },
  { "<leader>cTo", "<cmd>TSToolsOrganizeImports<CR>", desc = "Organize Imports" },
  { "<leader>cTs", "<cmd>TSToolsSortImports<CR>", desc = "Sort Imports" },
  { "<leader>cTX", "<cmd>TSToolsRemoveUnusedImports<CR>", desc = "Remove Unused Imports" },
  { "<leader>cTx", "<cmd>TSToolsRemoveUnused<CR>", desc = "Remove Unused Statements" },
  { "<leader>cTa", "<cmd>TSToolsAddMissingImports<CR>", desc = "Add Missing Imports" },
  { "<leader>cTf", "<cmd>TSToolsFixAll<CR>", desc = "Fix All Errors" },
  { "<leader>cTd", "<cmd>TSToolsGoToSourceDefinition<CR>", desc = "Source Definition" },
  { "<leader>cTr", "<cmd>TSToolsRenameFile<CR>", desc = "Rename File" },
  { "<leader>cTF", "<cmd>TSToolsFileReferences<CR>", desc = "Find File References" },
}
-------------

-- cmp
-------------
M.cmp_mapping = function()
  local cmp = require("cmp")
  return {
    -- ["<C-b>"] = cmp.mapping.scroll_docs(-4), -- Up
    -- ["<C-f>"] = cmp.mapping.scroll_docs(4), -- Down
    ["<C-Space>"] = cmp.mapping.complete({
      config = {
        sources = { { name = "nvim_lsp" } },
      },
    }),
    ["<C-s>"] = cmp.mapping.complete({
      config = {
        sources = { { name = "luasnip" } },
      },
    }),
    ["<C-v>"] = cmp.mapping.complete({
      config = {
        sources = { { name = "path" }, { name = "buffer" } },
      },
    }),
    ["<CR>"] = cmp.mapping.confirm({
      -- behavior = cmp.ConfirmBehavior.Insert,
      select = false,
    }),
    -- NOTE: default ones: [C-y] to confirm, [C-e] to abort
  }
end

M.cmdline_mapping = function()
  local cmp = require("cmp")
  return {
    ["<CR>"] = cmp.mapping(cmp.mapping.confirm({ select = false }), { "c" }),
    ["<C-j>"] = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }), { "c" }),
    ["<C-k>"] = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }), { "c" }),
  }
end

-- HTTP
-------------
M.kulala = {
  { "<leader>Hs", desc = "Send request" },
  { "<leader>Ha", desc = "Send all requests" },
  { "<leader>Hb", desc = "Open scratchpad" },
}
M.persistence = {
  { "<leader>Ss", [[<cmd>lua require("persistence").load()<cr>]] },
  { "<leader>Sl", [[<cmd>lua require("persistence").load({ last = true})<cr>]] },
  { "<leader>Sd", [[<cmd>lua require("persistence").stop()<cr>]] },
}

M.telescope = {
  -- {
  --   "<leader>r",
  --   ":lua require'telescope'.extensions.live_grep_args.live_grep_args()<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "RG",
  -- },
  -- {
  --   "<leader>#",
  --   ":lua require('telescope.builtin').grep_string()<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Grep string",
  -- },
  -- {
  --   "<leader>ts",
  --   ":lua require('telescope.builtin').treesitter()<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Treesitter",
  -- },
  -- { "<leader>m", ":lua require('telescope.builtin').marks()<CR>", noremap = true, silent = true, desc = "Marks" },
  -- {
  --   "<leader>bb",
  --   ":lua require('plugins.telescope').my_buffers()<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Buffers",
  -- },
  -- {
  --   "<leader>l",
  --   ":lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Search line buffer",
  -- },
  -- {
  --   "<leader>f",
  --   ":lua require('telescope.builtin').find_files({hidden=true})<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Find files",
  -- },
  -- {
  --   "<leader>fp",
  --   ":lua require('plugins.telescope').project_files()<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Project files",
  -- },
  -- {
  --   "<leader>p",
  --   ":lua require'telescope'.extensions.repo.list{file_ignore_patterns={'/%.cache/', '/%.cargo/', '/%.local/', '/%.asdf/', '/%.zinit/', '/%.tmux/'}}<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Projects",
  -- },
  -- {
  --   "<leader>g",
  --   ":lua require('plugins.telescope').my_git_status()<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Git status",
  -- },
  -- { "<leader>ns", ":lua require('plugins.telescope').my_note()<CR>", noremap = true, silent = true, desc = "Note" },
  -- { "<leader>y", ":Telescope neoclip<CR>", noremap = true, silent = true, desc = "Neoclip" },
  -- {
  --   "<leader>ll",
  --   ":lua require('telescope.builtin').grep_string({ search = vim.fn.input('GREP -> ') })<CR>",
  --   noremap = true,
  --   silent = true,
  --   desc = "Grep string",
  -- },
  -- { "<leader>z", ":Telescope zoxide list<CR>", noremap = true, silent = true, desc = "Zoxide" },
  -- { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "Find in files" },
  -- { "<leader>o", "<cmd>Telescope find_files<cr>", desc = "Find files" },
  -- { "<leader>p", "<cmd>Telescope oldfiles<cr>", desc = "Previous files" },
  -- { "gr", "<cmd>Telescope lsp_references<cr>", desc = "Go to references" },
  -- { "gI", "<cmd>Telescope lsp_implementations<cr>", desc = "Go to implementations" },
  -- { "<leader>t", group = "Telescope" },
  -- { "<leader>tb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
  -- { "<leader>tg", group = "Git" },
  -- { "<leader>tgb", "<cmd>Telescope git_branches<cr>", desc = "Git branches" },
  -- { "<leader>tgo", "<cmd>Telescope git_files<cr>", desc = "Git files" },
  -- { "<leader>tj", "<cmd>Telescope jumplist<cr>", desc = "Jumplist" },
  -- { "<leader>to", "<cmd>Telescope find_files<CR>", desc = "Find files" },
  -- { "<leader>tp", "<cmd>Telescope oldfiles<cr>", desc = "Oldfiles" },
  -- { "<leader>tq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix list" },
  -- { "<leader>tr", "<cmd>Telescope resume<cr>", desc = "Previous Telescope window" },
  -- { "<leader>ts", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace symbols" },
  -- { "<leader>tt", "<cmd>Telescope<cr>", desc = "Open Telescope" },
}
-- Reload nvim

return M --
-- nmap("<leader>ee", "<cmd>vsp .env<cr>", "Open .env file in a vertical split")
