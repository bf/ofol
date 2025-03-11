-- pretty printing?

-- From gvx/Ser
local oddvals = {[tostring(1/0)] = "1/0", [tostring(-1/0)] = "-1/0", [tostring(-(0/0))] = "-(0/0)", [tostring(0/0)] = "0/0"}

local function serialize(val, pretty, indent_str, escape, sort, limit, level)
  local space = pretty and " " or ""
  local indent = pretty and string.rep(indent_str, level) or ""
  local newline = pretty and "\n" or ""
  local ty = type(val)
  if ty == "string" then
    local out = string.format("%q", val)
    if escape then
      out = string.gsub(out, "\\\n", "\\n")
      out = string.gsub(out, "\\7", "\\a")
      out = string.gsub(out, "\\8", "\\b")
      out = string.gsub(out, "\\9", "\\t")
      out = string.gsub(out, "\\11", "\\v")
      out = string.gsub(out, "\\12", "\\f")
      out = string.gsub(out, "\\13", "\\r")
    end
    return out
  elseif ty == "table" then
    -- early exit
    if level >= limit then return tostring(val) end
    local next_indent = pretty and (indent .. indent_str) or ""
    local t = {}
    for k, v in pairs(val) do
      table.insert(t,
        next_indent .. "[" ..
          serialize(k, pretty, indent_str, escape, sort, limit, level + 1) ..
        "]" .. space .. "=" .. space .. serialize(v, pretty, indent_str, escape, sort, limit, level + 1))
    end
    if #t == 0 then return "{}" end
    if sort then table.sort(t) end
    return "{" .. newline .. table.concat(t, "," .. newline) .. newline .. indent .. "}"
  end
  if ty == "number" then
    -- tostring is locale-dependent, so we need to replace an eventual `,` with `.`
    local res, _ = tostring(val):gsub(",", ".")
    -- handle inf/nan
    return oddvals[res] or res
  end
  return tostring(val)
end


---@class fsutils.serializeoptions
---@field pretty boolean Enables pretty printing.
---@field indent_str string The indentation character to use. Defaults to `"  "`.
---@field escape boolean Uses normal escape characters ("\n") instead of decimal escape sequences ("\10").
---@field limit number Limits the depth when serializing nested tables. Defaults to `math.huge`.
---@field sort boolean Sorts the output if it is a sortable table.
---@field initial_indent number The initial indentation level. Defaults to 0.

---Serializes a value into a Lua string that is loadable with load().
---
---Only these basic types are supported:
---* nil
---* boolean
---* number (except very large numbers and special constants, e.g. `math.huge`, `inf` and `nan`)
---* integer
---* string
---* table
---
---@param val any
---@param opts? fsutils.serializeoptions
---@return string
function serialize_public(val, opts)
  opts = opts or {}
  local indent_str = opts.indent_str or "  "
  local initial_indent = opts.initial_indent or 0
  local indent = opts.pretty and string.rep(indent_str, initial_indent) or ""
  local limit = (opts.limit or math.huge) + initial_indent
  return indent .. serialize(val, opts.pretty, indent_str,
                   opts.escape, opts.sort, limit, initial_indent)
end

return serialize_public
