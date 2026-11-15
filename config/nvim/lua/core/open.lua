-- gx / LSP document links go through vim.ui.open. xdg-open on this machine sends
-- directories to disktree and text files to a terminal vim, so handle paths here:
-- text files open in this nvim, directories in yazi; URLs and everything else go to xdg-open
-- (firefox for http(s), chromium for pdf/images).
local xdg_open = vim.ui.open

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.open = function(target, opts)
  if target:match "^%a[%w+.-]*://" then return xdg_open(target, opts) end
  local path = vim.fs.normalize((target:gsub("^file://", "")))
  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == "directory" then
    require("yazi").yazi(nil, path)
    return nil, nil
  end
  if stat and vim.fn.executable "file" == 1 and vim.fn.system({ "file", "-b", "--mime-type", path }):match "^text/" then
    vim.cmd.edit(vim.fn.fnameescape(path))
    return nil, nil
  end
  return xdg_open(target, opts)
end
