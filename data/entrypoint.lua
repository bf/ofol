-- 
-- 
-- MAIN ENTRYPOINT !
-- THIS LUA FILE LOADS ALL OTHER LUA FILES
--
--

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


-- global constants
require("lib.global_constants")

-- global variables
require("lib.global_variables")


-- global include of stderr logging
stderr = require("lib.stderr")

-- threading code
threading = require("lib.threading")

-- graphics/rendering rect clipping code
clipping = require("lib.clipping")

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

-- global include of validator
Validator = require("lib.validator")

-- global include for user configuration
PersistentUserConfiguration = require("persistence.persistent_user_configuration")
ConfigurationOptionStore = require("stores.configuration_option_store")

-- load available configuration options
require("configuration")



-- Because AppImages change the working directory before running the executable,
-- we need to change it back to the original one.
-- https://github.com/AppImage/AppImageKit/issues/172
-- https://github.com/AppImage/AppImageKit/pull/191
local appimage_owd = os.getenv("OWD")
if os.getenv("APPIMAGE") and appimage_owd then
  system.chdir(appimage_owd)
end

-- global var core already defined as "nil" in src/main.c
core = require("core")
core.init()
core.run()

