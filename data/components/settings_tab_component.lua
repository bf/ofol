-- stores settings page with tab title

local style = require "themes.style"

-- singleton object
local SettingsTabComponent = Object:extend()

-- initialize 
function SettingsTabComponent:new(id, tab_title, tab_icon, fn_render_widgets_in_container) 
  stderr.debug("new tab component with id %s title %s", id, tab_title)
  self.id = id
  self.tab_title = tab_title
  self.tab_icon = tab_icon

  self.fn_render_widgets_in_container = fn_render_widgets_in_container
end

-- add this settings tab to a notebook widget
function SettingsTabComponent:add_to_notebook_widget(notebook_widget)
  -- add notebook pane
  local container = notebook_widget:add_pane(self.id, self.tab_title)

  -- set icon
  notebook_widget:set_pane_icon(self.id, self.tab_icon)

  -- render content
  self.fn_render_widgets_in_container(container)

  return container
end

return SettingsTabComponent