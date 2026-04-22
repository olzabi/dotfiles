local M = {}

M.laravel = {
  { ";Li",   "<cmd>Laravel install<cr>",                                 desc = "Laravel Install" },
  { ";LR",   "<cmd>Laravel related<cr>",                                 desc = "Laravel Related" },
  { ";Ll",   function() Laravel.pickers.laravel()              end,      desc = "Laravel Picker" },
  { ";La",   function() Laravel.pickers.artisan()              end,      desc = "Laravel Artisan" },
  { ";Lr",   function() Laravel.pickers.routes()               end,      desc = "Laravel Routes" },
  { ";Lm",   function() Laravel.pickers.make()                 end,      desc = "Laravel Make" },
  { ";Lc",   function() Laravel.pickers.commands()             end,      desc = "Laravel Commands" },
  { ";Lo",   function() Laravel.pickers.resources()            end,      desc = "Laravel Resources" },
  { ";Lt",   function() Laravel.commands.run("actions")        end,      desc = "Laravel Actions" },
  { ";Lp",   function() Laravel.commands.run("command_center") end,      desc = "Laravel Command Center" },
  { ";Lh",   function() Laravel.run("artisan docs")            end,      desc = "Laravel Docs" },
  { "<C-g>", function() Laravel.commands.run("view:finder")   end,      desc = "Laravel View Finder" },
}

M.phptools = {
  { ";Pl",       "<cmd>PhpTools Method<cr>",             desc = "Method" },
  { ";Pc",       "<cmd>PhpTools Class<cr>",              desc = "Class" },
  { ";Ps",       "<cmd>PhpTools Scripts<cr>",            desc = "Scripts" },
  { ";Pn",       "<cmd>PhpTools Namespace<cr>",          desc = "Namespace" },
  { ";Pg",       "<cmd>PhpTools GetSet<cr>",             desc = "GetSet" },
  { ";Pf",       "<cmd>PhpTools Create<cr>",             desc = "Create" },
  { ";Pd",       "<cmd>PhpTools DrupalAutoLoader<cr>",   desc = "DrupalAutoLoader" },
  { ";Pr", mode = "v", "<cmd>PhpTools Refactor<cr>",     desc = "Refactor" },
}

M.phptools_ide_helper = {
  { ";Pha", function() require("phptools.ide_helper").generate_all()     end, desc = "Generate all IDE helpers" },
  { ";Phm", function() require("phptools.ide_helper").generate_models()  end, desc = "Generate model helpers" },
  { ";Phf", function() require("phptools.ide_helper").generate_facades() end, desc = "Generate facade helpers" },
  { ";Pht", function() require("phptools.ide_helper").generate_meta()    end, desc = "Generate meta helper" },
  { ";Phi", function() require("phptools.ide_helper").install()          end, desc = "Install IDE Helper" },
}

M.phptools_tests = {
  { ";Plta", function() require("phptools.tests").test.all()      end, desc = "Run all tests" },
  { ";Ptf",  function() require("phptools.tests").test.file()     end, desc = "Run file tests" },
  { ";Ptl",  function() require("phptools.tests").test.line()     end, desc = "Run test at cursor" },
  { ";Pts",  function() require("phptools.tests").test.filter()   end, desc = "Search and run test" },
  { ";Ptp",  function() require("phptools.tests").test.parallel() end, desc = "Run in parallel" },
  { ";Ptr",  function() require("phptools.tests").test.rerun()    end, desc = "Rerun last test" },
  { ";Pti",  function() require("phptools.tests").test.selected() end, desc = "Run selected test" },
}

