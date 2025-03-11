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
require("entrypoint.global_constants")

-- global variables
require("entrypoint.global_variables")

-- global includes
require("entrypoint.global_includes")


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

