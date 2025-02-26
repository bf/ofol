local SelectBox = require("lib.widget.selectbox")
local ConfigurationOption = require("models.configuration_option")

local ConfigurationOptionMultipleChoice = ConfigurationOption:extend()


-- Multiple Choice
function ConfigurationOptionMultipleChoice:new(key, description_text_short, description_text_long, default_value, options) 
  -- options.available_values is required
  if options ~= nil and options.available_values ~= nil then
    self._available_values = options.available_values
  else
    stderr.error("available_values is required")
  end

  -- initialize with parent class
  self.super.new(self, key, description_text_short, description_text_long, default_value, options)
end


-- return true if $val is valid
function ConfigurationOptionMultipleChoice:is_valid(val)
  return Validator.is_boolean(val) or Validator.is_string(val)
end


-- create UI element
function ConfigurationOptionMultipleChoice:add_value_modification_widget_to_container(container)
  local widget = SelectBox(container)

  -- render all options
  for _, data in pairs(self._available_values) do
    widget:add_option(data[1], data[2])
  end

  -- mark option as selected
  for idx, _ in ipairs(widget.list.rows) do
    if widget.list:get_row_data(idx) == self:get_current_value() then
      widget:set_selected(idx-1)
      break
    end
  end

  -- handle new value
  function widget.on_change(this, value)
    -- SelectBox requires a special way to get value
    local actual_value = this:get_selected_data()
    
    self:set_value_from_ui(actual_value)
  end

  return widget
end


return ConfigurationOptionMultipleChoice

