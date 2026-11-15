return {
  name = "hexcolors",
  dir = vim.fn.stdpath("config"), -- local "plugin"; no code is loaded from it
  event = { "BufReadPost", "BufNewFile" },

  config = function()
    vim.o.termguicolors = true

    local opts = {
      three_digit = false, -- set true to also highlight #rgb (can false-positive on things like "#123")
    }

    local ns = vim.api.nvim_create_namespace("hexcolors")
    local seen = {}     -- highlight groups already created
    local attached = {} -- buffers with an on_lines watcher

    local function group(hex)
      local name = "HexColor_" .. hex
      if not seen[name] then
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)
        local light = (0.299 * r + 0.587 * g + 0.114 * b) > 150
        vim.api.nvim_set_hl(0, name, { bg = "#" .. hex, fg = light and "#000000" or "#ffffff" })
        seen[name] = true
      end
      return name
    end

    local function eligible(buf)
      return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == ""
    end

    -- Re-highlight lines [first, last) (0-indexed, end-exclusive). Defaults to the whole buffer.
    local function colorize(buf, first, last)
      if not eligible(buf) then
        return
      end
      local count = vim.api.nvim_buf_line_count(buf)
      first = math.max(first or 0, 0)
      last = math.min(last or count, count)
      if first >= last then
        return
      end

      vim.api.nvim_buf_clear_namespace(buf, ns, first, last)

      for i, text in ipairs(vim.api.nvim_buf_get_lines(buf, first, last, false)) do
        local row = first + i - 1
        local init = 1
        while true do
          local s, e, digits = text:find("#(%x+)", init)
          if not s then
            break
          end
          init = e + 1

          local len = #digits
          local prev = s > 1 and text:sub(s - 1, s - 1) or ""
          local ok_prev = not prev:match("[%w_]") -- skip things like foo#abcdef

          if ok_prev then
            local rgb
            if len == 6 or len == 8 then
              rgb = digits:sub(1, 6) -- alpha is dropped: nvim highlights can't blend
            elseif len == 3 and opts.three_digit then
              rgb = digits:gsub(".", "%0%0")
            end

            if rgb then
              vim.api.nvim_buf_set_extmark(buf, ns, row, s - 1, {
                end_col = e,
                hl_group = group(rgb:lower()),
              })
            end
          end
        end
      end
    end

    local function attach(buf)
      if attached[buf] or not eligible(buf) then
        return
      end
      attached[buf] = true
      colorize(buf)

      vim.api.nvim_buf_attach(buf, false, {
        on_lines = function(_, b, _, first, _, new_last)
          if not attached[b] then
            return true -- detach
          end
          -- buffer text can't be safely touched mid-callback; defer
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(b) then
              colorize(b, first, new_last + 1)
            end
          end)
        end,
        on_reload = function(_, b)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(b) then
              colorize(b)
            end
          end)
        end,
        on_detach = function(_, b)
          attached[b] = nil
        end,
      })
    end

    local aug = vim.api.nvim_create_augroup("HexColors", { clear = true })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter" }, {
      group = aug,
      callback = function(a)
        attach(a.buf)
      end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
      group = aug,
      callback = function()
        seen = {} -- colorschemes can wipe custom groups; recreate lazily
        for buf in pairs(attached) do
          colorize(buf)
        end
      end,
    })

    attach(vim.api.nvim_get_current_buf()) -- the buffer that triggered the lazy load
  end,
}
