local ConfigurationOption = require("models.configuration_option")

-- singleton object for settings store
local ConfigurationStore = {}

  -- -- export enum of different types
  -- TYPES = {
  --   STRING = 1,
  --   NUMBER = 2,
  --   TOGGLE = 3,
  --   SELECTION = 4,
  --   LIST_STRINGS = 5,
  --   BUTTON = 6,
  --   FONT = 7,
  --   FILE = 8,
  --   DIRECTORY = 9,
  --   COLOR = 10
  -- },

  -- VALIDATORS = {
  --   STRING = {function (val_str)  return (type(val_str) == "string" or val_str.__tostring ~= nil) end},
  --   NUMBER = {function (val_num)  return (type(val) == "string" or val.__tostring ~= nil) end},
  -- }

-- remember which key is for which object
local configuration_options_by_key = {}

-- check if key has been initialized
function ConfigurationStore.check_if_configuration_option_was_initialized(configuration_key) 
  -- ensure key has been initialized already
  if configuration_options_by_key[configuration_key] == nil then
    stderr.error("configuration_key %s needs to be initialized before it can be retrieved", configuration_key)
  end
end

-- initialize a setting with default value
function ConfigurationStore.initialize_configuration_option(newConfigurationOption)
  if not newConfigurationOption:extends(ConfigurationOption) then
    stderr.error("newConfigurationOption needs to be derived from ConfigurationOption, but received %s", newConfigurationOption)
  end

  -- get configuration key
  local configuration_key = newConfigurationOption:get_key()

  -- ensure key has not been initialized before
  if configuration_options_by_key[configuration_key] ~= nil then
    stderr.error("key %s has already been initialized, cannot initialize a second time")
  end

  -- add to store
  configuration_options_by_key[configuration_key] = newConfigurationOption
end


-- retrieve setting by key
function ConfigurationStore.get(configuration_key) 
  -- ensure key exists
  ConfigurationStore.check_if_configuration_option_was_initialized(configuration_key)

  return configuration_options_by_key[configuration_key]
end

-- lazy getter function, returns function to retrieve config value
function ConfigurationStore.lazy_get_current_value(configuration_key)
  return function()
    return ConfigurationStore.get(configuration_key):get_current_value()
  end
end



return ConfigurationStore