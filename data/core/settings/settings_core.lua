local core = require "core"
local config = require "core.config"
local command = require "core.command"
local style = require "themes.style"
local UserSettingsStore = require "stores.user_settings_store"

local DocView = require "core.views.docview"

local Label = require "lib.widget.label"
local Line = require "lib.widget.line"
local Button = require "lib.widget.button"
local TextBox = require "lib.widget.textbox"
local SelectBox = require "lib.widget.selectbox"
local NumberBox = require "lib.widget.numberbox"
local Toggle = require "lib.widget.toggle"
local ListBox = require "lib.widget.listbox"
local FoldingBook = require "lib.widget.foldingbook"
local FontsList = require "lib.widget.fontslist"
local ItemsList = require "lib.widget.itemslist"
local Fonts = require "lib.widget.fonts"
local FilePicker = require "lib.widget.filepicker"
local ColorPicker = require "lib.widget.colorpicker"
local MessageBox = require "lib.widget.messagebox"



local core_sections = {}


---@class plugins.settings
local settings = {}
settings.config = {}


local DEFAULT_FONT_NAME = "JetBrains Mono Regular"
local DEFAULT_FONT_PATH = DATADIR .. "/static/fonts/JetBrainsMono-Regular.ttf"

---Enumeration for the different types of settings.
---@type table<string, integer>
CONST_SETTINGS_TYPES = {
  STRING = 1,
  NUMBER = 2,
  TOGGLE = 3,
  SELECTION = 4,
  LIST_STRINGS = 5,
  BUTTON = 6,
  FONT = 7,
  FILE = 8,
  DIRECTORY = 9,
  COLOR = 10
}

---@alias CONST_SETTINGS_TYPESs
---| `CONST_SETTINGS_TYPES.STRING`
---| `CONST_SETTINGS_TYPES.NUMBER`
---| `CONST_SETTINGS_TYPES.TOGGLE`
---| `CONST_SETTINGS_TYPES.SELECTION`
---| `CONST_SETTINGS_TYPES.LIST_STRINGS`
---| `CONST_SETTINGS_TYPES.BUTTON`
---| `CONST_SETTINGS_TYPES.FONT`
---| `CONST_SETTINGS_TYPES.FILE`
---| `CONST_SETTINGS_TYPES.DIRECTORY`
---| `CONST_SETTINGS_TYPES.COLOR`

---Represents a setting to render on a settings pane.
---@class settings.option
---Title displayed to the user eg: "My Option"
---@field public label string
---Description of the option eg: "Modifies the document indentation"
---@field public description string
---Config path in the config table, eg: section.myoption, myoption, etc...
---@field public path string
---Type of option that will be used to render an appropriate control
---@field public type CONST_SETTINGS_TYPESs | integer
---Default value of the option
---@field public default string | number | boolean | table<integer, string> | table<integer, integer>
---Used for NUMBER to indicate the minimum number allowed
---@field public min number
---Used for NUMBER to indiciate the maximum number allowed
---@field public max number
---Used for NUMBER to indiciate the increment/decrement amount
---@field public step number
---Used in a SELECTION to provide the list of valid options
---@field public values table
---Optionally used for FONT to store the generated font group.
---@field public fonts_list table<string, renderer.font>
---Flag set to true when loading user defined fonts fail
---@field public font_error boolean
---Optional function that is used to manipulate the current value on retrieval.
---@field public get_value nil | fun(value:any):any
---Optional function that is used to manipulate the saved value on save.
---@field public set_value nil | fun(value:any):any
---The icon set for a BUTTON
---@field public icon string
---Command or function executed when a BUTTON is clicked
---@field public on_click nil | string | fun(button:string, x:integer, y:integer)
---Optional function executed when the option value is applied.
---@field public on_apply nil | fun(value:any)
---When FILE or DIRECTORY this flag tells the path should exist.
---@field public exists boolean
---Lua patterns used on FILE or DIRECTORY to filter browser results and
---also force the selection to match one of the filters.
---@field public filters table<integer,string>