M.php_easy = {
  { "-#",  "<CMD>PHPEasyAttribute<CR>",         ft = "php",              desc = "Attribute" },
  { "-b",  "<CMD>PHPEasyDocBlock<CR>",          ft = "php",              desc = "DocBlock" },
  { "-r",  "<CMD>PHPEasyReplica<CR>",           ft = "php",              desc = "Replica" },
  { "-y",  "<CMD>PHPEasyCopy<CR>",              ft = "php",              desc = "Copy" },
  { "-d",  "<CMD>PHPEasyDelete<CR>",            ft = "php",              desc = "Delete" },
  { "-uu", "<CMD>PHPEasyRemoveUnusedUses<CR>",  ft = "php",              desc = "Remove unused uses" },
  { "-e",  "<CMD>PHPEasyExtends<CR>",           ft = "php",              desc = "Extends" },
  { "-i",  "<CMD>PHPEasyImplements<CR>",        ft = "php",              desc = "Implements" },
  { "--i", "<CMD>PHPEasyInitInterface<CR>",     ft = "php",              desc = "Init interface" },
  { "--c", "<CMD>PHPEasyInitClass<CR>",         ft = "php",              desc = "Init class" },
  { "--ac","<CMD>PHPEasyInitAbstractClass<CR>", ft = "php",              desc = "Init abstract class" },
  { "--t", "<CMD>PHPEasyInitTrait<CR>",         ft = "php",              desc = "Init trait" },
  { "--e", "<CMD>PHPEasyInitEnum<CR>",          ft = "php",              desc = "Init enum" },
  { "-c",  "<CMD>PHPEasyAppendConstant<CR>",    ft = "php", mode = { "n","v" }, desc = "Append constant" },
  { "-p",  "<CMD>PHPEasyAppendProperty<CR>",    ft = "php", mode = { "n","v" }, desc = "Append property" },
  { "-m",  "<CMD>PHPEasyAppendMethod<CR>",      ft = "php", mode = { "n","v" }, desc = "Append method" },
  { "__",  "<CMD>PHPEasyAppendConstruct<CR>",   ft = "php",              desc = "Append construct" },
  { "_i",  "<CMD>PHPEasyAppendInvoke<CR>",      ft = "php",              desc = "Append invoke" },
  { "-a",  "<CMD>PHPEasyAppendArgument<CR>",    ft = "php",              desc = "Append argument" },
}

M.phpactor = {
  { ";Pm", "<cmd>PhpactorContextMenu<CR>", ft = "php", desc = "Context menu" },
  { ";Pn", "<cmd>PhpactorClassNew<CR>",    ft = "php", desc = "New class" },
}

M.grug_far = {
  {
    "<leader>sr",
    function()
      local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
      require("grug-far").open({
        transient = true,
        prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
      })
    end,
    mode = { "n","v" },
    desc = "Search and Replace",
  },
}

M.gitsigns = {
  { "<leader>Gp", "<cmd>Gitsigns preview_hunk<cr>",              desc = "Preview hunk" },
  { "<leader>GB", function() require("gitsigns").blame() end,    desc = "Blame" },
}

M.git_blame = { { "<leader>uGb", "<cmd>GitBlameToggle<cr>", desc = "Toggle blame" }, }
M.lazygit = { { "<leader>Gl", "<cmd>LazyGit<cr>", desc = "LazyGit", }, }

M.cloak        = { { "<leader>uc",  "<cmd>CloakToggle<cr>",      desc = "Toggle cloak (.env)" } }
M.zen_mode     = { { "<leader>uEz", "<cmd>ZenMode<cr>",          desc = "Toggle ZenMode" } }
M.twilight     = { { "<leader>uEc", "<cmd>Twilight<cr>",         desc = "Toggle Twilight" } }
M.lazydocker   = { { "<leader>ul",  "<cmd>Lazydocker<cr>",       desc = "LazyDocker" } }
M.bufferline   = { { "<leader>bp",  "<cmd>BufferLinePick<cr>",   desc = "Pick buffer" } }
M.symbols_outline = { { "<leader>uCo", "<cmd>SymbolsOutline<cr>", desc = "Symbols outline" } }

M.noice = {
  { "<leader>n",  function() Snacks.picker.notifications() end, desc = "Notifications" },
  { "<leader>nn", "<cmd>NoiceDismiss<cr>",                      desc = "Dismiss" },
  { "<leader>nH", "<cmd>Noice history<cr>",                     desc = "History" },
  { "<leader>nl", "<cmd>Noice last<cr>",                        desc = "Last message" },
}

