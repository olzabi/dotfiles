local function setup()
  local dap, dapui = require("dap"), require("dapui")

  dapui.setup({
    controls = {
      element = "repl",
      enabled = true,
      icons = require("utils.icons").debug.controls,
    },
    element_mappings = {},
    expand_lines = true,
    floating = {
      border = "single",
      mappings = {
        close = { "q", "<Esc>" },
      },
    },
    force_buffers = true,
    icons = require("utils.icons").debug.dapui,
    layouts = {
      --{
      --	elements = {
      --		{
      --			id = "scopes",
      --			size = 0.25,
      --		},
      --		{
      --			id = "breakpoints",
      --			size = 0.25
      --		},
      --		{
      --			id = "stacks",
      --			size = 0.25
      --		},
      --		{
      --			id = "watches",
      --			size = 0.25
      --		}
      --	},
      --	position = "left",
      --	size = 40
      --},
      {
        elements = {
          --{
          --	id = "repl",
          --	size = 0.5
          --},
          --{
          --	id = "console",
          --	size = 0.5
          --}
        },
        position = "bottom",
        size = 10,
      },
    },
    mappings = {
      edit = "e",
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      repl = "r",
      toggle = "t",
    },
    render = {
      indent = 1,
      max_value_lines = 100,
    },
  })

  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end

  local keymap_opts = { noremap = true, silent = true }

  vim.keymap.set("n", "<M-k>", require("dapui").eval, keymap_opts)
end

return {
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = true,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    dependencies = {
      "williamboman/mason.nvim",
      {
        "mfussenegger/nvim-dap",
      },
      "nvim-neotest/nvim-nio",
      {
        "leoluz/nvim-dap-go",
        opts = {
          type = "go",
          name = "Attach remote",
          mode = "remote",
          request = "attach",
        },
      },
      "mfussenegger/nvim-dap-python",
    },
    keys = require("keymaps").debug,
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("mason-nvim-dap").setup({
        automatic_installation = true,
        ensure_installed = {
          "python",
          "codelldb",
        },
        handlers = {},
      })

      dapui.setup({
        -- Set icons to characters that are more likely to work in every terminal.
        --    Feel free to remove or use ones that you like more! :)
        --    Don't feel like these are good choices.
        icons = require("utils.icons").debug.dapui,
        controls = {
          icons = require("utils.icons").debug.controls,
        },
      })

      -- Change breakpoint icons
      vim.api.nvim_set_hl(0, "DapBreak", { fg = "#e51400" })
      vim.api.nvim_set_hl(0, "DapStop", { fg = "#ffcc00" })
      local breakpoint_icons = vim.g.have_nerd_font
          and {
            Breakpoint = "",
            BreakpointCondition = "",
            BreakpointRejected = "",
            LogPoint = "",
            Stopped = "",
          }
        or {
          Breakpoint = "●",
          BreakpointCondition = "⊜",
          BreakpointRejected = "⊘",
          LogPoint = "◆",
          Stopped = "⭔",
        }
      for type, icon in pairs(breakpoint_icons) do
        local tp = "Dap" .. type
        local hl = (type == "Stopped") and "DapStop" or "DapBreak"
        vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
      end

      dap.listeners.after.event_initialized["dapui_config"] = dapui.open
      dap.listeners.before.event_terminated["dapui_config"] = dapui.close
      dap.listeners.before.event_exited["dapui_config"] = dapui.close

      -- Install golang specific config
      require("dap-go").setup({
        delve = {
          -- On Windows delve must be run attached or it crashes.
          -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
          detached = vim.fn.has("win32") == 0,
        },
      })

      local debugpyPythonPath = require("mason-registry").get_package("debugpy"):get_install_path()
        .. "/venv/bin/python3"
      require("dap-python").setup(debugpyPythonPath, {})
    end,
  },
}