---Add a new settings section to the settings UI
---@param section string
---@param options settings.option[]
function settings_add(section, options)
  if not core_sections[section] then
    core_sections[section] = {}
    table.insert(core_sections, section)
  end

  for _, option in ipairs(options) do
    table.insert(core_sections[section], option)
  end
end

--------------------------------------------------------------------------------
-- Add Core Settings
--------------------------------------------------------------------------------

settings_add("General",
  {
    {
      label = "Clear Fonts Cache",
      description = "Delete current font cache and regenerate a fresh one.",
      type = CONST_SETTINGS_TYPES.BUTTON,
      icon = "C",
      on_click = function()
        if Fonts.cache_is_building() then
          MessageBox.warning(
            "Clear Fonts Cache",
            { "The font cache is already been built,\n"
              .. "status will be logged on the stderr.info."
            }
          )
        else
          MessageBox.info(
            "Clear Fonts Cache",
            { "Re-building the font cache can take some time,\n"
              .. "it is needed when you have installed new fonts\n"
              .. "which are not listed on the font picker tool.\n\n"
              .. "Do you want to continue?"
            },
            function(_, button_id, _)
              if button_id == 1 then
                Fonts.clean_cache()
              end
            end,
            MessageBox.BUTTONS_YES_NO
          )
        end
      end
    },
    -- {
    --   label = "Maximum Project Files",
    --   description = "The maximum amount of project files to register.",
    --   path = "max_project_files",
    --   type = CONST_SETTINGS_TYPES.NUMBER,
    --   default = 2000,
    --   min = 1,
    --   max = 100000,
    --   on_apply = function()
    --     core.rescan_project_directories()
    --   end
    -- },
    -- {
    --   label = "File Size Limit",
    --   description = "The maximum file size in megabytes allowed for editing.",
    --   path = "file_size_limit",
    --   type = CONST_SETTINGS_TYPES.NUMBER,
    --   default = 10,
    --   min = 1,
    --   max = 50
    -- },
    {
      label = "Ignore Files",
      description = "List of lua patterns matching files to be ignored by the editor.",
      path = "ignore_files",
      type = CONST_SETTINGS_TYPES.LIST_STRINGS,
      default = {
        -- folders
        "^%.svn/",        "^%.git/",   "^%.hg/",        "^CVS/", "^%.Trash/", "^%.Trash%-.*/",
        "^node_modules/", "^%.cache/", "^__pycache__/",
        -- files
        "%.pyc$",         "%.pyo$",       "%.exe$",        "%.dll$",   "%.obj$", "%.o$",
        "%.a$",           "%.lib$",       "%.so$",         "%.dylib$", "%.ncb$", "%.sdf$",
        "%.suo$",         "%.pdb$",       "%.idb$",        "%.class$", "%.psd$", "%.db$",
        "^desktop%.ini$", "^%.DS_Store$", "^%.directory$",
      },
      on_apply = function()
        core.rescan_project_directories()
      end
    },
    {
      label = "Maximum Clicks",
      description = "The maximum amount of consecutive clicks that are registered by the editor.",
      path = "max_clicks",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 3,
      min = 1,
      max = 10
    },
  }
)

-- settings_add("Graphics",
--   {
--   }
-- )

