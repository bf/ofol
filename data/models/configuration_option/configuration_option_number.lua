local ConfigurationOption = require("models.configuration_option")

local ConfigurationOptionNumber = ConfigurationOption:extend()

-- NUMBER 
function ConfigurationOptionNumber:new(key, description_text_short, description_text_long, default_value, min_value, max_value, optional_on_change_function) 
  -- min_value is optional
  if min_value ~= nil then 
    if not Validator.is_number(min_value) then
      stderr.error("min_value needs to be a number, received %s", min_value)
    end

    self._min_value = min_value
  else
    self._min_value = -1 * math.huge
  end

  -- max_value is optional
  if max_value ~= nil then
    if not Validator.is_number(max_value) then
      stderr.error("max_value needs to be a number, received %s", max_value)
    end
    
    self._max_value = max_value
  else
    self._max_value = math.huge
  end

  -- initialize with base class
  self.super.new(self, key, description_text_short, description_text_long, default_value, optional_on_change_function)
end

-- return true if $val is between min_value and max_value
function ConfigurationOptionNumber:is_valid(val)
  return Validator.is_number_between(val, self._min_value, self._max_value)
end


return ConfigurationOptionNumber