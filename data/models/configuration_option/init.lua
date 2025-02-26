-- base class for configuration options
-- this handles persistence while the extensions of this class handle type-specific validation
-- and ui component rendering

local Widget = require("lib.widget")
local Label = require("lib.widget.label")
local Button = require("lib.widget.button")

local style = require "themes.style"

local ConfigurationOption = Object:extend()

function ConfigurationOption:new(key, description_text_short, description_text_long, default_value, options)
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
  if default_value == nil then
    stderr.error("default value is required")
  end

  -- ensure that default value is valid
  self:validate(default_value)

  -- on_change_function() is optional
  -- it will be called when value has changed
  if options ~= nil and options.on_change ~= nil then
    -- ensure we have received a function
    if not Validator.is_function(options.on_change) then
      stderr.error("on_change must be a function")
    end

    -- store function
    self._optional_on_change_function = options.on_change
  end

  -- on_save_via_user_interface() is optional
  -- it will be called when value has changed to 
  -- convert the value before it is saved internally
  if options ~= nil and options.on_save_via_user_interface then
    -- ensure we have received a function
    if not Validator.is_function(options.on_save_via_user_interface) then
      stderr.error("on_save_via_user_interface must be a function")
    end

    -- store function
    self._optional_on_save_via_user_interface_function = options.on_save_via_user_interface
  end

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

-- return value of this configuration option
function ConfigurationOption:get_current_value()
  return self._current_value
end

-- return key of this configuration option
function ConfigurationOption:get_key()
  return self._key
end

-- set new value (called from ui)
function ConfigurationOption:set_value_from_ui(new_value)
  stderr.debug("VIA UI: ConfigurationOption %s set to %s", self._key, new_value)

  -- convert value from UI widget
  if self._optional_on_save_via_user_interface_function ~= nil then
    stderr.debug("calling self._optional_on_save_via_user_interface_function function with value", new_value)
    new_value = self._optional_on_save_via_user_interface_function(new_value)
    stderr.debug("new_value after self._optional_on_save_via_user_interface_function function =", new_value)
  end

  -- call internal set function
  self:set(new_value)
end


-- set new value for this configuration option
function ConfigurationOption:set(new_value)
  stderr.debug("ConfigurationOption %s set to %s", self._key, new_value)

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

-- reset value to default value
function ConfigurationOption:reset_to_default_value() 
  stderr.debug("ConfigurationOption %s reset to default value %s", self._key, self._default_value)
  self:set(self._default_value)
end

-- return true if current value is default value
function ConfigurationOption:is_default_value() 
  -- if type(self._default_value) == "table" then
  --   return json.encode(self._current_value) == json.encode(self._default_value)
  -- else
    return (self._current_value == self._default_value)
  -- end
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






-- render input form only
function ConfigurationOption:add_value_modification_widget_to_container(container)
  stderr.error("must not be called directly - it should be implemented in child class")
end

-- render short description text
function ConfigurationOption:_add_label_widget_to_container(container)
  -- add label with short description text
  local my_label = Label(container, self._description_text_short .. ":")

  -- use bold font for this label
  my_label.font = style.bold_font

  -- set lable color
  if self:is_default_value() then
    -- default color for default value
    my_label.foreground_color = style.dim
  else
    -- use different color if value has been modified
    my_label.foreground_color = style.accent
  end

  return my_label
end

-- render long description text
function ConfigurationOption:_add_description_widget_to_container(container)
  -- figure out text representation of default value
  local default_value_text
  if type(self._default_value) == "table" then
    -- for table values, use json
    default_value_text = json.encode(self._default_value)
  elseif type(self._default_value == "boolean") then
    if self._default_value == true then
      default_value_text = "true"
    else
      default_value_text = "false"
    end
  else
    -- all other types: convert to string with string.format()
    default_value_text = string.format("%s", self._default_value)
  end

  -- create label text
  local description_label_text = self._description_text_long .. " (default: " .. default_value_text .. ")"

  -- create widget and return it
  return Label(container, description_label_text)
end

-- render reset button for user-modified values
function ConfigurationOption:_add_reset_button_widget_to_container(container)
  -- create reset button
  local my_button = Button(container, "reset to default value")

  local outerSelf = self
  function my_button:on_mouse_pressed(button, x, y, clicks) 
    stderr.debug("my button on mouse pressed")
    outerSelf:reset_to_default_value()
  end

  return my_button
end

-- render widget, this needs to be overwritten by implementation
function ConfigurationOption:add_widgets_to_container(container)
  if not container then
    stderr.error("no widget provided")
  end

  -- render label on top of input
  local widget_label = self:_add_label_widget_to_container(container)

  -- render input ui element to change the configuration value
  local widget_modify_value = self:add_value_modification_widget_to_container(container)

  -- render description and default value after the input
  local widget_description = self:_add_description_widget_to_container(container)

  -- render button to reset value
  local widget_button_reset_value = self:_add_reset_button_widget_to_container(container)

  -- empty space between options
  local widget_line = Label(container, " ")

  return container
end




return ConfigurationOption