local M = {}

local function animated_header()
  local dashboard = require("alpha.themes.dashboard")

  local function read_ascii_frames()
    -- local file = io.open("/home/alice/.config/dotfiles/nvim/alpha/strawhatsAscii.txt", "r")
    local file = io.open("/home/alice/.config/dotfiles/nvim/alpha/play_fmt.txt", "r")
    if not file then
      print("Could not open ASCII file")
      return {}
    end

    local frames = {}
    local current_frame = {}
    local in_frame = false

    for line in file:lines() do
      if line == "Frame:" then
        --if line == "SPLIT" then
        in_frame = true
      elseif line:match("^=+$") then -- Matches a line of equal signs
        if #current_frame > 0 then
          table.insert(frames, current_frame)
          current_frame = {}
        end
        in_frame = false
      elseif in_frame then
        table.insert(current_frame, line)
      end
    end

    -- Add the last frame if it exists
    if #current_frame > 0 then
      table.insert(frames, current_frame)
    end

    file:close()

    -- Debug message
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
      vim.schedule_wrap(function() -- 100ms between frames
        frame_index = (frame_index % #frames) + 1
        dashboard.section.header.val = frames[frame_index]
        require("alpha").redraw()
      end)
    )

    -- Stop timer when leaving alpha
    vim.api.nvim_create_autocmd("BufLeave", {
      pattern = "alpha",
      callback = function()
        timer:stop()
      end,
    })
  end

  -- Disable folding on alpha buffer
  vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])

  -- Replace the headers section with:
  local frames = read_ascii_frames()
  dashboard.section.header.val = frames[1] or {} -- Set first frame as default

  -- Start animation after alpha setup
  vim.api.nvim_create_autocmd("User", {
    pattern = "AlphaReady",
    callback = function()
      create_animation_timer(dashboard)
    end,
  })
end

M.config = function()
  local alpha = require("alpha")
  local dashboard = require("alpha.themes.dashboard")
  local config_dir = vim.fn.stdpath("config")

  local author_section = {
    type = "text",
    val = "by olzabi",
    opts = {
      position = "center",
      hl = "HeaderInfo",
    },
  }

  local function footer()
    -- TODO: wh40k ... etc, quotes
    local plugins = require("lazy").stats().count
    local v = vim.version()
    return {
      "",
      string.format(" v%d.%d.%d  󰂖 %d", v.major, v.minor, v.patch, plugins),
      "",
    }
  end
  dashboard.section.footer.val = footer()

  dashboard.section.buttons.val = {
    dashboard.button("<leader><leader>", "  > Smart", "<cmd>lua Snacks.picker.smart()<cr>"),
    dashboard.button("p", "󰥨  > Projects", "<cmd>lua Snacks.picker.projects()<cr>"),
    dashboard.button("r", "  > Recent files", "<cmd>lua Snacks.picker.recent()<cr>"),
    dashboard.button("c", "  > Configuration", string.format("<cmd>e %s<cr>", config_dir)),
    dashboard.button("l", "󰏓  > Lazy", "<cmd>Lazy<cr>"),
    dashboard.button("q", "  > Quit", "<cmd>qa<cr>"),
  }

  dashboard.opts.layout = {
    { type = "padding", val = 3 },
    dashboard.section.header,
    { type = "padding", val = 2 },
    dashboard.section.buttons,
    { type = "padding", val = 3 },
    author_section,
    dashboard.section.footer,
  }

  alpha.setup(dashboard.opts)

  animated_header()
end

return M
