local ItemsList = require("lib.widget.itemslist")

local ConfigurationOption = require("models.configuration_option")
local ConfigurationOptionStringList = ConfigurationOption:extend()

-- List of Strings

-- return true if $val is valid
function ConfigurationOptionStringList:is_valid(val)
  return Validator.is_list_of_strings(val)
end

-- create UI element
function ConfigurationOptionStringList:add_value_modification_widget_to_container(container)
  local widget = ItemsList(container)
  for _, item in ipairs(self:get_current_value()) do
    widget:add_item(item)
  end

  -- handle new value
  function widget.on_change(this, value)
    -- ItemsList requires a special way to get value
    local actual_value = this:get_items()
    
    self:set_value_from_ui(actual_value)
  end

  return widget
end

return ConfigurationOptionStringList