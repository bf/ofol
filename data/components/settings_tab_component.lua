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

  -- update_positions() function will be called by settings class
  -- whenever a notebook pane is visible
  function container:update_positions()
    stderr.debug("update_positions() called for configuration option")

      -- container:set_size(
      --   section.parent.size.x - (style.padding.x),
      --   section:get_real_height()
      -- )
    -- section:set_position(style.padding.x / 2, 0)
    local prev_child = nil
    for pos=#container.childs, 1, -1 do
      local child = container.childs[pos]

      -- start with basic padding
      local x = style.padding.x
      local y = style.padding.y
      if prev_child then
        y = prev_child:get_bottom() + style.padding.y
      end

      -- set with to full available container width
      child:set_size(container:get_width() - 2*style.padding.x, child.size.y)

      -- set position
      child:set_position(x, y)

      -- remember previous child
      prev_child = child
    end
  end

  -- render content
  self.fn_render_widgets_in_container(container)

  return container
end

return SettingsTabComponent