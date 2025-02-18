local core = require "core"
local config = require "core.config"
local command = require "core.command"
local keymap = require "core.keymap"
local style = require "themes.style"
local UserSettingsStore = require "stores.user_settings_store"

local View = require "core.view"
local DocView = require "core.views.docview"

local json_config_file = require "lib.json_config_file"


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
local FontsList = require "lib.widget.fontslist"
local ItemsList = require "lib.widget.itemslist"
local KeybindingDialog = require "lib.widget.keybinddialog"
local Fonts = require "lib.widget.fonts"
local FilePicker = require "lib.widget.filepicker"
local ColorPicker = require "lib.widget.colorpicker"
local MessageBox = require "lib.widget.messagebox"



---@class plugins.settings
local settings = {}

-- settings.core = {}
-- settings.plugins = {}
-- settings.sections = {}
-- settings.plugin_sections = {}
-- settings.config = {}
-- settings.default_keybindings = {}


-- local DEFAULT_FONT_NAME = "JetBrains Mono Regular"
-- local DEFAULT_FONT_PATH = DATADIR .. "/static/fonts/JetBrainsMono-Regular.ttf"

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
-- function settings_add(section, options, plugin_name, overwrite)
--   local category = ""
--   if plugin_name ~= nil then
--     category = "plugins"
--   else
--     category = "core"
--   end

--   if overwrite and settings[category][section] then
--     settings[category][section] = {}
--   end

--   if not settings[category][section] then
--     settings[category][section] = {}
--     if category ~= "plugins" then
--       table.insert(settings.sections, section)
--     else
--       table.insert(settings.plugin_sections, section)
--     end
--   end

--   if plugin_name ~= nil then
--     if not settings[category][section][plugin_name] then
--       settings[category][section][plugin_name] = {}
--     end
--     for _, option in ipairs(options) do
--       table.insert(settings[category][section][plugin_name], option)
--     end
--   else
--     for _, option in ipairs(options) do
--       table.insert(settings[category][section], option)
--     end
--   end
-- end


-- ---Retrieve from given config the associated value using the given path.
-- ---@param conf table
-- ---@param path string
-- ---@param default any
-- ---@return any | nil
-- local function get_config_value(conf, path, default)
--   local sections = {};
--   for match in (path.."."):gmatch("(.-)%.") do
--     table.insert(sections, match);
--   end

--   local element = conf
--   for _, section in ipairs(sections) do
--     if type(element[section]) ~= "nil" then
--       element = element[section]
--     else
--       return default
--     end
--   end

--   if type(element) == "nil" then
--     return default
--   end

--   return element
-- end

-- ---Loops the given config table using the given path and store the value.
-- ---@param conf table
-- ---@param path string
-- ---@param value any
-- local function set_config_value(conf, path, value)
--   local sections = {};
--   for match in (path.."."):gmatch("(.-)%.") do
--     table.insert(sections, match);
--   end

--   local sections_count = #sections

--   if sections_count == 1 then
--     conf[sections[1]] = value
--     return
--   elseif type(conf[sections[1]]) ~= "table" then
--     conf[sections[1]] = {}
--   end

--   local element = conf
--   for idx, section in ipairs(sections) do
--     if type(element[section]) ~= "table" then
--       element[section] = {}
--       element = element[section]
--     else
--       element = element[section]
--     end
--     if idx + 1 == sections_count then break end
--   end

--   element[sections[sections_count]] = value
-- end




---Get a list of system and user installed plugins.
---@return table<integer, string>
local function get_installed_plugins()
  local files, ordered = {}, {}

  -- load plugins
  for _, root_dir in ipairs {DATADIR, USERDIR} do
    local plugin_dir = root_dir .. "/plugins"
    for _, filename in ipairs(system.list_dir(plugin_dir) or {}) do
      local valid = false
      local file_info = system.get_file_info(plugin_dir .. "/" .. filename)
      if file_info then
        -- simple case for files: must have .lua extension
        if file_info.type == "file" and filename:match("%.lua$") then
          valid = true
          filename = filename:gsub("%.lua$", "")
        
        -- special case for directory: directory must have init.lua file
        elseif file_info.type == "dir" and system.get_file_info(plugin_dir .. "/" .. filename .. "/init.lua") then
          valid = true
        end
      end
      if valid then
        if not files[filename] then table.insert(ordered, filename) end
        files[filename] = true
      end
    end
  end

  table.sort(ordered)

  return ordered
