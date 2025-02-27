local ConfigurationGroup = require("models.configuration_group")

local ConfigurationOptionNumber = require("models.configuration_option.configuration_option_number")
local ConfigurationOptionString = require("models.configuration_option.configuration_option_string")
local ConfigurationOptionMultipleChoice = require("models.configuration_option.configuration_option_multiple_choice")
local ConfigurationOptionBoolean = require("models.configuration_option.configuration_option_boolean")
local ConfigurationOptionStringList = require("models.configuration_option.configuration_option_string_list")

-- define configuration group
ConfigurationGroup("editor", "Editor", "P")

-- define configuration options
ConfigurationOptionBoolean("editor.disable_blink", "Disable Cursor Blinking", "Disables cursor blinking on text input elements.", false)

ConfigurationOptionNumber("editor.blink_period", "Cursor Blinking Period", "Interval in seconds in which the cursor blinks.", 0.8, {
  min_value = 0.3, 
  max_value = 2.0, 
  step = 0.1
})

ConfigurationOptionNumber("editor.max_visible_commands", "Commands Box number of suggestions", "Number of suggestions in command box.", 10, {
  min_value = 1, 
  max_value = 50
})

ConfigurationOptionMultipleChoice("editor.tab_type", "Indentation Type", "The character inserted when pressing the tab key.", "soft", {
  available_values = { 
      {"Space", "soft"},
      {"Tab", "hard"}
  },
})

ConfigurationOptionNumber("editor.indent_size", "Indentation Size", "Amount of spaces shown per indentation.", 2, {
  min_value = 1,
  max_value = 10
})

ConfigurationOptionBoolean("editor.keep_newline_whitespace", "Keep Newline Whitespace", "Do not remove whitespace when pressing enter.", false)

ConfigurationOptionNumber("editor.line_limit", "Line Limit", "Amount of characters at which the line breaking column will be drawn.", 80, {
  min_value = 1 
})

ConfigurationOptionNumber("editor.line_height", "Line Height", "The amount of spacing between lines.", 1.2, {
  min_value = 1.0, 
  max_value = 3.0, 
  step = 0.1
})

ConfigurationOptionMultipleChoice("editor.highlight_current_line", "Highlight Line", "Highlight the current line.", true, {
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
})

ConfigurationOptionNumber("editor.max_undos", "Maximum Undo History", "The amount of undo elements to keep.", 10000, {
  min_value = 100, 
  max_value = 100000,
})

ConfigurationOptionNumber("editor.undo_merge_timeout", "Undo Merge Timeout", "Time in seconds before applying an undo action.", 0.3, {
  min_value = 0.1, 
  max_value = 1.0, 
  step = 0.1
})

ConfigurationOptionString("editor.symbol_pattern", "Symbol Pattern", "A lua pattern used to match symbols in the document.", "[%a_][%w_]*")

ConfigurationOptionString("editor.non_word_chars", "Non Word Characters", "A string of characters that do not belong to a word.", " \\t\\n/\\()\"':,.;<>~!@#$%^&*|+=[]{}`?-")

ConfigurationOptionBoolean("editor.scroll_past_end", "Scroll Past the End", "Allow scrolling beyond the document ending.", true)


ConfigurationOptionStringList("editor.ignore_files", "Ignore Files", "List of lua patterns matching files to be ignored by the editor.", {
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
