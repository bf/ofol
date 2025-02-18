local UserSettingsStore = require("stores.user_settings_store")

-- singleton object for settings store
local SettingsStore = {
  -- enum of different types
  TYPES = {
    STRING = 1,
    NUMBER = 2,
    TOGGLE = 3,
    SELECTION = 4,
    LIST_STRINGS = 5,
    BUTTON = 6,
    FONT = 7,
    FILE = 8,
    DIRECTORY = 9,
    COLOR = 10
  }
}

-- remember which data type a key has
local map_key_to_datatype = {}

-- remember default value for key
local map_key_to_default_value = {}

-- load user settings
local user_settings

-- initialize user settings if needed
local function _initialize_user_settings_once() 
  -- load user settings if they have not been loaded before
  if user_settings == nil then
    stderr.debug("user_settings not loaded yet, loading now..")
    user_settings = UserSettingsStore.load_user_settings()
  end
end

_initialize_user_settings_once() 

-- initialize a setting with default value
function SettingsStore.initialize_configuration_option(setting_key, setting_datatype, setting_default_value)
  -- ensure key has not been initialized before
  if map_key_to_datatype[setting_key] ~= nil then
    stderr.error("setting_key %s has already been initialized")
  end

  -- ensure type is supported
  if not table.contains(SettingsStore.TYPES, setting_datatype) then
    stderr.error("setting_key %s has unsupported datatype %s", setting_key, setting_datatype)
  end

  -- remember datatype for this key
  map_key_to_datatype[setting_key] = setting_datatype

  -- set default value
  if setting_default_value ~= nil then
    map_key_to_default_value[setting_key] = setting_default_value
  else
    -- warn if no default value provided
    stderr.warn("no default value provided for setting_key %s", setting_key)
  end
end

-- return true if setting has been changed by user
function SettingsStore.has_setting_been_changed_by_user(setting_key) 
  return user_settings[setting_key] ~= nil
end

-- check if key has been initialized
function SettingsStore.check_if_key_was_initialized(setting_key) 
  -- ensure key has been initialized already
  if map_key_to_datatype[setting_key] == nil then
    stderr.error("setting_key %s needs to be initialized before it can be retrieved")
  end
end

-- check if key has proper value for data type
function SettingsStore.check_if_value_is_valid_for_datatype(setting_key, setting_value) 
  local expected_datatype = map_key_to_datatype[setting_key]

  -- STRING validation
  if expected_datatype == SettingsStore.TYPES.STRING then
    -- either value has string type already or the tostring conversion function should exist
    if type(setting_value) ~= "string" and setting_value.__tostring == nil then
      stderr.error("setting_key %s needs string value, but received %s", setting_key, setting_value)
    end

    return true
  end

  -- NUMBER validation
  if expected_datatype == SettingsStore.TYPES.NUMBER then
    if not tonumber(setting_value) then
      stderr.error("setting_key %s needs number value, but received %s", setting_value)
    end

    return true
  end


  -- todo: implement
  stderr.warn("validation not implemented for datatype %s", expected_datatype)
  return true
end

-- retrieve setting by key
function SettingsStore.get(setting_key) 
  SettingsStore.check_if_key_was_initialized(setting_key)

  -- check if user settings contains key
  if SettingsStore.has_setting_been_changed_by_user(setting_key) then
    -- if yes, return user-specific value of this key
    return user_settings[setting_key]
  end

  -- check if there is default value for this key
  if map_key_to_default_value[setting_key] ~= nil then
    -- return default value
    return map_key_to_default_value[setting_key]
  end

  -- at this point we could either return nil or 
  -- throw error because it's better coding style to always have default value
  stderr.error("setting_key %s neither found in user settings nor it seems to have a default value", setting_key)
end


-- store a setting
function SettingsStore.set(setting_key, setting_value)
  SettingsStore.check_if_key_was_initialized(setting_key)

  SettingsStore.check_if_value_is_valid_for_datatype(setting_key, setting_value)

  -- fetch old value from user settings
  local old_value_from_user_settings = user_settings[setting_key]

  -- check if there is default value for this key
  if map_key_to_default_value[setting_key] ~= nil then
    -- check if default value equals new value
    if map_key_to_default_value[setting_key] == setting_value then
      -- don't store default value in user settings
      -- just delete value from user settings 
      -- because on .get() call it will return default value anyways
      user_settings[setting_key] = nil
    else
      -- new value is different than default value, so we store it in user settings
      user_settings[setting_key] = setting_value
    end
  else
    -- if there is no default value for this key, then just store it in user settings
    user_settings[setting_key] = setting_value
  end

  -- if user settings value has changed, then save user settings to disk
  if old_value_from_user_settings ~= user_settings[setting_key] then
    -- persist user settings to disk
    UserSettingsStore.save_user_settings(user_settings)
  end
end

return SettingsStore