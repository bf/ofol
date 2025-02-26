-- base class for configuration options
-- this handles persistence while the extensions of this class handle type-specific validation
-- and ui component rendering

local Widget = require("lib.widget")
local Label = require("lib.widget.label")
local Line = require("lib.widget.line")
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
  if not default_value then
    stderr.error("default value is required")
  end

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

-- render input form only
function ConfigurationOption:add_value_modification_widget_to_container(container)
  stderr.error("must not be called directly - it should be implemented in child class")
end

-- render short description text
function ConfigurationOption:_add_label_widget_to_container(container)
  -- add label with short description text
  local my_label = Label(container, self._description_text_short .. ":")
  my_label.font = style.bold_font

  return my_label
end

-- render long description text
function ConfigurationOption:_add_description_widget_to_container(container)
  -- add description label
  local description = Label(container, self._description_text_long .. " " .. string.format("(default: %s)", self._default_value))
  description.desc = true
  return description
end

-- render widget, this needs to be overwritten by implementation
function ConfigurationOption:add_widgets_to_container(container)
  if not container then
    stderr.error("no widget provided")
  end

  -- render label on top of input
  local widget_label = self:_add_label_widget_to_container(container)
  -- widget_label:set_size(widget_label:get_real_width(), widget_label:get_real_height())
  -- widget_label:set_position(style.padding.x, y_start_coordinate + style.padding.y)

  -- render input ui element to change the configuration value
  local widget_modify_value = self:add_value_modification_widget_to_container(container)
  -- widget_modify:set_size(widget_modify:get_real_width(), widget_modify:get_real_height())
  -- widget_modify:set_position(style.padding.x, y_start_coordinate + widget_label:get_real_height() + 2*style.padding.y)

  -- render description and default value after the input
  local widget_description = self:_add_description_widget_to_container(container)
    -- widget_description:set_size(widget_description:get_real_width(), widget_description:get_real_height())
    -- widget_description:set_position(style.padding.x, widget_modify:get_bottom() + style.padding.y)
  -- widget_description:set_position(style.padding.x, y_start_coordinate + widget_label:get_real_height() + widget_description:get_real_height() + 3*style.padding.y)

  -- function container:is_visible()
  --   stderr.debug("is_visible() called")
  -- end

  -- line between options
  local widget_line = Label(container, " ")

  -- update_positions() function will be called by settings class
  -- whenever a notebook pane is visible
  function container:update_positions()
    stderr.debug("update_positions() called for configuration option")

      -- container:set_size(
      --   section.parent.size.x - (style.padding.x),
      --   section:get_real_height()
      -- )
    -- section:set_position(style.padding.x / 2, 0)
    local prev_child = nil
    for pos=#container.childs, 1, -1 do
      local child = container.childs[pos]

      -- start with basic padding
      local x = style.padding.x
      local y = style.padding.y
      if prev_child then
        y = prev_child:get_bottom() + style.padding.y
      end

      -- set with to full available container width
      child:set_size(container:get_width() - 2*style.padding.x, child.size.y)

      -- set position
      child:set_position(x, y)

      -- remember previous child
      prev_child = child
    end

    -- -- local center = self:get_width() / 2

    -- -- label on top
    -- widget_label:set_position(style.padding.x, style.padding.y)
    -- widget_label:set_size(container:get_width() - 2*style.padding.x, widget_label.size.y)

    -- -- value modification widget underneath label
    -- widget_modify_value:set_position(style.padding.x, widget_label:get_bottom() + style.padding.y)
    -- widget_modify_value:set_size(container:get_width() - 2*style.padding.x, widget_modify_value.size.y)

    -- -- description label at the bottom
    -- widget_description:set_position(style.padding.x, widget_modify_value:get_bottom() + style.padding.y)
    -- widget_description:set_size(container:get_width() - 2*style.padding.x, widget_description.size.y)




    -- title:set_label("Lite XL")
    -- title:set_position(
    --   center - (title:get_width() / 2),
    --   style.padding.y
    -- )

    -- version:set_position(
    --   center - (version:get_width() / 2),
    --   title:get_bottom() + (style.padding.y / 2)
    -- )

    -- description:set_position(
    --   center - (description:get_width() / 2),
    --   version:get_bottom() + (style.padding.y / 2)
    -- )

    -- button:set_position(
    --   center - (button:get_width() / 2),
    --   description:get_bottom() + style.padding.y
    -- )

    -- contributors:set_position(
    --   style.padding.x,
    --   button:get_bottom() + style.padding.y
    -- )

    -- contributors:set_size(
    --   self:get_width() - (style.padding.x * 2),
    --   self:get_height() - (button:get_bottom() + (style.padding.y * 2))
    -- )

    -- contributors:set_visible_rows()
  end

  -- function section:update()   
  --   stderr.warn("UPDATE UPDATE ")
  --   widget_label:set_position(style.padding.x, style.padding.y)
  --   widget_label:set_size(widget_label:get_real_width(), widget_label:get_real_height())
    
  --   widget_modify:set_position(style.padding.x, widget_label:get_bottom() + style.padding.y)
  --   widget_modify:set_size(widget_modify:get_real_width(), widget_modify:get_real_height())

  --   widget_description:set_position(style.padding.x, widget_modify:get_bottom() + style.padding.y)
  --   widget_description:set_size(widget_description:get_real_width(), widget_description:get_real_height())

  -- section:set_size(section:get_real_width(),section:get_real_height())
  -- end

  -- section:set_size(section:get_real_width(),section:get_real_height())

  -- section:update()

  -- local height = widget_description:get_real_height() + widget_label:get_real_height() + widget_modify:get_real_height() + 4 * style.padding.y

  return container
  -- return section
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