end


-- ---Load the saved fonts into the config path or fonts_list table.
-- ---@param option settings.option
-- ---@param path string
-- ---@param saved_value any
-- local function merge_font_settings(option, path, saved_value)
--   local font_options = saved_value.options or {
--     size = style.DEFAULT_FONT_SIZE,
--     antialiasing = "supixel",
--     hinting = "slight"
--   }
--   font_options.size = font_options.size or style.DEFAULT_FONT_SIZE
--   font_options.antialiasing = font_options.antialiasing or "subpixel"
--   font_options.hinting = font_options.hinting or "slight"

--   local fonts = {}
--   local font_loaded = true
--   for _, font in ipairs(saved_value.fonts) do
--     local font_data = nil
--     font_loaded = core.try(function()
--       font_data = renderer.font.load(
--         font.path, font_options.size * SCALE, font_options
--       )
--     end)
--     if font_loaded then
--       table.insert(fonts, font_data)
--     else
--       option.font_error = true
--       stderr.error("Settings: could not load %s\n'%s - %s'", path, font.name, font.path)
--       break
--     end
--   end

--   if font_loaded then
--     if option.fonts_list then
--       set_config_value(option.fonts_list, option.path, renderer.font.group(fonts))
--     else
--       set_config_value(config, path, renderer.font.group(fonts))
--     end
--   end
-- end

-- ---Load the user_settings.lua stored options for a plugin into global config.
-- ---@param plugin_name string
-- ---@param options settings.option[]
-- local function merge_plugin_settings(plugin_name, options)
--   for _, option in pairs(options) do
--     if type(option.path) == "string" then
--       local path = "plugins." .. plugin_name .. "." .. option.path
--       local saved_value = get_config_value(settings.config, path)
--       if type(saved_value) ~= "nil" then
--         if option.type == settings.type.FONT or option.type == "font" then
--           merge_font_settings(option, path, saved_value)
--         else
--           set_config_value(config, path, saved_value)
--         end
--         if option.on_apply then
--           option.on_apply(saved_value)
--         end
--       end
--     end
--   end
-- end

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
--       settings_add(
--         -- conf.config_spec.name,
--         plugin,
--         conf.config_spec,
--         plugin
--       )
--     end
--   end
-- end

---Helper function to add control for both core and plugin settings.
---@oaram pane widget
---@param option settings.option
---@param plugin_name? string | nil
local function add_control(pane, option, plugin_name)
  local found = false
  local path = type(plugin_name) ~= "nil" and
    "plugins." .. plugin_name .. "." .. option.path or option.path
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
    option.type = settings.type[option.type:upper()]
  end

  if option.type == settings.type.NUMBER then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.numberbox
    local number = NumberBox(pane, option_value, option.min, option.max, option.step)
    widget = number
    found = true

  elseif option.type == settings.type.TOGGLE then
    ---@type widget.toggle
    local toggle = Toggle(pane, option.label, option_value)
    widget = toggle
    found = true

  elseif option.type == settings.type.STRING then
    ---@type widget.label
    Label(pane, option.label .. ":")
    ---@type widget.textbox
    local string = TextBox(pane, option_value or "")
    widget = string
    found = true

  elseif option.type == settings.type.SELECTION then
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

  elseif option.type == settings.type.BUTTON then
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

  elseif option.type == settings.type.LIST_STRINGS then
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

  elseif option.type == settings.type.FONT then
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

  elseif option.type == settings.type.FILE then
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

  elseif option.type == settings.type.DIRECTORY then
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

  elseif option.type == settings.type.COLOR then
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


---Unload a plugin settings from plugins section.
---@param plugin string
local function disable_plugin(plugin)
  -- TODO: implement 
  stderr.error("not implemented")
  -- stderr.debug("disable_plugin %s", plugin)
  -- for _, section in ipairs(settings.plugin_sections) do
  --   local plugins = settings.plugins[section]

  --   for plugin_name, options in pairs(plugins) do
  --     if plugin_name == plugin then
  --       plugin_sections:delete_pane(section)
  --     end
  --   end
  -- end

  -- if
  --   type(settings.config.enabled_plugins) == "table"
  --   and
  --   settings.config.enabled_plugins[plugin]
  -- then
  --   settings.config.enabled_plugins[plugin] = nil
  -- end
  -- if type(settings.config.disabled_plugins) ~= "table" then
  --   settings.config.disabled_plugins = {}
  -- end

  -- settings.config.disabled_plugins[plugin] = true
  -- UserSettingsStore.save_user_settings(settings.config)
