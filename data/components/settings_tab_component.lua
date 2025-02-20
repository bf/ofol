-- stores settings page with tab title

local style = require "themes.style"

-- singleton object
local SettingsTabComponent = Object:extend()

-- initialize 
function SettingsTabComponent:new(id, tab_title, tab_icon, fn_render_settings_page_body) 
  stderr.debug("new tab component with id %s title %s", id, tab_title)
  self.id = id
  self.tab_title = tab_title
  self.tab_icon = tab_icon

  self.fn_render_settings_page_body = fn_render_settings_page_body
end

-- add this settings tab to a notebook widget
function SettingsTabComponent:add_to_notebook_widget(notebook_widget)
  -- add notebook pane
  local pane_for_rendering = notebook_widget:add_pane(self.id, self.tab_title)

  -- set icon
  notebook_widget:set_pane_icon(self.id, self.tab_icon)

  -- render content
  self.fn_render_settings_page_body(pane_for_rendering)

  return pane_for_rendering
end

return SettingsTabComponent