local M = {}

M.has = function(...)
  for _, name in ipairs({ ... }) do
    if vim.fn.executable(name) == 0 then
      return false
    end
  end
  return true
end

M.get_typescript_sdk = function()
  local local_sdk = vim.fn.getcwd() .. "/node_modules/typescript/lib"
  if vim.fn.isdirectory(local_sdk) == 1 then
    return local_sdk
  end
  -- Try global installation
  local global_root = vim.fn.system("npm root -g"):gsub("\n", ""):gsub("\r", "")
  local global_sdk = global_root .. "/typescript/lib"
  if vim.fn.isdirectory(global_sdk) == 1 then
    return global_sdk
  end

  -- If both fail, return nil to let vue-language-server find it automatically
  return nil
end

return M