end


---Load plugin and append its settings to the plugins section.
---@param plugin string
local function enable_plugin(plugin)
  -- TODO: implement 
  stderr.error("not implemented")

  -- stderr.debug("enable_plugin %s", plugin)
  -- local loaded = false
  -- local config_type = type(config.plugins[plugin])
  -- if config_type == "boolean" or config_type == "nil" then
  --   config.plugins[plugin] = {}
  --   loaded = true
  -- end

  -- require("plugins." .. plugin)

  -- if config.plugins[plugin] and config.plugins[plugin].config_spec then
  --   local conf = config.plugins[plugin].config_spec
  --   settings_add(conf.name, conf, plugin, true)
  -- end

  -- for _, section in ipairs(settings.plugin_sections) do
  --   local plugins = settings.plugins[section]

  --   for plugin_name, options in pairs(plugins) do
  --     if plugin_name == plugin then
  --       ---@type widget|widget.foldingbook.pane|nil
  --       local pane = plugin_sections:get_pane(section)
  --       if not pane then
  --         pane = plugin_sections:add_pane(section, section)
  --       else
  --         pane = pane.container
  --       end

  --       merge_plugin_settings(plugin, options)

  --       for _, opt in ipairs(options) do
  --         ---@type settings.option
  --         local option = opt
  --         add_control(pane, option, plugin_name)
  --       end
  --     end
  --   end
  -- end

  -- if
  --   type(settings.config.disabled_plugins) == "table"
  --   and
  --   settings.config.disabled_plugins[plugin]
  -- then
  --   settings.config.disabled_plugins[plugin] = nil
  -- end
  -- if type(settings.config.enabled_plugins) ~= "table" then
  --   settings.config.enabled_plugins = {}
  -- end

  -- settings.config.enabled_plugins[plugin] = true
  -- UserSettingsStore.save_user_settings(settings.config)

  -- if loaded then
  --   stderr.info("Loaded '%s' plugin", plugin)
  -- end
end

-- list of plugin sections
local plugin_sections = {}

---Generate all the widgets for plugin settings.
local function settings_plugins(plugins)
  -- list of plugin sections
  plugin_sections = FoldingBook(plugins)
  plugin_sections.border.width = 0
  plugin_sections.scrollable = false

  ---@type widget|widget.foldingbook.pane|nil
  local pane = plugin_sections:get_pane("settings_plugins_enable_disable")
  if not pane then
    pane = plugin_sections:add_pane("settings_plugins_enable_disable", "Installed")
  else
    pane = pane.container
  end

  -- requires earlier access to startup process
  Label(
    pane,
    "Notice: disabling plugins will not take effect until next restart"
  )

  Line(pane, 2, 10)

  local plugins = get_installed_plugins()
  for _, plugin in ipairs(plugins) do
    if plugin ~= "settings" then
      local enabled = false

      if
        -- (
        --   type(config.plugins[plugin]) ~= "nil"
        --   and
        --   config.plugins[plugin] ~= false
        -- )
        -- or
        (
          config.enabled_plugins
          and
          config.enabled_plugins[plugin]
        )
      then
        enabled = true
      end

      ---@type widget.toggle
      local toggle = Toggle(pane, plugin, enabled)
      function toggle:on_change(value)
        if value then
          enable_plugin(plugin)
        else
          disable_plugin(plugin)
        end
      end
    end
  end

  table.sort(plugin_sections)

  for _, section in ipairs(plugin_sections) do
    local plugins = plugins[section]

    for plugin_name, options in pairs(plugins) do
      ---@type widget|widget.foldingbook.pane|nil
      local pane = plugin_sections:get_pane(section)
      if not pane then
        pane = plugin_sections:add_pane(section, section)
      else
        pane = pane.container
      end

      for _, opt in ipairs(options) do
        ---@type settings.option
        local option = opt
        add_control(pane, option, plugin_name)
      end
    end
  end

  return plugins
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

return settings_plugins;
