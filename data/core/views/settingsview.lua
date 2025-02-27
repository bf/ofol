local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

local Widget = require("lib.widget")
local NoteBook = require("lib.widget.notebook")

local settings_general = require("core.settings.settings_general")
local settings_user_interface = require("core.settings.settings_user_interface")
local settings_editor = require("core.settings.settings_editor")
local settings_about = require("core.settings.settings_about")
local settings_colors = require("core.settings.settings_colors")
local settings_keybindings = require("core.settings.settings_keybindings")

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

  settings_general:add_to_notebook_widget(self.notebook)
  settings_user_interface:add_to_notebook_widget(self.notebook)
  settings_editor:add_to_notebook_widget(self.notebook)
  settings_colors:add_to_notebook_widget(self.notebook)
  settings_keybindings:add_to_notebook_widget(self.notebook)
  settings_about:add_to_notebook_widget(self.notebook)
end


---Reposition and resize core and plugin widgets.
function Settings:update()
  if not Settings.super.update(self) then return end

  -- stderr.debug("Setings:update() called")
  self.notebook:set_size(self.size.x, self.size.y)

  -- update notebook pane sub-widgets
  if self.notebook ~= nil
    and self.notebook.active_pane ~= nil 
    and self.notebook.active_pane.container ~= nil 
    and self.notebook.active_pane.container.update_positions ~= nil 
  then
    -- stderr.debug("calling update_positions() on notebook.active_pane")  
    self.notebook.active_pane.container:update_positions()
  end
end


-- --------------------------------------------------------------------------------
-- -- overwrite core run to inject previously saved settings
-- --------------------------------------------------------------------------------
-- local core_run = core.run
-- function core.run()
--   stderr.debug("overwritten core.run() in settings.lua")
--   store_default_keybindings()

--   ---@type settings.ui
--   settings.ui = Settings()

--   core_run()
-- end

--------------------------------------------------------------------------------
-- Add command and keymap to load settings view
--------------------------------------------------------------------------------
command.add(nil, {
  ["ui:settings"] = function()
    stderr.debug("show settings ui")
    -- settings.ui:show()
    core.settings_view:show()
    local node = core.root_view:get_active_node_default()
    local found = false
    for _, view in ipairs(node.views) do
      if view:is(Settings) then
        found = true
        node:set_active_view(view)
        break
      end
    end
    if not found then
      node:add_view(core.settings_view)
    end
  end,
})

keymap.add {
  ["ctrl+alt+p"] = "ui:settings"
}



return Settings;
