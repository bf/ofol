
---Parses a CSS color string.
---
---Only these formats are supported:
---* `rgb(r, g, b)`
---* `rgba(r, g, b, a)`
---* `#rrggbbaa`
---* `#rrggbb`
---@param str string
---@return number r
---@return number g
---@return number b
---@return number a
local color_from_css_string = function (str)
  local r, g, b, a = str:match("^#(%x%x)(%x%x)(%x%x)(%x?%x?)$")
  if r then
    r = tonumber(r, 16)
    g = tonumber(g, 16)
    b = tonumber(b, 16)
    a = tonumber(a, 16) or 0xff
  elseif str:match("rgba?%s*%([%d%s%.,]+%)") then
    local f = str:gmatch("[%d.]+")
    r = (f() or 0)
    g = (f() or 0)
    b = (f() or 0)
    a = (f() or 1) * 0xff
  else
    stderr.error("bad color string '%s'", str)
  end
  return r, g, b, a
end

return color_from_css_string