settings_add("User Interface",
  {
    {
      label = "Font",
      description = "The font and fallbacks used on non code text.",
      path = "font",
      type = CONST_SETTINGS_TYPES.FONT,
      fonts_list = style,
      default = {
        fonts = {
          {
            name = DEFAULT_FONT_NAME,
            path = DEFAULT_FONT_PATH
          }
        },
        options = {
          size = 18,
          antialiasing = "subpixel",
          hinting = "slight"
        }
      }
    },
    -- {
    --   label = "Borderless",
    --   description = "Use built-in window decorations.",
    --   path = "borderless",
    --   type = CONST_SETTINGS_TYPES.TOGGLE,
    --   default = false,
    --   on_apply = function()
    --     core.configure_borderless_window()
    --   end
    -- },
    -- {
    --   label = "Always Show Tabs",
    --   description = "Shows tabs even if a single document is opened.",
    --   path = "always_show_tabs",
    --   type = CONST_SETTINGS_TYPES.TOGGLE,
    --   default = true
    -- },
    -- {
    --   label = "Maximum Tabs",
    --   description = "The maximum amount of visible document tabs.",
    --   path = "max_tabs",
    --   type = CONST_SETTINGS_TYPES.NUMBER,
    --   default = 8,
    --   min = 1,
    --   max = 100
    -- },
    -- {
    --   label = "Close Button on Tabs",
    --   description = "Display the close button on tabs.",
    --   path = "tab_close_button",
    --   type = CONST_SETTINGS_TYPES.TOGGLE,
    --   default = true
    -- },
    {
      label = "Mouse wheel scroll rate",
      description = "The amount to scroll when using the mouse wheel.",
      path = "mouse_wheel_scroll",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 50,
      min = 10,
      max = 200,
      get_value = function(value)
        return value / SCALE
      end,
      set_value = function(value)
        return value * SCALE
      end
    },
    {
      label = "Force Scrollbar Status",
      description = "Choose a fixed scrollbar state instead of resizing it on mouse hover.",
      path = "force_scrollbar_status",
      type = CONST_SETTINGS_TYPES.SELECTION,
      default = false,
      values = {
        {"Disabled", false},
        {"Expanded", "expanded"},
        {"Contracted", "contracted"}
      },
      on_apply = function(value)
        local mode = config.force_scrollbar_status_mode or "global"
        local globally = mode == "global"
        local views = core.root_view.root_node:get_children()
        for _, view in ipairs(views) do
          if globally or view:extends(DocView) then
            view.h_scrollbar:set_forced_status(value)
            view.v_scrollbar:set_forced_status(value)
          else
            view.h_scrollbar:set_forced_status(false)
            view.v_scrollbar:set_forced_status(false)
          end
        end
      end
    },
    {
      label = "Force Scrollbar Status Mode",
      description = "Choose between applying globally or document views only.",
      path = "force_scrollbar_status_mode",
      type = CONST_SETTINGS_TYPES.SELECTION,
      default = "global",
      values = {
        {"Documents", "docview"},
        {"Globally", "global"}
      },
      on_apply = function(value)
        local globally = value == "global"
        local views = core.root_view.root_node:get_children()
        for _, view in ipairs(views) do
          if globally or view:extends(DocView) then
            view.h_scrollbar:set_forced_status(config.force_scrollbar_status)
            view.v_scrollbar:set_forced_status(config.force_scrollbar_status)
          else
            view.h_scrollbar:set_forced_status(false)
            view.v_scrollbar:set_forced_status(false)
          end
        end
      end
    },
    {
      label = "Disable Cursor Blinking",
      description = "Disables cursor blinking on text input elements.",
      path = "disable_blink",
      type = CONST_SETTINGS_TYPES.TOGGLE,
      default = false
    },
    {
      label = "Cursor Blinking Period",
      description = "Interval in seconds in which the cursor blinks.",
      path = "blink_period",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 0.8,
      min = 0.3,
      max = 2.0,
      step = 0.1
    }
  }
)