M.yazi = {
  { "<F6>",  "<cmd>Yazi cwd<cr>", desc = "Yazi (cwd)" },
  { "<F11>", "<cmd>Yazi<cr>",     desc = "Yazi (current file)" },
}

M.venv_selector = {
  { "<leader>vs", "<cmd>VenvSelector<cr>",       desc = "Venv selector" },
  { "<leader>vc", "<cmd>VenvSelectCached<cr>",   desc = "Select venv (cached)" },
}

M.overseer = {
  { "<leader>ot", "<cmd>OverseerToggle<CR>",      desc = "Toggle task list" },
  { "<leader>or", "<cmd>OverseerRun<CR>",         desc = "Run task" },
  { "<leader>ol", "<cmd>OverseerRunCmd<CR>",      desc = "Run command" },
  { "<leader>oq", "<cmd>OverseerQuickAction<CR>", desc = "Quick action" },
  { "<leader>oa", "<cmd>OverseerTaskAction<CR>",  desc = "Task action" },
  { "<leader>oc", "<cmd>OverseerClearCache<CR>",  desc = "Clear cache" },
  { "<leader>os", "<cmd>OverseerSaveBundle<CR>",  desc = "Save bundle" },
  { "<leader>ob", "<cmd>OverseerLoadBundle<CR>",  desc = "Load bundle" },
}

M.trouble = {
  { ";xx", "<cmd>Trouble diagnostics toggle<cr>",                desc = "Diagnostics" },
  { ";xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",   desc = "Buffer diagnostics" },
  { ";xs", "<cmd>Trouble symbols toggle<cr>",                    desc = "Symbols" },
  { ";xS", "<cmd>Trouble lsp toggle<cr>",                        desc = "LSP (Trouble)" },
  { ";xL", "<cmd>Trouble loclist toggle<cr>",                    desc = "Location list" },
  { ";xQ", "<cmd>Trouble qflist toggle<cr>",                     desc = "Quickfix list" },
  {
    "[q",
    function()
      if require("trouble").is_open() then
        require("trouble").prev({ skip_groups = true, jump = true })
      else
        local ok, err = pcall(vim.cmd.cprev)
        if not ok then vim.notify(err, vim.log.levels.ERROR) end
      end
    end,
    desc = "Prev trouble/quickfix",
  },
  {
    "]q",
    function()
      if require("trouble").is_open() then
        require("trouble").next({ skip_groups = true, jump = true })
      else
        local ok, err = pcall(vim.cmd.cnext)
        if not ok then vim.notify(err, vim.log.levels.ERROR) end
      end
    end,
    desc = "Next trouble/quickfix",
  },
}

M.treesj = {
  { "gJ", function() require("treesj").join()  end, desc = "Join lines" },
  { "gS", function() require("treesj").split() end, desc = "Split lines" },
}

M.yanky = {
  { "<leader>y", "<cmd>YankyRingHistory<cr>",          mode = { "n","x" }, desc = "Yank history" },
  { "y",  "<Plug>(YankyYank)",                         mode = { "n","x" }, desc = "Yank" },
  { "p",  "<Plug>(YankyPutAfter)",                     mode = { "n","x" }, desc = "Put after" },
  { "P",  "<Plug>(YankyPutBefore)",                    mode = { "n","x" }, desc = "Put before" },
  { "gp", "<Plug>(YankyGPutAfter)",                    mode = { "n","x" }, desc = "Put after selection" },
  { "gP", "<Plug>(YankyGPutBefore)",                   mode = { "n","x" }, desc = "Put before selection" },
  { "]p", "<Plug>(YankyPutIndentAfterLinewise)",                           desc = "Put indented after" },
  { "[p", "<Plug>(YankyPutIndentBeforeLinewise)",                          desc = "Put indented before" },
  { "]P", "<Plug>(YankyPutIndentAfterLinewise)",                           desc = "Put indented after" },
  { "[P", "<Plug>(YankyPutIndentBeforeLinewise)",                          desc = "Put indented before" },
  { ">p", "<Plug>(YankyPutIndentAfterShiftRight)",                         desc = "Put indent right" },
  { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)",                          desc = "Put indent left" },
  { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)",                        desc = "Put before indent right" },
  { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)",                         desc = "Put before indent left" },
  { "=p", "<Plug>(YankyPutAfterFilter)",                                   desc = "Put after filter" },
  { "=P", "<Plug>(YankyPutBeforeFilter)",                                  desc = "Put before filter" },
}

