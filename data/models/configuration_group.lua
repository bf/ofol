-- base class for configuration groups

local style = require("themes.style")
local Label = require("lib.widget.label")
local Button = require("lib.widget.button")

local ConfigurationOptionGroup = Object:extend()

function ConfigurationOptionGroup:new(group_key, label_text, icon)
  -- ensure group_key is provided
  if not group_key or not Validator.is_string(group_key) then
    stderr.error("group_key is required")
  end

  -- ensure label is provided
  if not label_text or not Validator.is_string(label_text) then
    stderr.error("label_text is required")
  end

  -- ensure icon is provided
  if not icon or not Validator.is_string(icon) then
    stderr.error("icon is required")
  end

  -- ensure icon is exactly 1 character long
  if #icon ~= 1 then
    stderr.error("icon string needs to have length of 1")
  end

  self._group_key = group_key
  self._label_text = label_text
  self._icon = icon

  -- add this group to the global storage 
  ConfigurationOptionStore.initialize_configuration_group(self)
end

function ConfigurationOptionGroup:get_group_key()
  return self._group_key
end

function ConfigurationOptionGroup:get_label_text()
  return self._label_text
end

function ConfigurationOptionGroup:get_icon()
  return self._icon
end

return ConfigurationOptionGroup