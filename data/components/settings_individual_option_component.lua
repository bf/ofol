-- component for single option of specific type

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

return load_core_settings
