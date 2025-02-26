local Toggle = require("lib.widget.toggle")
local ConfigurationOption = require("models.configuration_option")

local ConfigurationOptionBoolean = ConfigurationOption:extend()

-- return true if $val is valid
function ConfigurationOptionBoolean:is_valid(val)
  return Validator.is_boolean(val)
end

-- create UI element
function ConfigurationOptionBoolean:add_value_modification_widget_to_container(pane)
  -- add number input box
  local widget = Toggle(pane, self:get_current_value())

  -- -- handle new value
  -- function widget.on_change(this, value)
  --   self:set(value)
  -- end
  
  return widget
end

return ConfigurationOptionBoolean