settings_add("Editor",
  {
    {
      label = "Code Font",
      description = "The font and fallbacks used on the code editor.",
      path = "code_font",
      type = CONST_SETTINGS_TYPES.FONT,
      fonts_list = style,
      default = {
        fonts = {
          {
            -- name = "JetBrains Mono Regular",
            -- path = DATADIR .. "/fonts/JetBrainsMono-Regular.ttf"
            name = DEFAULT_FONT_NAME,
            path = DEFAULT_FONT_PATH
          }
        },
        options = {
          size = 22,
          antialiasing = "subpixel",
          hinting = "slight"
        }
      }
    },
    {
      label = "Indentation Type",
      description = "The character inserted when pressing the tab key.",
      path = "tab_type",
      type = CONST_SETTINGS_TYPES.SELECTION,
      default = "soft",
      values = {
        {"Space", "soft"},
        {"Tab", "hard"}
      }
    },
    {
      label = "Indentation Size",
      description = "Amount of spaces shown per indentation.",
      path = "indent_size",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 2,
      min = 1,
      max = 10
    },
    {
      label = "Keep Newline Whitespace",
      description = "Do not remove whitespace when pressing enter.",
      path = "keep_newline_whitespace",
      type = CONST_SETTINGS_TYPES.TOGGLE,
      default = false
    },
    {
      label = "Line Limit",
      description = "Amount of characters at which the line breaking column will be drawn.",
      path = "line_limit",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 80,
      min = 1
    },
    {
      label = "Line Height",
      description = "The amount of spacing between lines.",
      path = "line_height",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 1.2,
      min = 1.0,
      max = 3.0,
      step = 0.1
    },
    {
      label = "Highlight Line",
      description = "Highlight the current line.",
      path = "highlight_current_line",
      type = CONST_SETTINGS_TYPES.SELECTION,
      default = true,
      values = {
        {"Yes", true},
        {"No", false},
        {"No Selection", "no_selection"}
      },
      set_value = function(value)
        if type(value) == "nil" then return false end
        return value
      end
    },
    {
      label = "Maximum Undo History",
      description = "The amount of undo elements to keep.",
      path = "max_undos",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 10000,
      min = 100,
      max = 100000
    },
    {
      label = "Undo Merge Timeout",
      description = "Time in seconds before applying an undo action.",
      path = "undo_merge_timeout",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 0.3,
      min = 0.1,
      max = 1.0,
      step = 0.1
    },
    {
      label = "Symbol Pattern",
      description = "A lua pattern used to match symbols in the document.",
      path = "symbol_pattern",
      type = CONST_SETTINGS_TYPES.STRING,
      default = "[%a_][%w_]*"
    },
    {
      label = "Non Word Characters",
      description = "A string of characters that do not belong to a word.",
      path = "non_word_chars",
      type = CONST_SETTINGS_TYPES.STRING,
      default = " \\t\\n/\\()\"':,.;<>~!@#$%^&*|+=[]{}`?-",
      get_value = function(value)
        return value:gsub("\n", "\\n"):gsub("\t", "\\t")
      end,
      set_value = function(value)
        return value:gsub("\\n", "\n"):gsub("\\t", "\t")
      end
    },
    {
      label = "Scroll Past the End",
      description = "Allow scrolling beyond the document ending.",
      path = "scroll_past_end",
      type = CONST_SETTINGS_TYPES.TOGGLE,
      default = true
    }
  }
)

settings_add("Development",
  {
    {
      label = "Core Log",
      description = "Open the list of logged messages.",
      type = CONST_SETTINGS_TYPES.BUTTON,
      icon = "f",
      on_click = "core:open-log"
    },
    {
      label = "Log Items",
      description = "The maximum amount of entries to keep on the log UI.",
      path = "max_log_items",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 800,
      min = 150,
      max = 2000
    },
  }
)

settings_add("Status Bar",
  {
    {
      label = "Enabled",
      description = "Toggle the default visibility of the status bar.",
      path = "statusbar.enabled",
      type = CONST_SETTINGS_TYPES.TOGGLE,
      default = true,
      on_apply = function(enabled)
        if enabled then
          core.status_view:show()
        else
          core.status_view:hide()
        end
      end
    },
    {
      label = "Show Notifications",
      description = "Toggle the visibility of status messages.",
      path = "statusbar.messages",
      type = CONST_SETTINGS_TYPES.TOGGLE,
      default = true,
      on_apply = function(enabled)
        core.status_view:display_messages(enabled)
      end
    },
    {
      label = "Messages Timeout",
      description = "The amount in seconds before a notification dissapears.",
      path = "message_timeout",
      type = CONST_SETTINGS_TYPES.NUMBER,
      default = 5,
      min = 1,
      max = 30
    }
  }
)

