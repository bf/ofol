local SettingsTabComponent = require("components.settings_tab_component")

local ConfigurationOptionNumber = require("models.configuration_option.configuration_option_number")
local ConfigurationOptionString = require("models.configuration_option.configuration_option_string")
local ConfigurationOptionMultipleChoice = require("models.configuration_option.configuration_option_multiple_choice")
local ConfigurationOptionBoolean = require("models.configuration_option.configuration_option_boolean")

local ConfigurationStore = require("stores.configuration_store")

local optionForceScrollbarStatus
local optionForceScrollbarStatusMode

optionForceScrollbarStatus = ConfigurationOptionMultipleChoice("force_scrollbar_status", "Force Scrollbar Status", "Choose a fixed scrollbar state instead of resizing it on mouse hover.", false, {
    available_values = { 
      {"Disabled", false},
      {"Expanded", "expanded"},
      {"Contracted", "contracted"}
    },
    on_change = function(value) 
      if optionForceScrollbarStatus ~= nil and optionForceScrollbarStatusMode ~= nil then
        updateScrollbarStatus()
      end
    end
  })

optionForceScrollbarStatusMode = ConfigurationOptionMultipleChoice("force_scrollbar_status_mode", "Force Scrollbar Status Mode", "Choose between applying globally or document views only.", "global", {
    available_values = {
      {"Documents", "docview"},
      {"Globally", "global"}
    },
    on_change = function(value) 
      if optionForceScrollbarStatus ~= nil and optionForceScrollbarStatusMode ~= nil then
        updateScrollbarStatus()
      end
    end
  })

-- common update function for two variables
function updateScrollbarStatus () 
  local globally =  optionForceScrollbarStatusMode.get_current_value() or "global"
  local currentValueForOptionForceScrollbarStatus = optionForceScrollbarStatus.get_current_value() 

  local views = core.root_view.root_node:get_children()

  for _, view in ipairs(views) do
    if globally or view:extends(DocView) then
      view.h_scrollbar:set_forced_status(currentValueForOptionForceScrollbarStatus)
      view.v_scrollbar:set_forced_status(currentValueForOptionForceScrollbarStatus)
    else
      view.h_scrollbar:set_forced_status(false)
      view.v_scrollbar:set_forced_status(false)
    end
  end
end

-- initialize config options
local userInterfaceOptions = {
  ConfigurationOptionNumber("mouse_wheel_scroll", "Mouse wheel scroll rate", "The amount to scroll when using the mouse wheel.", 0.5, {
    min_value = 0.1, 
    max_value = 2.0, 
    step = 0.05
  }),


  optionForceScrollbarStatus,
  optionForceScrollbarStatusMode,  

  ConfigurationOptionBoolean("disable_blink", "Disable Cursor Blinking", "Disables cursor blinking on text input elements.", false),

  ConfigurationOptionNumber("blink_period", "Cursor Blinking Period", "Interval in seconds in which the cursor blinks.", 0.8, {
    min_value = 0.3, 
    max_value = 2.0, 
    step = 0.1
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

