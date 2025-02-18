-- 
-- 
-- MAIN ENTRYPOINT !
-- THIS LUA FILE LOADS ALL OTHER LUA FILES
--
--

local CONSTANT_FRAMES_PER_SECOND = 60

-- this file is used by lite-xl to setup the Lua environment when starting
VERSION = "@PROJECT_VERSION@"
PROJECT_NAME="ofol"

SCALE = tonumber(os.getenv("LITE_SCALE") or os.getenv("GDK_SCALE") or os.getenv("QT_SCALE_FACTOR")) or 1
PATHSEP = package.config:sub(1, 1)

EXEDIR = EXEFILE:match("^(.+)[/\\][^/\\]+$")
if MACOS_RESOURCES then
  DATADIR = MACOS_RESOURCES
else
  local prefix = os.getenv('LITE_PREFIX') or EXEDIR:match("^(.+)[/\\]bin$")
  DATADIR = prefix and (prefix .. PATHSEP .. 'share' .. PATHSEP .. PROJECT_NAME) or (EXEDIR .. PATHSEP .. 'data')
end
USERDIR = (system.get_file_info(EXEDIR .. PATHSEP .. 'user') and (EXEDIR .. PATHSEP .. 'user'))
       or os.getenv("LITE_USERDIR")
       or ((os.getenv("XDG_CONFIG_HOME") and os.getenv("XDG_CONFIG_HOME") .. PATHSEP .. PROJECT_NAME))
       or (HOME and (HOME .. PATHSEP .. '.config' .. PATHSEP .. PROJECT_NAME))




package.path = DATADIR .. '/?.lua;'
package.path = DATADIR .. '/?/init.lua;' .. package.path
-- TODO: check if this is needed
-- package.path = USERDIR .. '/?.lua;' .. package.path
-- package.path = USERDIR .. '/?/init.lua;' .. package.path

-- do not load random .so files from many places
-- local suffix = PLATFORM == "Windows" and 'dll' or 'so'
-- package.cpath =
-- USERDIR .. '/?.' .. ARCH .. "." .. suffix .. ";" ..
-- USERDIR .. '/?/init.' .. ARCH .. "." .. suffix .. ";" ..
-- USERDIR .. '/?.' .. suffix .. ";" ..
-- USERDIR .. '/?/init.' .. suffix .. ";" ..
--   DATADIR .. '/?.' .. ARCH .. "." .. suffix .. ";" ..
--   DATADIR .. '/?/init.' .. ARCH .. "." .. suffix .. ";" ..
--   DATADIR .. '/?.' .. suffix .. ";" ..
--   DATADIR .. '/?/init.' .. suffix .. ";"

package.native_plugins = {}

-- do not load .so files from lua lib dir
-- local function search_for_module_in_these_directories(modname)
--   local path, err = package.searchpath(modname, package.cpath)
--   if not path then return err end
--   return system.load_native_plugin, path
-- end

-- limit package searcher to local diretories
package.searchers = { 
  package.searchers[1], 
  package.searchers[2], 

  -- do not load .so files from lua lib dir
  -- search_for_module_in_these_directories
}

table.pack = table.pack or pack or function(...) return {...} end
table.unpack = table.unpack or unpack

-- global include of fsutils
fsutils = require("lib.fsutils")

-- global include of stderr logging
stderr = require("lib.stderr")

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

-- strict variable checking
-- from core/strict.lua
local strict = {}
strict.defined = {}

-- used to define a global variable
-- function global(t)
--   for k, v in pairs(t) do
--     strict.defined[k] = true
--     rawset(_G, k, v)
--   end
-- end
function global(k,v)
  strict.defined[k] = true
  rawset(_G, k, v)
end

-- function strict.__newindex(t, k, v)
--   stderr.error("cannot SET undefined variable: " .. k)
-- end

function strict.__index(t, k)
  if not strict.defined[k] then
    stderr.error("cannot GET undefined variable: " .. k)
  end
end

setmetatable(_G, strict)



-- monkeypatch lua standard libraries
require "lib.lua-monkeypatch.lua-monkeypatch-bit32"
require "lib.lua-monkeypatch.lua-monkeypatch-string"
require "lib.lua-monkeypatch.lua-monkeypatch-math"
require "lib.lua-monkeypatch.lua-monkeypatch-regex"
require "lib.lua-monkeypatch.lua-monkeypatch-process"
require "lib.lua-monkeypatch.lua-monkeypatch-table"
require "lib.lua-monkeypatch.lua-monkeypatch-renderer"




-- Because AppImages change the working directory before running the executable,
-- we need to change it back to the original one.
-- https://github.com/AppImage/AppImageKit/issues/172
-- https://github.com/AppImage/AppImageKit/pull/191
local appimage_owd = os.getenv("OWD")
if os.getenv("APPIMAGE") and appimage_owd then
  system.chdir(appimage_owd)
end
