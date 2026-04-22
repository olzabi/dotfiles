_G.merge = function(...)
  local result = {}
  local sources = { ... }
  for i = 1, #sources do
    local source = sources[i]
    for key, value in pairs(source) do
      result[key] = value
    end
  end
  return result
end