-- NOTE 1
-- local setup = function()
-- 	local dap = require('dap')
--
-- 	dap.adapters.php = {
-- 		type = 'executable',
-- 		command = 'php-debug-adapter',
-- 	}
--
-- 	dap.configurations.php = {
-- 		{
-- 			type = 'php',
-- 			request = 'launch',
-- 			name = 'Listen for Xdebug',
-- 			port = 9003,
-- 			pathMappings = {
-- 				["/myposter"] = "${workspaceFolder}",
-- 				["/shop-backend"] = "${workspaceFolder}"
-- 			}
-- 		}
-- 	}
--
-- 	dap.adapters.delve = {
-- 		type = 'server',
-- 		port = '${port}',
-- 		executable = {
-- 			command = 'dlv',
-- 			args = { 'dap', '-l', '127.0.0.1:${port}' },
-- 		}
-- 	}
--
-- 	-- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
-- 	dap.configurations.go = {
-- 		{
-- 			type = "delve",
-- 			name = "Debug",
-- 			request = "launch",
-- 			program = "${workspaceFolder}/cmd/server/main.go",
-- 			env = {
-- 				CGO_CFLAGS_ALLOW = "-Xpreprocessor",
-- 				CACHE = "filesystem",
-- 				ENVIRONMENT = "development",
-- 				LOG_LEVEL = "info",
-- 				PORT = "8001"
-- 			}
-- 		},
-- 	}
--
-- 	local keymap_opts = {
--     noremap = true,
--     silent = true,
--   }
--
-- 	vim.keymap.set("n", "<F5>", function() dap.continue() end, keymap_opts)
-- 	vim.keymap.set("n", "<F9>", function() dap.toggle_breakpoint() end, keymap_opts)
-- 	vim.keymap.set("n", "<F10>", function() dap.step_over() end, keymap_opts)
-- 	vim.keymap.set("n", "<F11>", function() dap.step_into() end, keymap_opts)
-- 	vim.keymap.set("n", "<F12>", function() dap.step_out() end, keymap_opts)
-- end
--
-- return {
-- 	'mfussenegger/nvim-dap',
-- 	config = setup,
-- }
-- dap.adapters["pwa-node"] = {
--   type = "server",
--   host = "localhost",
--   port = "${port}",
--   executable = {
--     command = "node",
--     args = {
--       -- require("mason-registry").get_package("js-debug-adapter"):get_install_path()
--       -- .. "/js-debug/src/dapDebugServer.js", "${port}" }
--   }
-- },
-- for _, language in ipairs { "typescript", "javascript" } do
--   dap.configurations[language] = {
--     {
--       type = "pwa-node",
--       request = "launch",
--       name = "Launch file",
--       program = "${file}",
--       cwd = "${workspaceFolder}",
--       runtimeExecutable = "node",
--     },
--     {
--       type = "pwa-node",
--       request = "attach",
--       name = "Attach",
--       processId = require("dap.utils").pick_process,
--       cwd = "${workspaceFolder}",
--     },
--     {
--       type = "pwa-node",
--       request = "launch",
--       name = "Debug Jest Tests",
--       -- trace = true, -- include debugger info
--       runtimeExecutable = "node",
--       runtimeArgs = {
--         "./node_modules/jest/bin/jest.js",
--         "--runInBand",
--       },
--       rootPath = "${workspaceFolder}",
--       cwd = "${workspaceFolder}",
--       console = "integratedTerminal",
--       internalConsoleOptions = "neverOpen",
--     },
--   }
-- end

-- NOTE: 2
-- {
--    'mfussenegger/nvim-dap',
--    optional = true,
--    dependencies = {
--      {
--        'williamboman/mason.nvim',
--        opts = function(_, opts)
--          opts.ensure_installed = opts.ensure_installed or {}
--          table.insert(opts.ensure_installed, 'js-debug-adapter')
--        end,
--      },
--    },
--    opts = function()
--      local dap = require 'dap'
--      if not dap.adapters['pwa-node'] then
--        require('dap').adapters['pwa-node'] = {
--          type = 'server',
--          host = 'localhost',
--          port = '${port}',
--          executable = {
--            command = 'node',
--            args = {
--              vim.env.MASON
--                .. '/packages/'
--                .. 'js-debug-adapter'
--                .. '/js-debug/src/dapDebugServer.js',
--              '${port}',
--            },
--          },
--        }
--      end
--      if not dap.adapters['node'] then
--        dap.adapters['node'] = function(cb, config)
--          if config.type == 'node' then
--            config.type = 'pwa-node'
--          end
--          local nativeAdapter = dap.adapters['pwa-node']
--          if type(nativeAdapter) == 'function' then
--            nativeAdapter(cb, config)
--          else
--            cb(nativeAdapter)
--          end
--        end
--      end
--
--      local js_filetypes =
--        { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' }
--
--      local vscode = require 'dap.ext.vscode'
--      vscode.type_to_filetypes['node'] = js_filetypes
--      vscode.type_to_filetypes['pwa-node'] = js_filetypes
--
--      for _, language in ipairs(js_filetypes) do
--        if not dap.configurations[language] then
--          dap.configurations[language] = {
--            {
--              type = 'pwa-node',
--              request = 'launch',
--              name = 'Launch file',
--              program = '${file}',
--              cwd = '${workspaceFolder}',
--            },
--            {
--              type = 'pwa-node',
--              request = 'attach',
--              name = 'Attach',
--              processId = require('dap.utils').pick_process,
--              cwd = '${workspaceFolder}',
--            },
--          }
--        end
--      end
--    end,
--  }
