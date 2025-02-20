local NumberBox = require("lib.widget.numberbox")
local ConfigurationOption = require("models.configuration_option")


local ConfigurationOptionNumber = ConfigurationOption:extend()

-- NUMBER 
function ConfigurationOptionNumber:new(key, description_text_short, description_text_long, default_value, options) 
  -- step is optional
  if options ~= nil and options.step ~= nil then
    if not Validator.is_number(options.step) then
      stderr.error("step needs to be a number, received %s", options.step)
    end

    self._step = options.step
  else 
    self._step = 1
  end

  -- min_value is optional
  if options ~= nil and options.min_value ~= nil then 
    if not Validator.is_number(options.min_value) then
      stderr.error("min_value needs to be a number, received %s", options.min_value)
    end

    self._min_value = options.min_value
  else
    self._min_value = -1 * math.huge
  end

  -- max_value is optional
  if options ~= nil and options.max_value ~= nil then
    if not Validator.is_number(options.max_value) then
      stderr.error("max_value needs to be a number, received %s", options.max_value)
    end
    
    self._max_value = options.max_value
  else
    self._max_value = math.huge
  end

  -- initialize with base class
  self.super.new(self, key, description_text_short, description_text_long, default_value, options)
end

-- return true if $val is between min_value and max_value
function ConfigurationOptionNumber:is_valid(val)
  return Validator.is_number_between(val, self._min_value, self._max_value)
end

-- create UI element
function ConfigurationOptionNumber:render_only_modification_ui_in_widget_pane(pane)
  -- add number input box
  local widget = NumberBox(pane, self:get_current_value(), self._min_value, self._min_value, self._step)

  -- handle new value
  function widget.on_change(this, value)
    self:set(value)
  end

  return widget
end

return ConfigurationOptionNumber