
local config = {}


---The maximum number of undo steps per-document.
---
---The default is 10000.
---@type number
config.max_undos = 10000

---The maximum number of entries shown at a time in the command palette.
---
---The default is 10.
---@type integer
config.max_visible_commands = 10

---Shows/hides the tab bar when there is only one tab open.
---
---The tab bar is always shown by default.
---@type boolean
config.always_show_tabs = true

---@alias config.highlightlinetype
---| true # Always highlight the current line.
---| false # Never highlight the current line.
---| "no_selection" # Highlight the current line if no text is selected.

---Highlights the current line.
---
---The default is true.
---@type config.highlightlinetype
config.highlight_current_line = true

---The spacing between each line of text.
---
---The default is 120% of the height of the text (1.2).
---@type number
config.line_height = 1.2

---The number of spaces each level of indentation represents.
---
---The default is 2.
---@type number
config.indent_size = 2

---The type of indentation.
---
---The default is "soft" (spaces).
---@type "soft" | "hard"
config.tab_type = "soft"

---Do not remove whitespaces when advancing to the next line.
---
---Defaults to false.
---@type boolean
config.keep_newline_whitespace = false

---Default line endings for new files.
---
---Defaults to `crlf` (`\r\n`) on Windows and `lf` (`\n`) on everything else.
---@type "crlf" | "lf"
config.line_endings = PLATFORM == "Windows" and "crlf" or "lf"

---Maximum number of characters per-line for the line guide.
---
---Defaults to 80.
---@type number
config.line_limit = 80

---Maximum number of project files to keep track of.
---If the number of files in the project exceeds this number,
---Lite XL will not be able to keep track of them.
---They will be not be searched when searching for files or text.
---
---Defaults to 2000.
---@type number
config.max_project_files = 20000


---The caret's blinking period, in seconds.
---
---Defaults to 0.8.
---@type number
config.blink_period = 0.8

---Disables caret blinking.
---
---Defaults to false.
---@type boolean
config.disable_blink = false

---Draws whitespaces as dots.
---This option is deprecated.
---Please use the drawwhitespace plugin instead.
---@deprecated
config.draw_whitespace = false

-- -- disable all plugins
-- config.disable_all_plugins = true

---Shows/hides the close buttons on tabs.
---When hidden, users can close tabs via keyboard shortcuts or commands.
---
---Defaults to true.
---@type boolean
config.tab_close_button = true

---Maximum number of clicks recognized by Lite XL.
---
---Defaults to 3.
---@type number
config.max_clicks = 3

-- holds the plugins real config table
local plugins_config = {}

---A table containing configuration for all the plugins.
---
---This is a metatable that automaticaly creates a minimal
---configuration when a plugin is initially configured.
---Each plugins will then call `table.merge()` to get the finalized
---plugin config.
---Do not use raw operations on this table.
---@type table
config.plugins = {}

-- allows virtual access to the plugins config table
setmetatable(config.plugins, {
  __index = function(_, k)
    if not plugins_config[k] then
      plugins_config[k] = { enabled = true, config = {} }
    end
    if plugins_config[k].enabled ~= false then
      return plugins_config[k].config
    end
    return false
  end,
  __newindex = function(_, k, v)
    if not plugins_config[k] then
      plugins_config[k] = { enabled = nil, config = {} }
    end
    if v == false and package.loaded["plugins."..k] then
      local core = require "core"
      stderr.warn("[%s] is already enabled, restart the editor for the change to take effect", k)
      return
    elseif plugins_config[k].enabled == false and v ~= false then
      plugins_config[k].enabled = true
    end
    if v == false then
      plugins_config[k].enabled = false
    elseif type(v) == "table" then
      plugins_config[k].enabled = true
      plugins_config[k].config = table.merge(plugins_config[k].config, v)
    end
  end,
  __pairs = function()
    return coroutine.wrap(function()
      for name, status in pairs(plugins_config) do
        coroutine.yield(name, status.config)
      end
    end)
  end
})


return config
