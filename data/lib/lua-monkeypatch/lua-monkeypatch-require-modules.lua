local lua_require = require
local require_stack = { "" }

---Loads the given module, returns any value returned by the searcher (`true` when `nil`).
---Besides that value, also returns as a second result the loader data returned by the searcher,
---which indicates how `require` found the module.
---(For instance, if the module came from a file, this loader data is the file path.)
---
---This is a variant that also supports relative imports.
---
---For example `require ".b"` will require `b` in the same path of the current
---file.
---This also supports multiple levels traversal. For example `require "...b"`
---will require `b` from two levels above the current one.
---This method has a few caveats: it uses the last `require` call to get the
---current "path", so this only works if the relative `require` is called inside
---its parent `require`.
---Calling a relative `require` in a function called outside the parent
---`require`, will result in the wrong "path" being used.
---
---It's possible to save the current "path" with `get_current_require_path`
---called inside the parent `require`, and use its return value to populate
---future requires.
---@see get_current_require_path
---@param modname string
---@return unknown
---@return unknown loaderdata
function require(modname, ...)
  if modname then
    local level, rel_path = string.match(modname, "^(%.*)(.*)")
    level = #(level or "")
    
    if level > 0 then
      if #require_stack == 0 then
        return stderr.error("Require stack underflowed.")
      else
        local base_path = require_stack[#require_stack]
        -- stderr.info(string.format("[start.lua] require(%d): %s\tbase_path before: %s", level, modname, base_path))
        while level > 1 do
          base_path = string.match(base_path, "^(.*)%.") or ""
          level = level - 1
        end
        -- stderr.info(string.format("[start.lua] require(%d): %s\tbase_path after: %s", level, modname, base_path))
        modname = base_path
        if #base_path > 0 then
          modname = modname .. "."
        end
        modname = modname .. rel_path
      end
    else
      -- stderr.info(string.format("[start.lua] require(%d): %s\trel_path: %s", level, modname, rel_path))
    end
  else
    stderr.error("[start.lua] require called without modname?")
  end

  -- increase require stack
  table.insert(require_stack, modname)

  -- try to load required module
  local ok, result, loaderdata = pcall(lua_require, modname, ...)

  -- decrease require stack
  table.remove(require_stack)

  -- handle module loading error
  if not ok then
    stderr.error(string.format("[start.lua] require(%s): %s", modname, result))
    return error(result)
  end

  return result, loaderdata
end


-- reload a lua module at runtime
-- previously core.reload_module()
function reload_module(name)
  stderr.warn_backtrace("reloading module %s", name)
  local old = package.loaded[name]
  package.loaded[name] = nil
  local new = require(name)
  if type(old) == "table" then
    for k, v in pairs(new) do old[k] = v end
    package.loaded[name] = old
  end
end


---Returns the current `require` path.
---@see require for details and caveats
---@return string
function get_current_require_path()
  return require_stack[#require_stack]
end