---Retrieve from given config the associated value using the given path.
---@param conf table
---@param path string
---@param default any
---@return any | nil
local function get_config_value(conf, path, default)
  local sections = {};
  for match in (path.."."):gmatch("(.-)%.") do
    table.insert(sections, match);
  end

  local element = conf
  for _, section in ipairs(sections) do
    if type(element[section]) ~= "nil" then
      element = element[section]
    else
      return default
    end
  end

  if type(element) == "nil" then
    return default
  end

  return element
end

---Loops the given config table using the given path and store the value.
---@param conf table
---@param path string
---@param value any
local function set_config_value(conf, path, value)
  local sections = {};
  for match in (path.."."):gmatch("(.-)%.") do
    table.insert(sections, match);
  end

  local sections_count = #sections

  if sections_count == 1 then
    conf[sections[1]] = value
    return
  elseif type(conf[sections[1]]) ~= "table" then
    conf[sections[1]] = {}
  end

  local element = conf
  for idx, section in ipairs(sections) do
    if type(element[section]) ~= "table" then
      element[section] = {}
      element = element[section]
    else
      element = element[section]
    end
    if idx + 1 == sections_count then break end
  end

  element[sections[sections_count]] = value
end


---Load the saved fonts into the config path or fonts_list table.
---@param option settings.option
---@param path string
---@param saved_value any
local function merge_font_settings(option, path, saved_value)
  local font_options = saved_value.options or {
    size = style.DEFAULT_FONT_SIZE,
    antialiasing = "supixel",
    hinting = "slight"
  }
  font_options.size = font_options.size or style.DEFAULT_FONT_SIZE
  font_options.antialiasing = font_options.antialiasing or "subpixel"
  font_options.hinting = font_options.hinting or "slight"

  local fonts = {}
  local font_loaded = true
  for _, font in ipairs(saved_value.fonts) do
    local font_data = nil
    font_loaded = try_catch(function()
      font_data = renderer.font.load(
        font.path, font_options.size * SCALE, font_options
      )
    end)
    if font_loaded then
      table.insert(fonts, font_data)
    else
      option.font_error = true
      stderr.error("Settings: could not load %s\n'%s - %s'", path, font.name, font.path)
      break
    end
  end

  if font_loaded then
    if option.fonts_list then
      set_config_value(option.fonts_list, option.path, renderer.font.group(fonts))
    else
      set_config_value(config, path, renderer.font.group(fonts))
    end
  end
end



