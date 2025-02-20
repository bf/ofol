-- base class for configuration options
-- this handles persistence while the extensions of this class handle type-specific validation
-- and ui component rendering

local ConfigurationOption = Object:extend()

function ConfigurationOption:new(key, description_text_short, description_text_long, default_value, optional_on_change_function)
  -- ensure key is provided
  if not key or not Validator.is_string(key) then
    stderr.error("key is required")
  end

  -- ensure description_text_short is provided and is a string
  if not description_text_short or not Validator.is_string(description_text_short) then
    stderr.error("description_text_short must be a string")
  end

  -- ensure description_text_long is provided and is a string
  if not description_text_long or not Validator.is_string(description_text_long) then
    stderr.error("description_text_long must be a string")
  end

  -- ensure default value is provided
  if not default_value then
    stderr.error("default value is required")
  end

  -- on_change_function() is optional
  -- it will be called when value has changed
  if optional_on_change_function ~= nil then
    -- ensure we have received a function
    if not Validator.is_function(optional_on_change_function) then
      stderr.error("optional_on_change_function must be a function")
    end

    -- store function
    self._optional_on_change_function = optional_on_change_function
  end

  -- ensure that default value is valid
  self:validate(default_value)

  -- initialize member variables
  self._key = key
  self._default_value = default_value
  self._description_text_short = description_text_short
  self._description_text_long = description_text_long

  -- load user-customized value from persistent storage
  local value_modified_by_user = PersistentUserConfiguration.get(self._key)

  -- check if user-customized value exists
  if value_modified_by_user ~= nil then
    stderr.debug("ConfigurationOption %s value_modified_by_user %s", self._key, value_modified_by_user)

    -- ensure that user-customized value is valid
    self:validate(value_modified_by_user)

    -- initialize with user-customized value
    self._current_value = value_modified_by_user
  else
    stderr.debug("ConfigurationOption %s default_value %s", self._key, self._default_value)

    -- otherwise, initialize with default value
    self._current_value = self._default_value
  end

  -- add this configuraiton option to the global configuration storage 
  ConfigurationStore.initialize_configuration_option(self)

  -- run on change function if it has been defined
  self:run_on_change_function_if_exists()
end

-- overwrite toString method
function ConfigurationOption:__tostring()
  return "ConfigurationOption for " .. self._key
end

-- run optional on change function if needed
function ConfigurationOption:run_on_change_function_if_exists()
  if self._optional_on_change_function ~= nil then
    stderr.debug("ConfigurationOption %s running on_change_function for new value %s", self._key, self._current_value)
    self._optional_on_change_function(self._current_value)
  end
end

-- render widget, this needs to be overwritten by implementation
function ConfigurationOption:add_to_widget()
  stderr.error("must not be called directly - it should be implemented in child class")
end

-- return value of this configuration option
function ConfigurationOption:get_current_value()
  return self._current_value
end

-- return key of this configuration option
function ConfigurationOption:get_key()
  return self._key
end

-- set new value for this configuration option
function ConfigurationOption:set(new_value)
  -- ensure new value is valid
  self:validate(new_value)

  -- store new value internally
  self._current_value = new_value

  -- check if new value is default value
  if self:is_default_value() then
    -- when it is default value, we need to remove it from the user settings
    PersistentUserConfiguration.delete(self._key)
  else
    -- when it is modified by user, we need to persist it
    PersistentUserConfiguration.set(self._key, self._current_value)
  end

  -- run on change function if it has been defined
  self:run_on_change_function_if_exists()
end

-- return true if current value is default value
function ConfigurationOption:is_default_value() 
  return (self._current_value == self._default_value)
end

-- return true if current value has been modified by user
function ConfigurationOption:is_customized_value()
  return not self:is_default_value()
end

-- return true if value is valid
function ConfigurationOption:is_valid(val)
  stderr.error("must not be called directly - it should be implemented in child class")
end

-- throw error on invalid value
function ConfigurationOption:validate(val)
  -- use is_valid() to check if it can be used
  if not self:is_valid(val) then
    -- fatal error on invalid value
    stderr.error("key %s: value %s is not valid", self._key, val)
  end
end

return ConfigurationOption