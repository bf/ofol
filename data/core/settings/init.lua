local core = require "core"
local config = require "core.config"
local command = require "core.command"
local keymap = require "core.keymap"
local style = require "themes.style"
-- local UserSettingsStore = require "stores.user_settings_store"
-- local SettingsStore = require "stores.settings_store"

local View = require "core.view"
local DocView = require "core.views.docview"

local Widget = require "lib.widget"

local Label = require "lib.widget.label"
local Line = require "lib.widget.line"
local NoteBook = require "lib.widget.notebook"
local Button = require "lib.widget.button"
local TextBox = require "lib.widget.textbox"
local SelectBox = require "lib.widget.selectbox"
local NumberBox = require "lib.widget.numberbox"
local Toggle = require "lib.widget.toggle"
local ListBox = require "lib.widget.listbox"
local FoldingBook = require "lib.widget.foldingbook"
local ItemsList = require "lib.widget.itemslist"
local Fonts = require "lib.widget.fonts"
local FilePicker = require "lib.widget.filepicker"
local ColorPicker = require "lib.widget.colorpicker"
local MessageBox = require "lib.widget.messagebox"

local settings_core = require("core.settings.settings_core")
local settings_general = require("core.settings.settings_general")
local settings_about = require("core.settings.settings_about")
local settings_plugins = require("core.settings.settings_plugins")
local settings_colors = require("core.settings.settings_colors")
local settings_keybindings = require("core.settings.settings_keybindings")

local SettingsTabComponent = require("components.settings_tab_component")


---@class plugins.settings
local settings = {}

settings.core = {}
settings.plugins = {}
settings.sections = {}
settings.plugin_sections = {}
settings.config = {}
settings.default_keybindings = {}


local DEFAULT_FONT_NAME = "JetBrains Mono Regular"
local DEFAULT_FONT_PATH = DATADIR .. "/static/fonts/JetBrainsMono-Regular.ttf"

