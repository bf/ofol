local SettingsTabComponent = require("components.settings_tab_component")

local ConfigurationOptionNumber = require("models.configuration_option.configuration_option_number")
local ConfigurationOptionString = require("models.configuration_option.configuration_option_string")
local ConfigurationOptionMultipleChoice = require("models.configuration_option.configuration_option_multiple_choice")
local ConfigurationOptionBoolean = require("models.configuration_option.configuration_option_boolean")


-- initialize config options
local userInterfaceOptions = {
  ConfigurationOptionNumber("mouse_wheel_scroll", "Mouse wheel scroll rate", "The amount to scroll when using the mouse wheel.", 10, {
    min_value = 0.1, 
    max_value = 10.0, 
    step = 0.1
  }),

  ConfigurationOptionBoolean("disable_blink", "Disable Cursor Blinking", "Disables cursor blinking on text input elements.", false),

  ConfigurationOptionNumber("blink_period", "Cursor Blinking Period", "Interval in seconds in which the cursor blinks.", 0.8, {
    min_value = 0.3, 
    max_value = 2.0, 
    step = 0.1
  }),


  ConfigurationOptionNumber("max_visible_commands", "Commands Box number of suggestions", "Number of suggestions in command box.", 10, {
    min_value = 1, 
    max_value = 50
  }),
}

-- generate ui and add to pane
function setup_user_interface(container) 
  -- iterate over all options
  for index, myConfigurationOption in pairs(userInterfaceOptions) do
    -- add to widget
    myConfigurationOption:add_widgets_to_container(container)
  end


  return container
end


return SettingsTabComponent("user_interface", "User Interface", "P", setup_user_interface);

