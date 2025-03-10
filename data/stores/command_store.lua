-- singleton object for command store
local CommandStore = {}

-- remember which key is for which object
local _commands_by_key = {}

-- initialize a configuration option
function CommandStore.initialize_configuration_option(newConfigurationOption)
  if not newConfigurationOption:extends(ConfigurationOption) then
    stderr.error("newConfigurationOption needs to be derived from ConfigurationOption, but received %s", newConfigurationOption)
  end

  -- get configuration key
  local configuration_option_key = newConfigurationOption:get_key()

  -- ensure key has not been initialized before
  if _configuration_options_by_key[configuration_option_key] ~= nil then
    stderr.error("configuration option with key %s has already been initialized, cannot initialize a second time", configuration_option_key)
  end

  -- get group_key from configuration option 
  local group_key = newConfigurationOption:get_group_key()

  -- ensure group_key has been initialized 
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

-- retrieve all groups
function ConfigurationOptionStore.retrieve_all_groups()
  -- ensure at least one group exists
  if table.count(_groups_by_key) == 0 then
    stderr.error("no group exists, this is unexpected")
  end

  return _groups_by_key
end

-- retrieve all options for specific group
function ConfigurationOptionStore.retrieve_all_configuration_options_for_group_key(group_key)
  stderr.debug("retrieve_all_configuration_options_for_group_key", group_key)

  -- ensure group_key has been initialized 
  if _groups_by_key[group_key] == nil then
    stderr.error("group_key %s needs to be initialized first", group_key)
  end

  -- filter all options to find matching ones
  local function filter_function (item) 
    -- check if group key is same
    return item:get_group_key() == group_key
  end

  -- only get options for this group
  local options_for_group = table.filter(_configuration_options_by_key, filter_function)

  if table.count(options_for_group) == 0 then
    stderr.error("found zero options for group_key %s, this is unexpected", group_key)
  end

  return options_for_group
end

return ConfigurationOptionStore