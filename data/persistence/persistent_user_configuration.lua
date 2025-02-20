local json_config_file = require "lib.json_config_file"

local PersistentUserConfiguration = {}

-- path for user settings
local PATH_USER_CONFIGURATION_JSON = USERDIR .. PATHSEP .. "user_configuration.json"

-- remember if already initialized
local has_been_initialized = false

-- store configuration in this file
local user_configuration

---Load config options from the USERDIR user_settings.lua and store them on
---settings.config for later usage.
function PersistentUserConfiguration.load_user_configuration()
  stderr.debug("loading user configuration from %s", PATH_USER_CONFIGURATION_JSON)
  return json_config_file.load_object_from_json_file(PATH_USER_CONFIGURATION_JSON)
end

-- error if not initialized
local function _fail_if_not_initialized() 
  if not has_been_initialized then
    stderr.error("must be initialized first")
  end
end

---Save current config options into the USERDIR user_settings.lua
function PersistentUserConfiguration.persist_to_disk()
  _fail_if_not_initialized()

  stderr.debug("saving user configuration to %s", PATH_USER_CONFIGURATION_JSON)
  json_config_file.save_object_to_json_file(user_configuration, PATH_USER_CONFIGURATION_JSON)
end

-- get configuration by key
function PersistentUserConfiguration.get(key)
  _fail_if_not_initialized()

  return user_configuration[key]
end

-- set configuration key
function PersistentUserConfiguration.set(key, val)
  _fail_if_not_initialized()

  -- set value
  user_configuration[key] = val

  -- store on disk
  PersistentUserConfiguration.persist_to_disk()
end

-- delete configuration key from user configuration
-- this is done when valueis changed back to the default value (e.g. we dont need to remember it)
function PersistentUserConfiguration.delete(key)
  _fail_if_not_initialized()

  -- set value to nil so it is deleted from the table
  user_configuration[key] = nil

  -- store on disk
  PersistentUserConfiguration.persist_to_disk()
end


-- initialize user configuration once at startup
local function _initialize() 
  -- error when already called
  if has_been_initialized then
    stderr.error("must not initialize more than one time")
  end

  -- load user configuration from disk
  has_been_initialized = true
  stderr.debug("user_configuration not loaded yet, loading now..")
  user_configuration = PersistentUserConfiguration.load_user_configuration()
end

-- load from disk
_initialize()

return PersistentUserConfiguration