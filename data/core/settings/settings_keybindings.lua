local command = require "core.command"
local keymap = require "core.keymap"
local style = require "themes.style"
-- local UserSettingsStore = require "stores.user_settings_store"

local Button = require "lib.widget.button"
local TextBox = require "lib.widget.textbox"
local ListBox = require "lib.widget.listbox"
local KeybindingDialog = require "lib.widget.keybinddialog"

local SettingsTabComponent = require("components.settings_tab_component")

-- local config = UserSettingsStore.load_user_settings()
local config ={}

local default_keybindings = {}

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

---Called at core first run to store the default keybindings.
local function store_default_keybindings()
  for name, _ in pairs(command.map) do
    local keys = { keymap.get_binding(name) }
    if #keys > 0 then
      default_keybindings[name] = keys
    end
  end
end



---@type widget.keybinddialog
local keymap_dialog = KeybindingDialog()

function keymap_dialog:on_save(bindings)
  local row_value = apply_keybinding(self.command, bindings)
  if row_value then
    self.listbox:set_row(self.row_id, row_value)
  end
end

function keymap_dialog:on_reset()
  local default_keys = default_keybindings[self.command]
  local current_keys = { keymap.get_binding(self.command) }

  for _, binding in ipairs(current_keys) do
    keymap.unbind(binding, self.command)
  end

  if default_keys and #default_keys > 0 then
    local cmd = self.command
    if not config.custom_keybindings then
      config.custom_keybindings = {}
      config.custom_keybindings[cmd] = {}
    elseif not config.custom_keybindings[cmd] then
      config.custom_keybindings[cmd] = {}
    end
    local shortcuts = ""
    for _, binding in ipairs(default_keys) do
      keymap.add({[binding] = cmd})
      shortcuts = shortcuts .. binding .. "\n"
      table.insert(config.custom_keybindings[cmd], binding)
    end
    local bindings_list = shortcuts:gsub("\n$", "")
    self.listbox:set_row(self.row_id, {
      style.text, cmd, ListBox.COLEND, style.dim, bindings_list
    })
  else
    self.listbox:set_row(self.row_id, {
      style.text, self.command, ListBox.COLEND, style.dim, "none"
    })
  end
  if
    config.custom_keybindings
    and
    config.custom_keybindings[self.command]
  then
    config.custom_keybindings[self.command] = nil
    -- UserSettingsStore.save_user_settings(config)
  end
end

---Generate the list of all available commands and allow editing their keymaps.
local function load_keymap_settings(self_keybinds)
  self_keybinds.scrollable = false

  local ordered = {}
  for name, _ in pairs(command.map) do
    table.insert(ordered, name)
  end
  table.sort(ordered)

  ---@type widget.textbox
  local textbox = TextBox(self_keybinds, "", "filter bindings...")

  ---@type widget.listbox
  local listbox = ListBox(self_keybinds)

  listbox.border.width = 0

  listbox:add_column("Command")
  listbox:add_column("Bindings")

  for _, name in ipairs(ordered) do
    local keys = { keymap.get_binding(name) }
    local binding = ""
    if #keys == 1 then
      binding = keys[1]
    elseif #keys > 1 then
      binding = keys[1]
      for idx, key in ipairs(keys) do
        if idx ~= 1 then
          binding = binding .. "\n" .. key
        end
      end
    elseif #keys < 1 then
      binding = "none"
    end
    listbox:add_row({
      style.text, name, ListBox.COLEND, style.dim, binding
    }, name)
  end

  function textbox:on_change(value)
    listbox:filter(value)
  end

  function listbox:on_mouse_pressed(button, x, y, clicks)
    listbox.super.on_mouse_pressed(self, button, x, y, clicks)
    local idx = listbox:get_selected()
    local data = listbox:get_row_data(idx)
    if clicks == 2 and not keymap_dialog:is_visible() then
      local bindings = { keymap.get_binding(data) }
      keymap_dialog:set_bindings(bindings)
      keymap_dialog.row_id = idx
      keymap_dialog.command = data
      keymap_dialog.listbox = self
      keymap_dialog:show()
    end
  end

  ---@param self widget
  function self_keybinds:update_positions()
    textbox:set_position(0, 0)
    textbox:set_size(self:get_width() - self.border.width * 2)
    listbox:set_position(0, textbox:get_bottom())
    listbox:set_size(self:get_width() - self.border.width * 2, self:get_height() - textbox:get_height())
  end

  return self_keybinds
end


return SettingsTabComponent("keybindings", "Keybindings", "M", load_keymap_settings);
