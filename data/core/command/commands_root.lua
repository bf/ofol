local core = require "core"
local style = require "themes.style"
local command = require "core.command"
local Node = require "core.node"
local DocView = require "core.views.docview"


local t = {
  ["root:close"] = function(node)
    node:close_active_view(core.root_view.root_node)
  end,

  ["root:reopen-closed"] = function(node)
    node:reopen_closed_view(core.root_view.root_node)
  end,

  ["root:close-or-quit"] = function(node)
    if node and (not node:is_empty() or not node.is_primary_node) then
      node:close_active_view(core.root_view.root_node)
    else
      core.quit()
    end
  end,

  ["root:close-all"] = function()
    core.confirm_close_docs()
  end,

  ["root:close-all-others"] = function()
    local active_doc = core.active_view and core.active_view.doc

    -- iterate over all open docs
    for i, v in ipairs(core.docs) do 
      -- ensure it is not active doc
      if v ~= active_doc then 
        -- try to close doc
        v.doc:try_close()
      end
    end
  end,

  ["root:move-tab-left"] = function(node)
    local idx = node:get_view_idx(core.active_view)
    if idx > 1 then
      table.remove(node.views, idx)
      table.insert(node.views, idx - 1, core.active_view)
    end
  end,

  ["root:move-tab-right"] = function(node)
    local idx = node:get_view_idx(core.active_view)
    if idx < #node.views then
      table.remove(node.views, idx)
      table.insert(node.views, idx + 1, core.active_view)
    end
  end
}


for i = 1, 9 do
  t["root:switch-to-tab-" .. i] = function(node)
    local view = node.views[i]
    if view then
      node:set_active_view(view)
    end
  end
end


for _, dir in ipairs { "left", "right", "up", "down" } do
  t["root:split-" .. dir] = function(node)
    local av = node.active_view
    node:split(dir)
    if av:is(DocView) then
      core.root_view:open_doc(av.doc)
    end
  end

  t["root:switch-to-" .. dir] = function(node)
    local x, y
    if dir == "left" or dir == "right" then
      y = node.position.y + node.size.y / 2
      x = node.position.x + (dir == "left" and -1 or node.size.x + style.divider_size)
    else
      x = node.position.x + node.size.x / 2
      y = node.position.y + (dir == "up"   and -1 or node.size.y + style.divider_size)
    end
    local node = core.root_view.root_node:get_child_overlapping_point(x, y)
    local sx, sy = node:get_locked_size()
    if not sx and not sy then
      core.set_active_view(node.active_view)
    end
  end
end

command.add(function()
  local node = core.root_view:get_active_node()
  local sx, sy = node:get_locked_size()
  return not sx and not sy, node
end, t)


command.add(nil, {
  ["root:scroll"] = function(delta)
    local view = core.root_view.overlapping_view or core.active_view
    if view and view.scrollable then
      view.scroll.to.y = view.scroll.to.y + delta * -1 * ConfigurationOptionStore.get_user_interface_mouse_wheel_scroll()
      return true
    end
    return false
  end,
  ["root:horizontal-scroll"] = function(delta)
    local view = core.root_view.overlapping_view or core.active_view
    if view and view.scrollable then
      view.scroll.to.x = view.scroll.to.x + delta * -1 * ConfigurationOptionStore.get_user_interface_mouse_wheel_scroll()
      return true
    end
    return false
  end
})

command.add(function(node)
    if not Node:is_extended_by(node) then node = nil end
    -- No node was specified, use the active one
    node = node or core.root_view:get_active_node()
    if not node then return false end
    return true, node
  end,
  {
    ["root:switch-to-previous-tab"] = function(node)
      local idx = node:get_view_idx(node.active_view)
      idx = idx - 1
      if idx < 1 then idx = #node.views end
      node:set_active_view(node.views[idx])
    end,

    ["root:switch-to-next-tab"] = function(node)
      local idx = node:get_view_idx(node.active_view)
      idx = idx + 1
      if idx > #node.views then idx = 1 end
      node:set_active_view(node.views[idx])
    end,

    ["root:scroll-tabs-backward"] = function(node)
      node:scroll_tabs(1)
    end,

    ["root:scroll-tabs-forward"] = function(node)
      node:scroll_tabs(2)
    end
  }
)

command.add(function()
    local node = core.root_view.root_node:get_child_overlapping_point(core.root_view.mouse.x, core.root_view.mouse.y)
    if not node then 
      return false 
    end
    
    return (node.hovered_tab or node.hovered_scroll_button > 0) and true, node
  end,
  {
    ["root:switch-to-hovered-previous-tab"] = function(node)
      command.perform("root:switch-to-previous-tab", node)
    end,

    ["root:switch-to-hovered-next-tab"] = function(node)
      command.perform("root:switch-to-next-tab", node)
    end,

    ["root:scroll-hovered-tabs-backward"] = function(node)
      command.perform("root:scroll-tabs-backward", node)
    end,

    ["root:scroll-hovered-tabs-forward"] = function(node)
      command.perform("root:scroll-tabs-forward", node)
    end
  }
)

-- double clicking the tab bar, or on the emptyview should open a new doc
command.add(function(x, y)
  local node = x and y and core.root_view.root_node:get_child_overlapping_point(x, y)
  return node and node:is_in_tab_area(x, y)
end, {
  ["tabbar:new-doc"] = function()
    command.perform("core:new-doc")
  end
})
command.add("core.views.emptyview", {
  ["emptyview:new-doc"] = function()
    command.perform("core:new-doc")
  end
})