M.refactoring = {
  { "<leader>Rs", function() require("refactoring").select_refactor() end, mode = { "n","v" }, desc = "Select refactor" },
  { "<leader>Re", "<cmd>Refactor extract<cr>",             mode = "x", desc = "Extract function" },
  { "<leader>Rf", "<cmd>Refactor extract_to_file<cr>",     mode = "x", desc = "Extract to file" },
  { "<leader>Rv", "<cmd>Refactor extract_var<cr>",         mode = "x", desc = "Extract variable" },
  { "<leader>Ri", "<cmd>Refactor inline_var<cr>",          mode = { "x","n" }, desc = "Inline variable" },
  { "<leader>RI", "<cmd>Refactor inline_func<cr>",         mode = "n", desc = "Inline function" },
  { "<leader>Rb", "<cmd>Refactor extract_block<cr>",       mode = "n", desc = "Extract block" },
  { "<leader>RB", "<cmd>Refactor extract_block_to_file<cr>",mode = "n",desc = "Extract block to file" },
}

M.formatter = {
  {
    "<leader>cp",
    function()
      require("conform").format({
        notify_on_error = true,
        async = true,
        lsp_fallback = true,
      })
    end,
    mode = { "n","v" },
    desc = "Format",
  },
}

M.snacks = {
  { "<leader>bd",       function() Snacks.bufdelete() end,                                    desc = "Delete buffer" },
  { ";;",               function() Snacks.picker.grep() end,                                   desc = "Grep" },
  { "<leader>sw",       function() Snacks.picker.grep_word() end, mode = { "n","x" },          desc = "Visual selection or word" },
  { "<leader>sB",       function() Snacks.picker.grep_buffers() end,                           desc = "Grep open buffers" },
  { "<leader>su",       function() Snacks.picker.undo() end,                                   desc = "Undo history" },
  { '<leader>"',        function() Snacks.picker.registers() end,                              desc = "Registers" },
  { ";ff",              function() Snacks.picker.files() end,                                  desc = "Find files" },
  { ";Gb",              function() Snacks.picker.git_branches() end,                           desc = "Git branches" },
  { ";Gl",              function() Snacks.picker.git_log() end,                                desc = "Git log" },
  { ";GL",              function() Snacks.picker.git_log_line() end,                           desc = "Git log line" },
  { ";Gs",              function() Snacks.picker.git_status() end,                             desc = "Git status" },
  { ";GS",              function() Snacks.picker.git_stash() end,                              desc = "Git stash" },
  { ";Gd",              function() Snacks.picker.git_diff() end,                               desc = "Git diff" },
  { ";Ggf",             function() Snacks.picker.git_log_file() end,                           desc = "Git log file" },
  { "<leader>p",        function() Snacks.picker.yanky() end, mode = { "n","x" },              desc = "Yank history" },
  { ";q",               function() Snacks.picker.qflist() end,                                 desc = "Quickfix list" },
  { ";m",               function() Snacks.picker.marks() end,                                  desc = "Marks" },
  { ";P",               function() Snacks.picker.projects() end,                               desc = "Projects" },
  { "<leader><leader>", function() Snacks.scratch() end,                                       desc = "Scratch" },
  { ";s<leader>",       function() Snacks.scratch.select() end,                                desc = "Select scratch" },
  { ";r",               function() Snacks.picker.recent() end,                                 desc = "Recent files" },
  { ";<leader>",        function() Snacks.picker.smart() end,                                  desc = "Smart find files" },
  { "<leader>sT",       function() Snacks.picker.todo_comments({ keywords = { "TODO","FIX","WARN","HACK","PERF","NOTE","TEST" } }) end, desc = "Todo/Fix/Fixme" },
  { "<leader>xT",       "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,WARN,HACK,PERF,NOTE,TEST}}<cr>", desc = "Todos (Trouble)" },
}

return M
