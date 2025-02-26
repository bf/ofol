local SettingsTabComponent = require("components.settings_tab_component")

local ConfigurationOptionNumber = require("models.configuration_option.configuration_option_number")
local ConfigurationOptionString = require("models.configuration_option.configuration_option_string")
local ConfigurationOptionMultipleChoice = require("models.configuration_option.configuration_option_multiple_choice")
local ConfigurationOptionBoolean = require("models.configuration_option.configuration_option_boolean")


-- initialize config options
local editorOptions = {
 ConfigurationOptionMultipleChoice("tab_type", "Indentation Type", "The character inserted when pressing the tab key.", "soft", {
    available_values = { 
        {"Space", "soft"},
        {"Tab", "hard"}
    },
  }),

  ConfigurationOptionNumber("indent_size", "Indentation Size", "Amount of spaces shown per indentation.", 2, {
    min_value = 1,
    max_value = 10
  }),

  ConfigurationOptionBoolean("keep_newline_whitespace", "Keep Newline Whitespace", "Do not remove whitespace when pressing enter.", false),

  ConfigurationOptionNumber("line_limit", "Line Limit", "Amount of characters at which the line breaking column will be drawn.", 80, {
    min_value = 1 
  }),

  ConfigurationOptionNumber("line_height", "Line Height", "The amount of spacing between lines.", 1.2, {
    min_value = 1.0, 
    max_value = 3.0, 
    step = 0.1
  }),

 ConfigurationOptionMultipleChoice("highlight_current_line", "Highlight Line", "Highlight the current line.", true, {
    available_values = { 
      {"Yes", true},
      {"No", false},
      {"No Selection", "no_selection"}
    },
    on_save_via_user_interface = function(value) 
      if type(value) == "nil" then 
        return false
      else
        return value
      end
    end
  }),

  ConfigurationOptionNumber("max_undos", "Maximum Undo History", "The amount of undo elements to keep.", 10000, {
    min_value = 100, 
    max_value = 100000,
  }),

  ConfigurationOptionNumber("undo_merge_timeout", "Undo Merge Timeout", "Time in seconds before applying an undo action.", 0.3, {
    min_value = 0.1, 
    max_value = 1.0, 
    step = 0.1
  }),

  ConfigurationOptionString("symbol_pattern", "Symbol Pattern", "A lua pattern used to match symbols in the document.", "[%a_][%w_]*"),

  ConfigurationOptionString("non_word_chars", "Non Word Characters", "A string of characters that do not belong to a word.", " \\t\\n/\\()\"':,.;<>~!@#$%^&*|+=[]{}`?-"),

  ConfigurationOptionBoolean("scroll_past_end", "Scroll Past the End", "Allow scrolling beyond the document ending.", true),
}

-- generate ui and add to pane
function setup_editor(container) 
  -- iterate over all options
  for index, myConfigurationOption in pairs(editorOptions) do
    -- add to widget
    myConfigurationOption:add_widgets_to_container(container)
  end


  return container
end


return SettingsTabComponent("editor", "Editor", "P", setup_editor);

