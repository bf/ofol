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


return ConfigurationOptionString