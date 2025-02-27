-- 
-- 
-- MAIN ENTRYPOINT !
-- THIS LUA FILE LOADS ALL OTHER LUA FILES
--
--

-- global fps variable
CONSTANT_FRAMES_PER_SECOND = 60


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

-- global include of stderr logging
stderr = require("lib.stderr")

-- global include of fsutils
fsutils = require("lib.fsutils")

-- global include for json
json = require("lib.json")

-- global include for json config file
json_config_file = require("lib.json_config_file")

-- global modification of module loading behavior when require() is called
require("lib.lua-monkeypatch.lua-monkeypatch-require-modules")

-- global try/catch functionality 
require("lib.lua-monkeypatch.lua-monkeypatch-try-catch")

-- global strict variable checking, e.g. error when undefined variable is set/get
require("lib.lua-monkeypatch.lua-monkeypatch-strict-variable-checking")

-- global monkeypatches for lua standard types and modules
require("lib.lua-monkeypatch.lua-monkeypatch-bit32")
require("lib.lua-monkeypatch.lua-monkeypatch-string")
require("lib.lua-monkeypatch.lua-monkeypatch-math")
require("lib.lua-monkeypatch.lua-monkeypatch-regex")
require("lib.lua-monkeypatch.lua-monkeypatch-process")
require("lib.lua-monkeypatch.lua-monkeypatch-table")

-- global monkeypatch for SDL3 C API
require("lib.lua-monkeypatch.lua-monkeypatch-renderer")

-- global include for base object 
Object = require("lib.object")

-- caching
Cache = require("lib.cache")
ConfigurationCache = Cache("ConfigurationCache")

-- global include of validator
Validator = require("lib.validator")

-- global include for user configuration
PersistentUserConfiguration = require("persistence.persistent_user_configuration")
ConfigurationOptionStore = require("stores.configuration_option_store")



-- Because AppImages change the working directory before running the executable,
-- we need to change it back to the original one.
-- https://github.com/AppImage/AppImageKit/issues/172
-- https://github.com/AppImage/AppImageKit/pull/191
local appimage_owd = os.getenv("OWD")
if os.getenv("APPIMAGE") and appimage_owd then
  system.chdir(appimage_owd)
end
