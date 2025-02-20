-- component for single option of specific type

local core = require "core"
local config = require "core.config"
local command = require "core.command"
local style = require "themes.style"
local SettingsStore = require "stores.settings_store"

local Label = require "lib.widget.label"
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


local SettingsChangeComponent = Object:extend()

-- create new component for specific setting
function SettingsChangeComponent:new(setting_key, setting_datatype, setting_default_value)
  -- ensure setting key is provided
  if not setting_key then
    stderr.error("setting_key is required")
  end
  
  -- validate datatype
  SettingsStore.check_if_datatype_is_valid(setting_datatype)

  -- ensure default value is provided
  if not setting_default_value then
    stderr.error("setting_key %s requires a default value", setting_key)
  end

  -- ensure default value fits the datatype
  SettingsStore.check_if_value_is_valid_for_datatype(setting_key, setting_value)

  -- store member variables
  self.setting_key = setting_key
  self.setting_datatype = setting_datatype
  self.setting_default_value = setting_default_value
end


-- create UI element for user to modify a specific setting
-- widget will be chosen depending on datatype of the setting
-- once value is changed by user in the UI, update SettingStore
function SettingsChangeComponent:add_settings_change_widget_to_pane(pane, option)
  -- use member variables
  local setting_key = self.setting_key
  local setting_datatype = self.setting_datatype
  local setting_default_value = self.setting_default_value

  -- load value from the settings store
  local setting_value = SettingsStore.get(setting_key)

  -- check if get_value() function is defined
  -- which takes the value and converts it before it is stored
  if option.get_value ~= nil then
    setting_value = option.get_value(setting_value)
  end

  -- create widget for changing setting in UI 
  local widget = nil

  -- choose widget based on datatype
  if setting_datatype == SettingsStore.TYPES.NUMBER then
    -- number
    Label(pane, option.label .. ":")
    widget = NumberBox(pane, setting_value, option.min, option.max, option.step)
    
  elseif setting_datatype == SettingsStore.TYPES.TOGGLE then
    -- toggle
    widget = Toggle(pane, option.label, setting_value)

  elseif setting_datatype == SettingsStore.TYPES.STRING then
    -- string
    Label(pane, option.label .. ":")
    widget = TextBox(pane, setting_value or "")
    
  elseif setting_datatype == SettingsStore.TYPES.SELECTION then
    -- selection
    Label(pane, option.label .. ":")
    widget = SelectBox(pane)
    for _, data in pairs(option.values) do
      widget:add_option(data[1], data[2])
    end
    for idx, _ in ipairs(widget.list.rows) do
      if widget.list:get_row_data(idx) == setting_value then
        widget:set_selected(idx-1)
        break
      end
    end

  elseif setting_datatype == SettingsStore.TYPES.BUTTON then
    -- button
    widget = Button(pane, option.label)
    if option.icon then
      widget:set_icon(option.icon)
    end
    if option.on_click then
      local command_type = type(option.on_click)
      if command_type == "string" then
        function widget:on_click()
          command.perform(option.on_click)
        end
      elseif command_type == "function" then
        widget.on_click = option.on_click
      end
    end

  elseif setting_datatype == SettingsStore.TYPES.LIST_STRINGS then
    -- list of strings
    Label(pane, option.label .. ":")
    widget = ItemsList(pane)
    if type(setting_value) == "table" then
      for _, value in ipairs(setting_value) do
        widget:add_item(value)
      end
    end

  elseif setting_datatype == SettingsStore.TYPES.FILE then
    -- file on filesystem
    Label(pane, option.label .. ":")
    widget = FilePicker(pane, setting_value or "")
    if option.exists then
      widget:set_mode(FilePicker.mode.FILE_EXISTS)
    else
      widget:set_mode(FilePicker.mode.FILE)
    end
    widget.filters = option.filters or {}
    
  elseif setting_datatype == SettingsStore.TYPES.DIRECTORY then
    -- directory on filesystem
    Label(pane, option.label .. ":")
    widget = FilePicker(pane, setting_value or "")
    if option.exists then
      widget:set_mode(FilePicker.mode.DIRECTORY_EXISTS)
    else
      widget:set_mode(FilePicker.mode.DIRECTORY)
    end
    widget.filters = option.filters or {}

  elseif setting_datatype == SettingsStore.TYPES.COLOR then
    -- color selection
    Label(pane, option.label .. ":")
    widget = ColorPicker(pane, setting_value)
  
  else 
    -- throw error if datatype is not implemented
    stderr.error("setting_key %s has unsupported setting_datatype %s ", setting_key, setting_datatype)
  end

  -- throw error when no widget was created
  if not widget then
    stderr.error("no widget created for setting_key %s setting_datatype %s", setting_key, setting_datatype)
  end

  -- add onchange function to widget
  function widget:on_change(value)
    -- special cases for fetching value from widget
    if self:is(SelectBox) then
      value = self:get_selected_data()
    elseif self:is(ItemsList) then
      value = self:get_items()
    end

    -- check if option.set_value() function is defined
    if option.set_value then
      -- use set_value() to convert interval setting_value to displayed value
      value = option.set_value(value)
    end

    -- update store with new value
    SettingsStore.set(setting_key, value)

    -- check if option.on_apply() function is defined
    if option.on_apply then
      -- call on_apply() function
      option.on_apply(value)
    end
  end

  -- add label
  if option.description or setting_default_value then
    local text = option.description or ""
    local text_default = ""
    local default_type = type(setting_default_value)
    if default_type ~= "table" and default_type ~= "nil" then
      if text ~= "" then
        text = text .. " "
      end
      text_default = string.format("(default: %s)", setting_default_value)
    end
     ---@type widget.label
    local description = Label(pane, text .. text_default)
    description.desc = true
  end
end

return SettingsChangeComponent
