local TextBox = require("lib.widget.textbox")
local ConfigurationOption = require("models.configuration_option")

local ConfigurationOptionString = ConfigurationOption:extend()

-- String
-- function ConfigurationOptionString:new(key, description_text_short, description_text_long, default_value) 
--   -- initialize with base class
--   self.super.new(self, key, description_text_short, description_text_long, default_value)
-- end

-- return true if $val is valid
function ConfigurationOptionString:is_valid(val)
  return Validator.is_string(val)
end

-- create UI element
function ConfigurationOptionString:render_only_modification_ui_in_widget_pane(pane)
  -- add number input box
  local widget = TextBox(pane, self:get_current_value())
end

return ConfigurationOptionString