
---Returns a new table containing the contents of b merged into a.
---@param a table|nil
---@param b table?
---@return table
function table.merge(a, b)
  a = type(a) == "table" and a or {}
  local t = {}
  for k, v in pairs(a) do
    t[k] = v
  end
  if b and type(b) == "table" then
    for k, v in pairs(b) do
      t[k] = v
    end
  end
  return t
end
