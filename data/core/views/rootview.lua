local core = require "core"
local style = require "themes.style"
local Node = require "core.node"
local View = require "core.view"

local DocView = require "core.views.docview"

local OpenFilesStore = require "stores.open_files_store"


-- minimum distance in px after which tab dragging event will be triggered/recognized
local DRAGGING_MINIMUM_DISTANCE = (170 * SCALE * 0.05)

---@class core.rootview : core.view
---@field super core.view
---@field root_node core.node
---@field mouse core.view.position
local RootView = View:extend()

function RootView:new()
  RootView.super.new(self)
  self.root_node = Node()
  self.deferred_draws = {}
  self.mouse = { x = 0, y = 0 }
  self.drag_overlay = { x = 0, y = 0, w = 0, h = 0, visible = false, opacity = 0,
                        base_color = style.drag_overlay,
                        color = { table.unpack(style.drag_overlay) } }
  self.drag_overlay.to = { x = 0, y = 0, w = 0, h = 0 }
  self.drag_overlay_tab = { x = 0, y = 0, w = 0, h = 0, visible = false, opacity = 0,
                            base_color = style.drag_overlay_tab,
                            color = { table.unpack(style.drag_overlay_tab) } }
  self.drag_overlay_tab.to = { x = 0, y = 0, w = 0, h = 0 }
  self.grab = nil -- = {view = nil, button = nil}
  self.overlapping_view = nil
  self.first_drag_and_drop_processed = false
end


function RootView:defer_draw(fn, ...)
  table.insert(self.deferred_draws, 1, { fn = fn, ... })
end


---@return core.node
function RootView:get_active_node()
  local node = self.root_node:get_node_for_view(core.active_view)
  if not node then node = self:get_primary_node() end
  return node
end


---@return core.node
local function get_primary_node(node)
  if node.is_primary_node then
    return node
  end
  if not node:is_leaf() then
    return get_primary_node(node.child_node_a) or get_primary_node(node.child_node_b)
  end
end


-- returns the node object which contains the active view
function RootView:get_active_node_default()
  -- try to find node for active_view
  local node = self.root_node:get_node_for_view(core.active_view)

  if not node then 
    -- if nothing found, get primary node
    node = self:get_primary_node() 
  end

  if node.locked then
    -- if node is locked then use the first view (EmptyView?)
    local default_view = self:get_primary_node().views[1]
    assert(default_view, "internal error: cannot find original document node.")
    core.set_active_view(default_view)
    node = self:get_active_node()
  end

  return node
end


---@return core.node
function RootView:get_primary_node()
  return get_primary_node(self.root_node)
end


local function select_next_primary_node(node)
  if node.is_primary_node then return end
  if not node:is_leaf() then
    return select_next_primary_node(node.child_node_a) or select_next_primary_node(node.child_node_b)
  else
    local lx, ly = node:get_locked_size()
    if not lx and not ly then
      return node
    end
  end
end


function RootView:select_next_primary_node()
  return select_next_primary_node(self.root_node)
end


-- open file in editor
function RootView:open_doc(doc, go_to_line_number)
  stderr.debug("open_doc %s go_to_line_number %s", doc.filename, go_to_line_number)

  -- handle metadata for file
  OpenFilesStore.handle_open_file(doc)

  local node = self:get_active_node_default()

  -- check if doc is already opened in a view
  for i, view in ipairs(node.views) do
    -- DocView has .doc member variable
    -- this .doc is checked for to figure out if it is a DocView instance
    if view.doc == doc then
      node:set_active_view(node.views[i])

      -- move cursor to line number if needed
      if go_to_line_number then
        stderr.debug("open_doc found active view for go_to_line_number", go_to_line_number)
        -- scroll to line
        view:scroll_to_line(go_to_line_number, true, true)

        -- set cursor to beginning of line
        view.doc:set_selection(go_to_line_number, 1, go_to_line_number, 1)
      end

      -- return already opened view
      return view
    end
  end

  -- create new view
  local view = DocView(doc)

  -- add view to node
  node:add_view(view)

  self.root_node:update_layout()

  -- scroll to line if needed
  if go_to_line_number then
    stderr.debug("open_doc added new view for go_to_line_number", go_to_line_number)

    -- scroll to line
    view:scroll_to_line(go_to_line_number, true, true)

    -- set cursor to beginning of line
    view.doc:set_selection(go_to_line_number, 1, go_to_line_number, 1)
  else
    -- base case, not important where selection is
    view:scroll_to_line(view.doc:get_selection(), true, true)
  end

  return view
