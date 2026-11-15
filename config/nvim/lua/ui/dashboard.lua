local function animated_header()
  local dashboard = require "alpha.themes.dashboard"

  local function read_ascii_frames()
    local file = io.open(vim.fn.stdpath "config" .. "/alpha/play_fmt.txt", "r")
    if not file then
      print "Could not open ASCII file"
      return {}
    end

    local frames = {}
    local current_frame = {}
    local in_frame = false

    for line in file:lines() do
      if line == "Frame:" then
        --if line == "SPLIT" then
        in_frame = true
      elseif line:match "^=+$" then
        if #current_frame > 0 then
          table.insert(frames, current_frame)
          current_frame = {}
        end
        in_frame = false
      elseif in_frame then
        table.insert(current_frame, line)
      end
    end

    if #current_frame > 0 then
      table.insert(frames, current_frame)
    end

    file:close()
    print("Loaded " .. #frames .. " frames")
    return frames
  end

  local function create_animation_timer(dashboard)
    local frames = read_ascii_frames()
    if #frames == 0 then
      return
    end

    local timer = vim.loop.new_timer()
    local frame_index = 1

    timer:start(
      0,
      100,
      vim.schedule_wrap(function()
        frame_index = (frame_index % #frames) + 1
        dashboard.section.header.val = frames[frame_index]
        require("alpha").redraw()
      end)
    )

    vim.api.nvim_create_autocmd("BufLeave", {
      pattern = "alpha",
      callback = function()
        timer:stop()
      end,
    })
  end

  vim.cmd [[autocmd FileType alpha setlocal nofoldenable]]

  local frames = read_ascii_frames()
  dashboard.section.header.val = frames[1] or {}

  vim.api.nvim_create_autocmd("User", {
    pattern = "AlphaReady",
    callback = function()
      create_animation_timer(dashboard)
    end,
  })
end

return {
  {
    "goolord/alpha-nvim",
    lazy = false,
    event = { "VimEnter", "BufWinEnter" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      local config_dir = vim.fn.stdpath("config")

      local author_section = {
        type = "text",
        val = "by [your name]",
        opts = {
          position = "center",
          hl = "HeaderInfo",
        },
      }

      local function footer()
        local plugins = require("lazy").stats().count
        local v = vim.version()
        return {
          "",
          string.format(" v%d.%d.%d  󰂖 %d", v.major, v.minor, v.patch, plugins),
          "",
        }
      end
      local function buttons()
        return {
        dashboard.button("<leader><leader>", "  > Files", "<cmd>lua require('fff').find_files()<cr>"),
        dashboard.button("g", "󰱼  > Grep", "<cmd>lua require('fff').live_grep()<cr>"),
        dashboard.button("r", "  > Resume files", "<cmd>lua require('fff').find_files({ resume = true })<cr>"),
        dashboard.button("s", "  > Restore Session", "<cmd>lua require('persistence').load()<cr>"),
        dashboard.button("S", "  > Last Session", "<cmd>lua require('persistence').load({ last = true })<cr>"),
        dashboard.button("c", "  > Configuration", string.format("<cmd>e %s<cr>", config_dir)),
        dashboard.button("l", "󰏓  > Lazy", "<cmd>Lazy<cr>"),
        dashboard.button("q", "  > Quit", "<cmd>qa<cr>"),
      }
      end
      local function layout()
        dashboard.section.footer.val = footer
        dashboard.section.buttons.val = buttons

        return {
        { type = "padding", val = 3 },
        dashboard.section.header,
        { type = "padding", val = 2 },
        dashboard.section.buttons,
        { type = "padding", val = 3 },
        author_section,
        dashboard.section.footer,
      }
      end

      dashboard.opts.layout = layout()
      alpha.setup(dashboard.opts)

      animated_header()
    end,
  },
}
