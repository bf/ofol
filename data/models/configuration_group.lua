-- base class for configuration groups
local style = require("themes.style")

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

-- fetch all options for this group
function ConfigurationOptionGroup:retrieve_all_configuration_options()
  stderr.debug("retrieve_all_configuration_options for %s", self._group_key)
  return ConfigurationOptionStore.retrieve_all_configuration_options_for_group_key(self._group_key)
end

-- render configuration group for the settings page in a container
function ConfigurationOptionGroup:add_configuration_options_to_container(container)
  -- update_positions() function will be called by settings class
  -- whenever the container is visible
  function container:update_positions()
    -- remember previous child
    local prev_child = nil

    -- iterate over all children
    for pos=#container.childs, 1, -1 do
      local child = container.childs[pos]

      -- start with basic padding at top
      local x = style.padding.x
      local y = style.padding.y

      -- when previous child exists, position current child
      -- underneath previous child
      if prev_child then
        y = prev_child:get_bottom() + style.padding.y
      end

      -- set with to full available container width
      child:set_size(container:get_width() - 2*style.padding.x, child.size.y)

      -- set position
      child:set_position(x, y)

      -- remember previous child
      prev_child = child
    end
  end

  -- iterate over all options
  for index, myConfigurationOption in pairs(self:retrieve_all_configuration_options()) do
    -- add each option to  widget
    myConfigurationOption:add_widgets_to_container(container)
  end

  return container
end

return ConfigurationOptionGroup