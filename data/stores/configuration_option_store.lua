local ConfigurationOption = require("models.configuration_option")
local ConfigurationGroup = require("models.configuration_group")

-- singleton object for settings store
local ConfigurationOptionStore = {}

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
local _configuration_options_by_key = {}

-- remember which key is for which group
local _groups_by_key = {}



-- ensure configuration option key contains exactly one period (".")
local function _check_if_configuration_option_key_contains_exactly_one_period(configuration_option_key)
  -- Count the number of periods in the string
  local count = 0
  for _ in string.gmatch(configuration_option_key, "%.") do
      count = count + 1
  end

  if count ~= 1 then
    stderr.error("configuration_option_key %s needs to contain exactly one period")
  end
end

-- get group_key from a given configuration_option_key (first part until period ".")
local function _extract_group_key_from_configuration_option_key(configuration_option_key) 
  -- ensure configuration option key has a group key
  _check_if_configuration_option_key_contains_exactly_one_period(configuration_option_key)

  -- return first part of string until period
  return string.match(configuration_option_key, "^[^.]+")
end


-- initialize a configuration option
function ConfigurationOptionStore.initialize_configuration_option(newConfigurationOption)
  if not newConfigurationOption:extends(ConfigurationOption) then
    stderr.error("newConfigurationOption needs to be derived from ConfigurationOption, but received %s", newConfigurationOption)
  end

  -- get configuration key
  local configuration_option_key = newConfigurationOption:get_key()

  -- ensure key has not been initialized before
  if _configuration_options_by_key[configuration_option_key] ~= nil then
    stderr.error("configuration option with key %s has already been initialized, cannot initialize a second time", configuration_option_key)
  end

  -- fetch group_key from configuration option key
  local group_key = _extract_group_key_from_configuration_option_key(configuration_option_key)

  -- ensure group_key has been initialized already
  if _groups_by_key[group_key] == nil then
    stderr.error("group_key %s needs to be initialized before configuration option %s can be defined for this group", group_key, configuration_option_key)
  end

  -- add to store
  _configuration_options_by_key[configuration_option_key] = newConfigurationOption

  -- define dynamic getter function
  -- e.g. for key "editor.max_lines" -> ConfigurationOptionStore.get_editor_max_lines()
  local _getter_function_name = "get_" ..  string.gsub(configuration_option_key, "%.", "_")

  -- sanity check
  if ConfigurationOptionStore[_getter_function_name] ~= nil then
    stderr.error("_getter_function_name %s already exists, this should never happen. seen with configuration_option_key %s", _getter_function_name, configuration_option_key)
  end

  -- logic for dynamic getter function
  ConfigurationOptionStore[_getter_function_name] = function () 
    -- return value for configuration_option_key
    return newConfigurationOption:get_current_value()
  end

  stderr.debug("initialized getter function %s()", _getter_function_name)
end

-- initialize a group of configuration options
function ConfigurationOptionStore.initialize_configuration_group(newConfigurationGroup)
  if not newConfigurationGroup:extends(ConfigurationGroup) then
    stderr.error("newConfigurationGroup needs to be derived from ConfigurationGroup, but received %s", newConfigurationGroup)
  end

  -- get configuration key
  local group_key = newConfigurationGroup:get_group_key()

  -- ensure key has not been initialized before
  if _groups_by_key[group_key] ~= nil then
    stderr.error("group with key %s has already been initialized, cannot initialize a second time")
  end

  -- add to store
  _groups_by_key[group_key] = newConfigurationGroup
end

-- retrieve setting by key
function ConfigurationOptionStore.get(configuration_option_key) 
  stderr.deprecated()

  -- ensure key has been initialized already
  if _configuration_options_by_key[configuration_option_key] == nil then
    stderr.error("configuration_option_key %s needs to be initialized before it can be retrieved", configuration_option_key)
  end

  return _configuration_options_by_key[configuration_option_key]
end

return ConfigurationOptionStore