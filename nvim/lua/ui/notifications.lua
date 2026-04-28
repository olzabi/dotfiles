local routes = {
  { filter = { find = "E31" }, skip = true },
  { filter = { find = "E37" }, skip = true },
  { filter = { find = "E162" }, view = "mini" },
  { filter = { event = "msg_show", find = "E211: File .* no longer available" }, skip = true },
  { filter = { event = "msg_show", find = "E486: Pattern not found" }, view = "mini" },
  { filter = { event = "msg_show", find = "search hit TOP" }, skip = true },
  { filter = { event = "msg_show", find = "search hit BOTTOM" }, skip = true },
  { filter = { event = "emsg", find = "E20" }, skip = true },
  { filter = { event = "emsg", find = "E23" }, skip = true },
  { filter = { find = "No signature help" }, skip = true },
  { filter = { find = "Error detected while processing BufReadPost Autocommands for" }, skip = true },
  {
    filter = {
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
  { filter = { event = "msg_show", find = "^%[nvim%-treesitter%]" }, view = "mini" },
  -- code actions / search (already covered by snacks filter, belt-and-suspenders)
  { filter = { event = "notify", find = "No code actions available" }, skip = true },
  { filter = { event = "notify", find = "All parsers are up%-to%-date" }, skip = true },
  { filter = { event = "msg_show", find = "^[/?]." }, skip = true },
}

local views = {
  split = { enter = true },
  mini = {
    timeout = 3000,
    zindex = 4,
    position = { col = -3 },
    format = { "{title}", "{message}" },
    win_options = { winblend = 0 },
  },
  cmdline_popup = {
    relative = "editor",
    position = { row = 26, col = "50%" },
    border = { style = vim.g.borderStyle },
  },
}

local lsp = {
  enabled = true,
  override = {
    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
    ["vim.lsp.util.stylize_markdown"] = true,
  },
  hover = { enabled = true },
  signature = { enabled = true },
  progress = { enabled = true, view = "mini", format = "lsp_progress" },
  message = { enabled = true, view = "mini" },
}

return {

  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      progress = {
        suppress_on_insert = true,
        ignore_done_already = false,
        ignore_empty_message = false,
      },
      notification = {
        override_vim_notify = false,
        window = {
          winblend = 0,
          border = "none",
        },
      },
    },
  },

  {
    "folke/noice.nvim",
    event = "VimEnter",
    dependencies = "MunifTanjim/nui.nvim",
    opts = {
      presets = {
        long_message_to_split = true,
        lsp_doc_border = false,
        inc_rename = true,
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
      notify = { enabled = false },
      lsp = lsp,
      views = views,
      routes = routes,
    },
    keys = {
      { "<leader>nh", function() Snacks.picker.notifications() end, desc = "Notifications" },
      { "<leader>nn", "<cmd>NoiceDismiss<cr>", desc = "Dismiss" },
      { "<leader>nH", "<cmd>Noice history<cr>", desc = "History" },
      { "<leader>nl", "<cmd>Noice last<cr>", desc = "Last message" },
    },
  },
}
