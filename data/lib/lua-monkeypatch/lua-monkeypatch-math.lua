
-- math round functions
math.round = function (n)
  return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end

-- clamp value between min and max
math.clamp = function (n, lo, hi)
  return math.max(math.min(n, hi), lo)
end


---Returns a value between a and b on a linear scale, based on the
---interpolation point t.
---
---If a and b are tables, a table containing the result for all the
---elements in a and b is returned.
---@param a number
---@param b number
---@param t number
---@return number
---@overload fun(a: table, b: table, t: number): table
math.lerp = function (a, b, t)
  if type(a) ~= "table" then
    return a + (b - a) * t
  end
  local res = {}
  for k, v in pairs(b) do
    res[k] = math.lerp(a[k], v, t)
  end
  return res
end




---Returns the euclidean distance between two points.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
math.distance = function(x1, y1, x2, y2)
    return math.sqrt(((x2-x1) ^ 2)+((y2-y1) ^ 2))
end
