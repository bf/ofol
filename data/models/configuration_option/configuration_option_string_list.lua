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


return ConfigurationOptionStringList