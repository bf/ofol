local ItemsList = require("lib.widget.itemslist")

local ConfigurationOption = require("models.configuration_option")
local ConfigurationOptionStringList = ConfigurationOption:extend()

-- List of Strings
-- function ConfigurationOptionStringList:new(key, description_text_short, description_text_long, default_value) 
--   -- initialize with base class
--   self.super.new(self, key, description_text_short, description_text_long, default_value)
-- end

-- return true if $val is valid
function ConfigurationOptionStringList:is_valid(val)
  return Validator.is_list_of_strings(val)
end

-- create UI element
function ConfigurationOptionStringList:render_only_modification_ui_in_widget_pane(pane)
  local widget = ItemsList(pane)
  for _, item in ipairs(self:get_current_value()) do
    widget:add_item(item)
  end

  -- handle new value
  function widget.on_change(this, value)
    -- ItemsList requires a special way to get value
    local actual_value = this:get_items()
    
    self:set(actual_value)
  end

  return widget
end

return ConfigurationOptionStringList