end


---@param keep_active boolean
function RootView:close_all_docviews(keep_active)
  self.root_node:close_all_docviews(keep_active)
end


---Obtain mouse grab.
---
---This means that mouse movements will be sent to the specified view, even when
---those occur outside of it.
---There can't be multiple mouse grabs, even for different buttons.
---@see RootView:ungrab_mouse
---@param button core.view.mousebutton
---@param view core.view
function RootView:grab_mouse(button, view)
  assert(self.grab == nil)
  self.grab = {view = view, button = button}
end


---Release mouse grab.
---
---The specified button *must* be the last button that grabbed the mouse.
---@see RootView:grab_mouse
---@param button core.view.mousebutton
function RootView:ungrab_mouse(button)
  assert(self.grab and self.grab.button == button)
  self.grab = nil
end


---Function to intercept mouse pressed events on the active view.
---Do nothing by default.
---@param button core.view.mousebutton
---@param x number
---@param y number
---@param clicks integer
function RootView.on_view_mouse_pressed(button, x, y, clicks)
  stderr.warn("on_view_mouse_pressed %d %d %d", x, y, clicks)
end


---@param button core.view.mousebutton
---@param x number
---@param y number
---@param clicks integer
---@return boolean
function RootView:on_mouse_pressed(button, x, y, clicks)
  stderr.debug("on_mouse_pressed %d %d %d", x, y, clicks)
  -- If there is a grab, release it first
  if self.grab then
    self:on_mouse_released(self.grab.button, x, y)
  end
  local dragged_divider = self.root_node:get_divider_overlapping_point(x, y)
  local node = self.root_node:get_child_overlapping_point(x, y)
  if dragged_divider and (node and not node.active_view:scrollbar_overlaps_point(x, y)) then
    self.dragged_divider = dragged_divider
    return true
  end
  if node.hovered_scroll_button > 0 then
    node:scroll_tabs(node.hovered_scroll_button)
    return true
  end
  local idx = node:get_tab_overlapping_point(x, y)
  if idx then
    if button == "middle" or node.hovered_close == idx then
      -- FIXME: node.views[idx] is invalid for middle click ont ab
      local view = node.views[idx]
      if view == nil then
        stderr.error("mouse middle button does not find view %d for total views %d", idx, #node.views)
      end
      node:close_view(self.root_node, view) 
      return true
    else
      if button == "left" then
        self.dragged_node = { node = node, idx = idx, dragging = false, drag_start_x = x, drag_start_y = y}
      end
      -- FIXME: node.views[idx] is invalid for middle click ont ab
      local view = node.views[idx]
      if view == nil then
        stderr.error("mouse click does not find view %d for total views %d", idx, #node.views)
      end
      node:set_active_view(view)
      return true
    end
  elseif not self.dragged_node then -- avoid sending on_mouse_pressed events when dragging tabs
    core.set_active_view(node.active_view)
    self:grab_mouse(button, node.active_view)
    return self.on_view_mouse_pressed(button, x, y, clicks) or node.active_view:on_mouse_pressed(button, x, y, clicks)
  end
end


function RootView:get_overlay_base_color(overlay)
  if overlay == self.drag_overlay then
    return style.drag_overlay
  else
    return style.drag_overlay_tab
  end
end


function RootView:set_show_overlay(overlay, status)
  stderr.debug("overlay: %s", status)
  overlay.visible = status
  if status then 
    -- reset colors
    -- reload base_color
    overlay.base_color = self:get_overlay_base_color(overlay)
    overlay.color[1] = overlay.base_color[1]
    overlay.color[2] = overlay.base_color[2]
    overlay.color[3] = overlay.base_color[3]
    overlay.color[4] = overlay.base_color[4]
    overlay.opacity = 0
  end
end


---@param button core.view.mousebutton
---@param x number
---@param y number
function RootView:on_mouse_released(button, x, y, ...)
  stderr.debug("root on_mouse_released %d %d", x, y)

  -- something is grabbed with the mouse
  if self.grab then
    if self.grab.button == button then
      local grabbed_view = self.grab.view
      grabbed_view:on_mouse_released(button, x, y, ...)
      self:ungrab_mouse(button)

      -- If the mouse was released over a different view, send it the mouse position
      local hovered_view = self.root_node:get_child_overlapping_point(x, y)
      if grabbed_view ~= hovered_view then
        self:on_mouse_moved(x, y, 0, 0)
      end
    end
    return
  end

  -- divider between nodes is moved via drag'n'drop
  if self.dragged_divider then
    self.dragged_divider = nil
  end

  -- node is moved via drag'n'drop
  if self.dragged_node then
    if button == "left" then
      if self.dragged_node.dragging then
        local node = self.root_node:get_child_overlapping_point(self.mouse.x, self.mouse.y)
        local dragged_node = self.dragged_node.node

        if node and not node.locked
           -- don't do anything if dragging onto own node, with only one view
           and (node ~= dragged_node or #node.views > 1) then
          local split_type = node:get_split_type(self.mouse.x, self.mouse.y)
          local view = dragged_node.views[self.dragged_node.idx]

          if split_type ~= "middle" and split_type ~= "tab" then 
            -- needs splitting
            local new_node = node:split(split_type)
            self.root_node:get_node_for_view(view):remove_view(self.root_node, view)
            new_node:add_view(view)
          elseif split_type == "middle" and node ~= dragged_node then 
            -- move to other node
            dragged_node:remove_view(self.root_node, view)
            node:add_view(view)
            self.root_node:get_node_for_view(view):set_active_view(view)
          elseif split_type == "tab" then 
            -- move besides other tabs
            local tab_index = node:get_drag_overlay_tab_position(self.mouse.x, self.mouse.y, dragged_node, self.dragged_node.idx)
            dragged_node:remove_view(self.root_node, view)
            node:add_view(view, tab_index)
            self.root_node:get_node_for_view(view):set_active_view(view)
          end

          self.root_node:update_layout()
          GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true
        end
      end

      self:set_show_overlay(self.drag_overlay, false)
      self:set_show_overlay(self.drag_overlay_tab, false)

      if self.dragged_node and self.dragged_node.dragging then
        core.request_cursor("arrow")
      end

      self.dragged_node = nil
    end
  end
end


local function resize_child_node(node, axis, value, delta)
  local accept_resize = node.child_node_a:resize(axis, value)
  if not accept_resize then
    accept_resize = node.child_node_b:resize(axis, node.size[axis] - value)
  end
  if not accept_resize then
    node.divider = node.divider + delta / node.size[axis]
  end
end


---@param x number
---@param y number
---@param dx number
---@param dy number
function RootView:on_mouse_moved(x, y, dx, dy)
  self.mouse.x, self.mouse.y = x, y

  -- todo: refactor "grabbing"
  if self.grab then
    self.grab.view:on_mouse_moved(x, y, dx, dy)
    core.request_cursor(self.grab.view.cursor)
    return
  end

  if self.dragged_divider then
    local node = self.dragged_divider
    if node:is_split_horizontally() then
      x = math.clamp(x - node.position.x, 0, self.root_node.size.x * 0.95)
      resize_child_node(node, "x", x, dx)
    elseif node:is_split_vertically() then
      y = math.clamp(y - node.position.y, 0, self.root_node.size.y * 0.95)
      resize_child_node(node, "y", y, dy)
    end
    node.divider = math.clamp(node.divider, 0.01, 0.99)
    return
  end

  local dn = self.dragged_node
  if dn and not dn.dragging then
    -- start dragging only after enough movement
    dn.dragging = math.distance(x, y, dn.drag_start_x, dn.drag_start_y) > DRAGGING_MINIMUM_DISTANCE
    if dn.dragging then
      core.request_cursor("hand")
    end
  end

  -- avoid sending on_mouse_moved events when dragging tabs
  if dn then return end

  local last_overlapping_view = self.overlapping_view
  local overlapping_node = self.root_node:get_child_overlapping_point(x, y)
  self.overlapping_view = overlapping_node and overlapping_node.active_view

  if last_overlapping_view and last_overlapping_view ~= self.overlapping_view then
    -- last_overlapping_view:on_mouse_left()
  end

  if not self.overlapping_view then return end

  self.overlapping_view:on_mouse_moved(x, y, dx, dy)
  core.request_cursor(self.overlapping_view.cursor)

  if not overlapping_node then return end

  local div = self.root_node:get_divider_overlapping_point(x, y)
  if overlapping_node:get_scroll_button_index(x, y) or overlapping_node:is_in_tab_area(x, y) then
    core.request_cursor("arrow")
  elseif div and not self.overlapping_view:scrollbar_overlaps_point(x, y) then
    if div:is_split_horizontally() then
      core.request_cursor("sizeh")
    else
      core.request_cursor("sizev")
    end
  end
end


function RootView:on_mouse_left()
  stderr.debug("on_mouse_left")
  if self.overlapping_view then
    stderr.debug("on_mouse_left with overlapping view", self.overlapping_view)
    self.overlapping_view:on_mouse_left()
  end
end


---@param filename string
---@param x number
---@param y number
---@return boolean
function RootView:on_file_dropped(filename, x, y)
  stderr.error("needs to be refactored")
  
  -- -- todo: refactor
  -- local node = self.root_node:get_child_overlapping_point(x, y)
  -- local result = node and node.active_view:on_file_dropped(filename, x, y)
  -- if result then return result end
  -- local info = system.get_file_info(filename)
  -- if info and info.type == "dir" then
  --   if self.first_drag_and_drop_processed then
  --     -- first update done, open in new window
  --     system.exec(string.format("%q %q", EXEFILE, filename))
  --   else
  --     -- DND event before first update, this is sent by macOS when folder is dropped into the dock
  --     -- first close all open documents
  --     if core.confirm_close_docs() then
  --       -- then open new folder as project
  --       local dirpath = system.absolute_path(filename)


  --       -- core.open_folder_project(dirpath)
  --     end
  --     self.first_drag_and_drop_processed = true
  --   end
  -- else
  --   local ok, doc = try_catch(core.open_doc, filename)
  --   if ok then
  --     local node = core.root_view.root_node:get_child_overlapping_point(x, y)
  --     node:set_active_view(node.active_view)
  --     core.root_view:open_doc(doc)
  --   end
  -- end
  -- return true
end


function RootView:on_mouse_wheel(...)
  local x, y = self.mouse.x, self.mouse.y
  local node = self.root_node:get_child_overlapping_point(x, y)
  return node.active_view:on_mouse_wheel(...)
end


function RootView:on_text_input(...)
  core.active_view:on_text_input(...)
end


function RootView:on_ime_text_editing(...)
  core.active_view:on_ime_text_editing(...)
end


function RootView:interpolate_drag_overlay(overlay)
  overlay.x = overlay.to.x
  overlay.y = overlay.to.y
  overlay.w = overlay.to.w
  overlay.h = overlay.to.h
  overlay.opacity = overlay.visible and 100 or 0
  overlay.color[4] = overlay.base_color[4] * overlay.opacity / 100
end


function RootView:update()
  Node.copy_position_and_size(self.root_node, self)
  self.root_node:update()
  self.root_node:update_layout()

  self:update_drag_overlay()
  self:interpolate_drag_overlay(self.drag_overlay)
  self:interpolate_drag_overlay(self.drag_overlay_tab)
  
  -- set this to true because at this point there are no drag_and_drop requests
  -- that are caused by the initial drag_and_drop into dock user action
  self.first_drag_and_drop_processed = true
end


function RootView:set_drag_overlay(overlay, x, y, w, h, immediate)
  overlay.to.x = x
  overlay.to.y = y
  overlay.to.w = w
  overlay.to.h = h
  if immediate then
    overlay.x = x
    overlay.y = y
    overlay.w = w
    overlay.h = h
  end
  if not overlay.visible then
    self:set_show_overlay(overlay, true)
  end
end


local function get_split_sizes(split_type, x, y, w, h)
  if split_type == "left" then
    w = w * .5
  elseif split_type == "right" then
    x = x + w * .5
    w = w * .5
  elseif split_type == "up" then
    h = h * .5
  elseif split_type == "down" then
    y = y + h * .5
    h = h * .5
  end
  return x, y, w, h
end


function RootView:update_drag_overlay()
  if not (self.dragged_node and self.dragged_node.dragging) then 
    -- skip when not dragging
    return 
  end
  
  local over = self.root_node:get_child_overlapping_point(self.mouse.x, self.mouse.y)
  if over and not over.locked then
    local _, _, _, tab_h = over:get_scroll_button_rect(1)
    local x, y = over.position.x, over.position.y
    local w, h = over.size.x, over.size.y
    local split_type = over:get_split_type(self.mouse.x, self.mouse.y)

    if split_type == "tab" and (over ~= self.dragged_node.node or #over.views > 1) then
      local tab_index, tab_x, tab_y, tab_w, tab_h = over:get_drag_overlay_tab_position(self.mouse.x, self.mouse.y)
      self:set_drag_overlay(self.drag_overlay_tab,
        tab_x + (tab_index and 0 or tab_w), tab_y,
        style.caret_width, tab_h,
        -- avoid showing tab overlay moving between nodes
        over ~= self.drag_overlay_tab.last_over)
      self:set_show_overlay(self.drag_overlay, false)
      self.drag_overlay_tab.last_over = over
    else
      if (over ~= self.dragged_node.node or #over.views > 1) then
        y = y + tab_h
        h = h - tab_h
        x, y, w, h = get_split_sizes(split_type, x, y, w, h)
      end
      self:set_drag_overlay(self.drag_overlay, x, y, w, h)
      self:set_show_overlay(self.drag_overlay_tab, false)
    end
  else
    self:set_show_overlay(self.drag_overlay, false)
    self:set_show_overlay(self.drag_overlay_tab, false)
  end
end


function RootView:draw_grabbed_tab()
  stderr.debug("grabbed tab")
  local dn = self.dragged_node
  local _,_, w, h = dn.node:get_tab_rect(dn.idx)
  local x = self.mouse.x - w / 2
  local y = self.mouse.y - h / 2
  local view = dn.node.views[dn.idx]
  self.root_node:draw_tab(view, true, true, x, y, w, h, true)
end


function RootView:draw_drag_overlay(ov)
  if ov.opacity > 0 then
    renderer.draw_rect(ov.x, ov.y, ov.w, ov.h, ov.color)
  end
end

-- draw root view
function RootView:draw()
  self.root_node:draw()

  while #self.deferred_draws > 0 do
    local t = table.remove(self.deferred_draws)
    t.fn(table.unpack(t))
  end

  self:draw_drag_overlay(self.drag_overlay)
  self:draw_drag_overlay(self.drag_overlay_tab)
  if self.dragged_node and self.dragged_node.dragging then
    self:draw_grabbed_tab()
  end

  -- cursor change has been requested
  if core.cursor_change_req then
    stderr.debug("cursor_change_req %s", core.cursor_change_req)

    -- set new cursor
    system.set_cursor(core.cursor_change_req)

    -- remove change request
    core.cursor_change_req = nil
  end
end


return RootView
