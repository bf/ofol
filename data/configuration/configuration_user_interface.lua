local ConfigurationGroup = require("models.configuration_group")

local ConfigurationOptionNumber = require("models.configuration_option.configuration_option_number")
local ConfigurationOptionString = require("models.configuration_option.configuration_option_string")
local ConfigurationOptionMultipleChoice = require("models.configuration_option.configuration_option_multiple_choice")
local ConfigurationOptionBoolean = require("models.configuration_option.configuration_option_boolean")
local ConfigurationOptionTheme = require("models.configuration_option.configuration_option_theme")

-- define configuration group
ConfigurationGroup("user_interface", "User Interface", "W")

-- config keys
ConfigurationOptionTheme("user_interface.selected_theme", "Theme / Color Scheme", "Name of color scheme", "default")

ConfigurationOptionNumber("user_interface.mouse_wheel_scroll", "Mouse wheel scroll rate", "The amount to scroll when using the mouse wheel.", 10, {
  min_value = 0.1, 
  max_value = 10.0, 
  step = 0.1
})

ConfigurationOptionNumber("user_interface.max_consecutive_clicks_registered", "Maximum Clicks", "The maximum amount of consecutive clicks that are registered by the editor.", 3, {
  min_value = 1, 
  max_value = 10, 
  step = 1
})