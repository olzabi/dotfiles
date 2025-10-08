local M = {}

local routes = {
  { filter = { find = "E31" }, skip = true },
  { filter = { find = "E37" }, skip = true },
  { filter = { find = "E162" }, view = "mini" },
  -- E211 no longer needed, since auto-closing deleted buffers
  { filter = { event = "msg_show", find = "E211: File .* no longer available" }, skip = true },
  -- search pattern not found
  { filter = { event = "msg_show", find = "E486: Pattern not found" }, view = "mini" },
  { filter = { event = "msg_show", find = "search hit TOP" }, skip = true },
  { filter = { event = "msg_show", find = "search hit BOTTOM" }, skip = true },
  { filter = { event = "emsg", find = "E20" }, skip = true },
  { filter = { event = "emsg", find = "E23" }, skip = true },
  { filter = { find = "No signature help" }, skip = true },
  { filter = { find = "Error detected while processing BufReadPost Autocommands for" }, skip = true },
  {
    filter = {
      -- write/deletion messages
      event = "msg_show",
      any = {
        { find = "%d+L, %d+B" },
        { find = "; after #%d+" },
        { find = "; before #%d+" },
        { find = "%-%-No lines in buffer%-%-" },
        { find = "%d+B written$" },
        { find = "yanked" },
      },
    },
    view = "mini",
  },
  {
    -- LSP
    filter = { event = "notify", find = "Restarting…" },
    view = "mini",
  },
  {
    filter = {
      event = "msg_show",
      any = {
        { find = "%d+ changes?; %a+ #%d+" },
        { find = "1 more line" },
        { find = "%d+ more lines" },
        { find = "%d+ fewer lines" },
        { find = "^Already at %a+ change$" },
      },
    },
    view = "mini",
  },
  -- nvim-treesitter
  { filter = { event = "msg_show", find = "^%[nvim%-treesitter%]" }, view = "mini" },
  { filter = { event = "notify", find = "All parsers are up%-to%-date" }, view = "mini" },
  -- code actions
  { filter = { event = "notify", find = "No code actions available" }, skip = true },
  { filter = { event = "msg_show", find = "^[/?]." }, skip = true },
}

local views = {
  split = {
    enter = true,
  },
  mini = {
    timeout = 3000,
    zindex = 4,
    position = { col = -3 },
    format = { "{title}", "{message}" },
    win_options = { winblend = 0 },
  },
  cmdline_popup = {
    relative = "editor",
    position = {
      row = 26,
      col = "50%",
    },
    -- size = {
    --   width = 60,
    --   height = "auto",
    --   max_height = 15
    -- },
    border = {
      style = vim.g.borderStyle,
    },
  },
}

local lsp = {
  enabled = true,
  override = {
    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
    ["vim.lsp.util.stylize_markdown"] = true,
    ["cmp.entry.get_documentation"] = true,
  },
  hover = { enabled = true },
  signature = { enabled = true },
  progress = { enabled = true },
  message = { enabled = true, view = "mini" },
}

M.opts = {
  presets = {
    long_message_to_split = true,
    lsp_doc_border = false,
    inc_rename = false,
    command_palette = false,
    bottom_search = false,
  },
  messages = {
    enabled = true,
    view = "mini",
    view_error = "mini",
    view_warn = "mini",
    view_history = "mini",
    view_search = "mini",
  },
  notify = {
    enabled = true,
    view = "mini",
  },
  lsp = lsp,
  views = views,
  routes = routes,
}

return M