---Enumeration for the different types of settings.
---@type table<string, integer>
settings.type = {
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

---@alias settings.types
---| `settings.type.STRING`
---| `settings.type.NUMBER`
---| `settings.type.TOGGLE`
---| `settings.type.SELECTION`
---| `settings.type.LIST_STRINGS`
---| `settings.type.BUTTON`
---| `settings.type.FONT`
---| `settings.type.FILE`
---| `settings.type.DIRECTORY`
---| `settings.type.COLOR`

---Represents a setting to render on a settings pane.
---@class settings.option
---Title displayed to the user eg: "My Option"
---@field public label string
---Description of the option eg: "Modifies the document indentation"
---@field public description string
---Config path in the config table, eg: section.myoption, myoption, etc...
---@field public path string
---Type of option that will be used to render an appropriate control
---@field public type settings.types | integer
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
---@param plugin_name? string Optional name of plugin
---@param overwrite? boolean Overwrite previous section options
function settings.add(section, options, plugin_name, overwrite)
  local category = ""
  if plugin_name ~= nil then
    category = "plugins"
  else
    category = "core"
  end

  if overwrite and settings[category][section] then
    settings[category][section] = {}
  end

  if not settings[category][section] then
    settings[category][section] = {}
    if category ~= "plugins" then
      table.insert(settings.sections, section)
    else
      table.insert(settings.plugin_sections, section)
    end
  end

  if plugin_name ~= nil then
    if not settings[category][section][plugin_name] then
      settings[category][section][plugin_name] = {}
    end
    for _, option in ipairs(options) do
      table.insert(settings[category][section][plugin_name], option)
    end
  else
    for _, option in ipairs(options) do
      table.insert(settings[category][section], option)
    end
  end
end

--------------------------------------------------------------------------------
-- Add Core Settings
--------------------------------------------------------------------------------

settings.add("User Interface",
  {
    {
      label = "Font",
      description = "The font and fallbacks used on non code text.",
      path = "font",
      type = settings.type.FONT,
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
    --   type = settings.type.TOGGLE,
    --   default = false,
    --   on_apply = function()
    --     core.configure_borderless_window()
    --   end
    -- },
    -- {
    --   label = "Always Show Tabs",
    --   description = "Shows tabs even if a single document is opened.",
    --   path = "always_show_tabs",
    --   type = settings.type.TOGGLE,
    --   default = true
    -- },
    -- {
    --   label = "Maximum Tabs",
    --   description = "The maximum amount of visible document tabs.",
    --   path = "max_tabs",
    --   type = settings.type.NUMBER,
    --   default = 8,
    --   min = 1,
    --   max = 100
    -- },
    -- {
    --   label = "Close Button on Tabs",
    --   description = "Display the close button on tabs.",
    --   path = "tab_close_button",
    --   type = settings.type.TOGGLE,
    --   default = true
    -- },
    {
      label = "Mouse wheel scroll rate",
      description = "The amount to scroll when using the mouse wheel.",
      path = "mouse_wheel_scroll",
      type = settings.type.NUMBER,
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
      type = settings.type.SELECTION,
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
      type = settings.type.SELECTION,
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
      type = settings.type.TOGGLE,
      default = false
    },
    {
      label = "Cursor Blinking Period",
      description = "Interval in seconds in which the cursor blinks.",
      path = "blink_period",
      type = settings.type.NUMBER,
      default = 0.8,
      min = 0.3,
      max = 2.0,
      step = 0.1
    }
  }
)

settings.add("Editor",
  {
    {
      label = "Code Font",
      description = "The font and fallbacks used on the code editor.",
      path = "code_font",
      type = settings.type.FONT,
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
      type = settings.type.SELECTION,
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
      type = settings.type.NUMBER,
      default = 2,
      min = 1,
      max = 10
    },
    {
      label = "Keep Newline Whitespace",
      description = "Do not remove whitespace when pressing enter.",
      path = "keep_newline_whitespace",
      type = settings.type.TOGGLE,
      default = false
    },
    {
      label = "Line Limit",
      description = "Amount of characters at which the line breaking column will be drawn.",
      path = "line_limit",
      type = settings.type.NUMBER,
      default = 80,
      min = 1
    },
    {
      label = "Line Height",
      description = "The amount of spacing between lines.",
      path = "line_height",
      type = settings.type.NUMBER,
      default = 1.2,
      min = 1.0,
      max = 3.0,
      step = 0.1
    },
    {
      label = "Highlight Line",
      description = "Highlight the current line.",
      path = "highlight_current_line",
      type = settings.type.SELECTION,
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
      type = settings.type.NUMBER,
      default = 10000,
      min = 100,
      max = 100000
    },
    {
      label = "Undo Merge Timeout",
      description = "Time in seconds before applying an undo action.",
      path = "undo_merge_timeout",
      type = settings.type.NUMBER,
      default = 0.3,
      min = 0.1,
      max = 1.0,
      step = 0.1
    },
    {
      label = "Symbol Pattern",
      description = "A lua pattern used to match symbols in the document.",
      path = "symbol_pattern",
      type = settings.type.STRING,
      default = "[%a_][%w_]*"
    },
    {
      label = "Non Word Characters",
      description = "A string of characters that do not belong to a word.",
      path = "non_word_chars",
      type = settings.type.STRING,
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
      type = settings.type.TOGGLE,
      default = true
    }
  }
)

settings.add("Development",
  {
    {
      label = "Core Log",
      description = "Open the list of logged messages.",
      type = settings.type.BUTTON,
      icon = "f",
      on_click = "core:open-log"
    },
    {
      label = "Log Items",
      description = "The maximum amount of entries to keep on the log UI.",
      path = "max_log_items",
      type = settings.type.NUMBER,
      default = 800,
      min = 150,
      max = 2000
    },
  }
)

settings.add("Status Bar",
  {
    {
      label = "Enabled",
      description = "Toggle the default visibility of the status bar.",
      path = "statusbar.enabled",
      type = settings.type.TOGGLE,
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
      type = settings.type.TOGGLE,
      default = true,
      on_apply = function(enabled)
        core.status_view:display_messages(enabled)
      end
    },
    {
      label = "Messages Timeout",
      description = "The amount in seconds before a notification dissapears.",
      path = "message_timeout",
      type = settings.type.NUMBER,
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

---Load the user_settings.lua stored options for a plugin into global config.
---@param plugin_name string
---@param options settings.option[]
local function merge_plugin_settings(plugin_name, options)
  for _, option in pairs(options) do
    if type(option.path) == "string" then
      local path = "plugins." .. plugin_name .. "." .. option.path
      local saved_value = get_config_value(settings.config, path)
      if type(saved_value) ~= "nil" then
        if option.type == settings.type.FONT or option.type == "font" then
          merge_font_settings(option, path, saved_value)
        else
          set_config_value(config, path, saved_value)
        end
        if option.on_apply then
          option.on_apply(saved_value)
        end
      end
    end
  end
end


---Apply a keybinding and optionally save it.
---@param cmd string
---@param bindings table<integer, string>
---@param skip_save? boolean
---@return table | nil
local function apply_keybinding(cmd, bindings, skip_save)
  local row_value = nil
  local changed = false

  local original_bindings = { keymap.get_binding(cmd) }
  for _, binding in ipairs(original_bindings) do
    keymap.unbind(binding, cmd)
  end

  if #bindings > 0 then
    if
      not skip_save
      and
      config.custom_keybindings
      and
      config.custom_keybindings[cmd]
    then
      config.custom_keybindings[cmd] = {}
    end
    local shortcuts = ""
    for _, binding in ipairs(bindings) do
      if not binding:match("%+$") and binding ~= "" and binding ~= "none" then
        keymap.add({[binding] = cmd})
        shortcuts = shortcuts .. binding .. "\n"
        if not skip_save then
          if not config.custom_keybindings then
            config.custom_keybindings = {}
            config.custom_keybindings[cmd] = {}
          elseif not config.custom_keybindings[cmd] then
            config.custom_keybindings[cmd] = {}
          end
          table.insert(config.custom_keybindings[cmd], binding)
          changed = true
        end
      end
    end
    if shortcuts ~= "" then
      local bindings_list = shortcuts:gsub("\n$", "")
      row_value = {
        style.text, cmd, ListBox.COLEND, style.dim, bindings_list
      }
    end
  elseif
    not skip_save
    and
    config.custom_keybindings
    and
    config.custom_keybindings[cmd]
  then
    config.custom_keybindings[cmd] = nil
    changed = true
  end

  if changed then
    -- UserSettingsStore.save_user_settings(config)
  end

  if not row_value then
    row_value = {
      style.text, cmd, ListBox.COLEND, style.dim, "none"
    }
  end

  return row_value
end

-- ---Merge previously saved settings without destroying the config table.
-- local function merge_settings()
--   stderr.debug("merging previously saved settings with new ones")
--   if type(settings.config) ~= "table" then return end

--   -- merge core settings
--   for _, section in ipairs(settings.sections) do
--     local options = settings.core[section]
--     for _, option in ipairs(options) do
--       if type(option.path) == "string" then
--         local saved_value = get_config_value(settings.config, option.path)
--         if type(saved_value) ~= "nil" then
--           if option.type == settings.type.FONT or option.type == "font" then
--             merge_font_settings(option, option.path, saved_value)
--           else
--             set_config_value(config, option.path, saved_value)
--           end
--           if option.on_apply then
--             option.on_apply(saved_value)
--           end
--         end
--       end
--     end
--   end

--   -- merge plugin settings
--   table.sort(settings.plugin_sections)
--   for _, section in ipairs(settings.plugin_sections) do
--     local plugins = settings.plugins[section]
--     for plugin_name, options in pairs(plugins) do
--       merge_plugin_settings(plugin_name, options)
--     end
--   end

--   -- apply custom keybindings
--   if settings.config.custom_keybindings then
--     for cmd, bindings in pairs(settings.config.custom_keybindings) do
--       apply_keybinding(cmd, bindings, true)
--     end
--   end
-- end

-- ---Scan all plugins to check if they define a config_spec and load it.
-- local function scan_plugins_spec()
--   for plugin, conf in pairs(config.plugins) do
--     if type(conf) == "table" and conf.config_spec then
--       settings.add(
--         -- conf.config_spec.name,
--         plugin,
--         conf.config_spec,
--         plugin
--       )
--     end
--   end
-- end

---Called at core first run to store the default keybindings.
local function store_default_keybindings()
  for name, _ in pairs(command.map) do
    local keys = { keymap.get_binding(name) }
    if #keys > 0 then
      settings.default_keybindings[name] = keys
    end
  end
end




---@class settings.ui : widget
---@field private notebook widget.notebook
---@field private core widget
---@field private colors widget
---@field private plugins widget
---@field private keybinds widget
---@field private about widget
---@field private core_sections widget.foldingbook
---@field private plugin_sections widget.foldingbook
local Settings = Widget:extend()

---Constructor
function Settings:new()
  Settings.super.new(self, nil, false)

  self.name = "Settings"
  self.tab_icon_symbol = "P"
  
  self.defer_draw = false
  self.border.width = 0
  self.draggable = false
  self.scrollable = false

  ---@type widget.notebook
  self.notebook = NoteBook(self)
  self.notebook.size.x = 250
  self.notebook.size.y = 300
  self.notebook.border.width = 0

  -- load about page
  self.about = settings_about:add_to_notebook_widget(self.notebook)

  -- load color settings page
  self.colors = settings_colors:add_to_notebook_widget(self.notebook)

  -- load key binding settings page
  self.keybinds = settings_keybindings:add_to_notebook_widget(self.notebook)

  -- load general settings page
  self.general = settings_general:add_to_notebook_widget(self.notebook)

  self.core = self.notebook:add_pane("core", "Core")
  -- self.colors = self.notebook:add_pane("colors", "Themes")
  self.plugins = self.notebook:add_pane("plugins", "Plugins")
  -- self.keybinds = self.notebook:add_pane("keybindings", "Keybindings")
  -- self.about = self.notebook:add_pane("about", "About")

  self.notebook:set_pane_icon("core", "P")
  -- self.notebook:set_pane_icon("colors", "W")
  self.notebook:set_pane_icon("plugins", "B")
  -- self.notebook:set_pane_icon("keybindings", "M")
  -- self.notebook:set_pane_icon("about", "i")

  self.core_sections = FoldingBook(self.core)
  self.core_sections.border.width = 0
  self.core_sections.scrollable = false

  -- self:load_core_settings()
  self.core = settings_core(self.core)

  self.plugin_sections = FoldingBook(self.plugins)
  self.plugin_sections.border.width = 0
  self.plugin_sections.scrollable = false

  -- load plugin page
  self.plugins = settings_plugins(self.plugins)

end


---Reposition and resize core and plugin widgets.
function Settings:update()
  if not Settings.super.update(self) then return end

  self.notebook:set_size(self.size.x, self.size.y)

  for _, section in ipairs({self.core_sections, self.plugin_sections}) do
    if section.parent:is_visible() then
      section:set_size(
        section.parent.size.x - (style.padding.x),
        section:get_real_height()
      )
      section:set_position(style.padding.x / 2, 0)
      for _, pane in ipairs(section.panes) do
        local prev_child = nil
        for pos=#pane.container.childs, 1, -1 do
          local child = pane.container.childs[pos]
          local x, y = 10, (10 * SCALE)
          if prev_child then
            if
              (prev_child:is(Label) and not prev_child.desc)
              or
              (child:is(Label) and child.desc)
            then
              y = prev_child:get_bottom() + (10 * SCALE)
            else
              y = prev_child:get_bottom() + (30 * SCALE)
            end
          end
          if child:is(Line) then
            x = 0
          elseif child:is(ItemsList) or child:is(FilePicker) or child:is(TextBox) then
            child:set_size(pane.container:get_width() - 20, child.size.y)
          end
          child:set_position(x, y)
          prev_child = child
        end
      end
    end
  end



  if self.keybinds:is_visible() then
    self.keybinds:update_positions()
  end

  if self.about:is_visible() then
    self.about:update_positions()
  end

  -- -- update table positions if needed
  -- if self.notebook ~= nil then
  --   -- check if notebook has any panes
  --   if #self.notebook.panes > 0 then
  --     -- loop over all panes in the notebook
  --     for pos, pane in pairs(self.notebook.panes) do
  --       -- check if pane is visible
  --       if pane.is_visible ~= nil and pane:is_visible() then
  --         -- check if custom update_positions() exists
  --         if pane.update_positions ~= nil then
  --           -- call function to update table size / positions
  --           pane:update_positions()
  --         end
  --       end
  --     end
  --   end
  -- end
end


--------------------------------------------------------------------------------
-- overwrite core run to inject previously saved settings
--------------------------------------------------------------------------------
local core_run = core.run
function core.run()
  stderr.debug("overwritten core.run() in settings.lua")
  store_default_keybindings()

  -- -- load plugins disabled by default and enabled by user
  -- local enabled_plugins = SettingsStore.get("enabled_plugins")
  -- if enabled_plugins then
  --   for name, _ in pairs(enabled_plugins) do
  --     if not config.plugins[name] then
  --       stderr.debug("loading plugin from settings.config.enabled_plugins: %s", name)
  --       require("plugins." .. name)
  --     end
  --   end
  -- end

  -- -- append all settings defined in the plugins spec
  -- scan_plugins_spec()

  -- -- merge custom settings into config
  -- merge_settings()

  ---@type settings.ui
  settings.ui = Settings()

  -- apply user chosen color theme
  if settings.config.theme and settings.config.theme ~= "default" then
    try_catch(function()
      reload_module("themes.colors." .. settings.config.theme)
    end)
  end

  core_run()
end

-- --------------------------------------------------------------------------------
-- -- Disable plugins at startup, only works if this file is the first
-- -- required on user module, or priority tag is obeyed by lite-xl.
-- --------------------------------------------------------------------------------
-- -- load custom user settings that include list of disabled plugins
-- settings.config = UserSettingsStore.load_user_settings()

-- -- only disable non already loaded plugins
-- if settings.config.disabled_plugins then
--   for name, _ in pairs(settings.config.disabled_plugins) do
--     stderr.debug("settings.config.disabled_plugins: disabling plugin %s", name)
--     if not package.loaded[name] then
--       stderr.debug("settings.config.disabled_plugins: plugin %s was not in package.loaded[], setting to false", name)
--       config.plugins[name] = false
--     end
--   end
-- end

--------------------------------------------------------------------------------
-- Add command and keymap to load settings view
--------------------------------------------------------------------------------
command.add(nil, {
  ["ui:settings"] = function()
    settings.ui:show()
    local node = core.root_view:get_active_node_default()
    local found = false
    for _, view in ipairs(node.views) do
      if view == settings.ui then
        found = true
        node:set_active_view(view)
        break
      end
    end
    if not found then
      node:add_view(settings.ui)
    end
  end,
})

keymap.add {
  ["ctrl+alt+p"] = "ui:settings"
}


--------------------------------------------------------------------------------
-- Overwrite View:new to allow setting force scrollbar status globally
--------------------------------------------------------------------------------
local view_new = View.new
function View:new()
  view_new(self)
  local mode = config.force_scrollbar_status_mode or "global"
  local globally = mode == "global"
  if globally then
    --This is delayed to allow widgets to also apply it to child views/widgets
    core.add_thread(function()
      self.v_scrollbar:set_forced_status(config.force_scrollbar_status)
      self.h_scrollbar:set_forced_status(config.force_scrollbar_status)
    end)
  end
end

return settings;
