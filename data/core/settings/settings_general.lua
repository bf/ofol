local SettingsTabComponent = require("components.settings_tab_component")

local ConfigurationOptionNumber = require("models.configuration_option.configuration_option_number")
local ConfigurationOptionString = require("models.configuration_option.configuration_option_string")
local ConfigurationOptionStringList = require("models.configuration_option.configuration_option_string_list")

-- initialize config options
local generalOptions = {
  ConfigurationOptionStringList("ignore_files", "Ignore Files", "List of lua patterns matching files to be ignored by the editor.", {
    -- folders
    "^%.svn/",        "^%.git/",   "^%.hg/",        "^CVS/", "^%.Trash/", "^%.Trash%-.*/",
    "^node_modules/", "^%.cache/", "^__pycache__/",
    -- files
    "%.pyc$",         "%.pyo$",       "%.exe$",        "%.dll$",   "%.obj$", "%.o$",
    "%.a$",           "%.lib$",       "%.so$",         "%.dylib$", "%.ncb$", "%.sdf$",
    "%.suo$",         "%.pdb$",       "%.idb$",        "%.class$", "%.psd$", "%.db$",
    "^desktop%.ini$", "^%.DS_Store$", "^%.directory$",
  }, {
    on_change = function(new_value)
        -- TODO: refactor
        -- core.rescan_project_directories()
      end
  }),

  ConfigurationOptionNumber("max_clicks", "Maximum Clicks", "The maximum amount of consecutive clicks that are registered by the editor.", 3, {
    min_value = 1, 
    max_value = 10, 
    step = 1
  })
}

-- generate ui and add to pane
function setup_general_settings(pane) 
  -- iterate over all options
  for _, myConfigurationOption in pairs(generalOptions) do
    -- add to widget
    myConfigurationOption:render_in_widget_pane(pane)
  end
end


return SettingsTabComponent("general", "General", "P", setup_general_settings);