---Helper function to add control for both core and plugin settings.
---@oaram pane widget
---@param option settings.option
---@param plugin_name? string | nil
local function add_control(pane, option)
  local found = false
  local path = option.path
  local option_value = nil
  if type(path) ~= "nil" then
    option_value = get_config_value(config, path, option.default)
  end

  if option.get_value then
    option_value = option.get_value(option_value)
  end

  ---@type widget
  local widget = nil

  if type(option.type) == "string" then
    option.type = CONST_SETTINGS_TYPES[option.type:upper()]
  end

  if option.type == CONST_SETTINGS_TYPES.NUMBER then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.numberbox
    local number = NumberBox(pane, option_value, option.min, option.max, option.step)
    widget = number
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.TOGGLE then
    ---@type widget.toggle
    local toggle = Toggle(pane, option.label, option_value)
    widget = toggle
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.STRING then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.textbox
    local string = TextBox(pane, option_value or "")
    widget = string
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.SELECTION then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.selectbox
    local select = SelectBox(pane)
    for _, data in pairs(option.values) do
      select:add_option(data[1], data[2])
    end
    for idx, _ in ipairs(select.list.rows) do
      if select.list:get_row_data(idx) == option_value then
        select:set_selected(idx-1)
        break
      end
    end
    widget = select
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.BUTTON then
    ---@type widget.button
    local button = Button(pane, option.label)
    if option.icon then
      button:set_icon(option.icon)
    end
    if option.on_click then
      local command_type = type(option.on_click)
      if command_type == "string" then
        function button:on_click()
          command.perform(option.on_click)
        end
      elseif command_type == "function" then
        button.on_click = option.on_click
      end
    end
    widget = button
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.LIST_STRINGS then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.itemslist
    local list = ItemsList(pane)
    if type(option_value) == "table" then
      for _, value in ipairs(option_value) do
        list:add_item(value)
      end
    end
    widget = list
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.FONT then
    --get fonts without conversion to renderer.font
    if type(path) ~= "nil" then
      if not option.font_error then
        option_value = get_config_value(settings.config, path, option.default)
      else
        --fallback to default fonts if error loading user defined ones
        option_value = option.default
      end
    end
     ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.fontslist
    local fonts = FontsList(pane)
    if type(option_value) == "table" then
      for _, font in ipairs(option_value.fonts) do
        fonts:add_font(font)
      end

      local font_options = option_value.options or {
        size = style.DEFAULT_FONT_SIZE,
        antialiasing = "supixel",
        hinting = "slight"
      }
      font_options.size = font_options.size or style.DEFAULT_FONT_SIZE
      font_options.antialiasing = font_options.antialiasing or "subpixel"
      font_options.hinting = font_options.hinting or "slight"
      fonts:set_options(font_options)
    end
    widget = fonts
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.FILE then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.filepicker
    local file = FilePicker(pane, option_value or "")
    if option.exists then
      file:set_mode(FilePicker.mode.FILE_EXISTS)
    else
      file:set_mode(FilePicker.mode.FILE)
    end
    file.filters = option.filters or {}
    widget = file
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.DIRECTORY then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.filepicker
    local file = FilePicker(pane, option_value or "")
    if option.exists then
      file:set_mode(FilePicker.mode.DIRECTORY_EXISTS)
    else
      file:set_mode(FilePicker.mode.DIRECTORY)
    end
    file.filters = option.filters or {}
    widget = file
    found = true

  elseif option.type == CONST_SETTINGS_TYPES.COLOR then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.colorpicker
    local color = ColorPicker(pane, option_value)
    widget = color
    found = true
  end

  if widget and type(path) ~= "nil" then
    function widget:on_change(value)
      if self:is(SelectBox) then
        value = self:get_selected_data()
      elseif self:is(ItemsList) then
        value = self:get_items()
      elseif self:is(FontsList) then
        value = {
          fonts = self:get_fonts(),
          options = self:get_options()
        }
      end

      if option.set_value then
        value = option.set_value(value)
      end

      if self:is(FontsList) then
        local fonts = {}
        for _, font in ipairs(value.fonts) do
          table.insert(fonts, renderer.font.load(
            font.path, value.options.size * SCALE, value.options
          ))
        end
        if option.fonts_list then
          set_config_value(option.fonts_list, path, renderer.font.group(fonts))
        else
          set_config_value(config, path, renderer.font.group(fonts))
        end
      else
        set_config_value(config, path, value)
      end

      set_config_value(settings.config, path, value)
      UserSettingsStore.save_user_settings(settings.config)
      if option.on_apply then
        option.on_apply(value)
      end
    end
  end

  if (option.description or option.default) and found then
    local text = option.description or ""
    local default = ""
    local default_type = type(option.default)
    if default_type ~= "table" and default_type ~= "nil" then
      if text ~= "" then
        text = text .. " "
      end
      default = string.format("(default: %s)", option.default)
    end
     ---@type widget.label
    local description = Label(pane, text .. default)
    description.desc = true
  end
end

---Generate all the widgets for core settings.
local function load_core_settings(self_core)
  core_sections = FoldingBook(self_core)
  core_sections.border.width = 0
  core_sections.scrollable = false

  for _, section in ipairs(core_sections) do
    local options = core_sections[section]

    ---@type widget|widget.foldingbook.pane|nil
    local pane = core_sections:get_pane(section)
    -- local pane = self.notebook:get_pane(section)
    if not pane then
      pane = core_sections:add_pane(section, section)
      -- pane = self.notebook:add_pane(section, section)
    else
      pane = pane.container
    end

    for _, opt in ipairs(options) do
      ---@type settings.option
      local option = opt
      add_control(pane, option)
    end
  end

  return core_sections
end

return load_core_settings
