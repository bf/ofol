local core = require "core"
local common = require "core.common"
local config = require "core.config"
local style = require "core.style"
local Object = require "core.object"

local stderr = require "libraries.stderr"

local EmptyView = require "core.views.emptyview"
local View = require "core.view"

local Cache = require "core.cache"
local CachedTabTitles = Cache("tab-title")

local FilenameInUI = require "core.ui.filename_in_ui"


local SYMBOL_CLOSE_BUTTON = "C"
local ICON_SCROLL_BUTTON_LEFT = "<"
local ICON_SCROLL_BUTTON_RIGHT = ">"


---@class core.node : core.object
local Node = Object:extend()

function Node:new(type)
  self.type = type or "leaf"
  self.position = { x = 0, y = 0 }
  self.size = { x = 0, y = 0 }
  self.views = {}
  self.divider = 0.5

  -- shift tab x position by this value
  -- so that active tab stays visible
  self.tab_shift_by_x_so_that_active_tab_stays_visible = 0

  -- add emptyview on startup
  if self.type == "leaf" then
    self:add_view(EmptyView())
  end
end


function Node:propagate(fn, ...)
  self.a[fn](self.a, ...)
  self.b[fn](self.b, ...)
end


---@deprecated
function Node:on_mouse_moved(x, y, ...)
  core.deprecation_log("Node:on_mouse_moved")
  if self.type == "leaf" then
    self.active_view:on_mouse_moved(x, y, ...)
  else
    self:propagate("on_mouse_moved", x, y, ...)
  end
end


---@deprecated
function Node:on_mouse_released(...)
  core.deprecation_log("Node:on_mouse_released")
  if self.type == "leaf" then
    self.active_view:on_mouse_released(...)
  else
    self:propagate("on_mouse_released", ...)
  end
end


---@deprecated
function Node:on_mouse_left()
  stderr.error("Node:on_mouse_left")
  if self.type == "leaf" then
    self.active_view:on_mouse_left()
  else
    self:propagate("on_mouse_left")
  end
end


---@deprecated
function Node:on_touch_moved(...)
  core.deprecation_log("Node:on_touch_moved")
  if self.type == "leaf" then
    self.active_view:on_touch_moved(...)
  else
    self:propagate("on_touch_moved", ...)
  end
end


function Node:consume(node)
  for k, _ in pairs(self) do self[k] = nil end
  for k, v in pairs(node) do self[k] = v   end
end


local type_map = { up="vsplit", down="vsplit", left="hsplit", right="hsplit" }

-- The "locked" argument below should be in the form {x = <boolean>, y = <boolean>}
-- and it indicates if the node want to have a fixed size along the axis where the
-- boolean is true. If not it will be expanded to take all the available space.
-- The "resizable" flag indicates if, along the "locked" axis the node can be resized
-- by the user. If the node is marked as resizable their view should provide a
-- set_target_size method.
function Node:split(dir, view, locked, resizable)
  assert(self.type == "leaf", "Tried to split non-leaf node")
  local node_type = assert(type_map[dir], "Invalid direction")
  local last_active = core.active_view
  local child = Node()
  child:consume(self)
  self:consume(Node(node_type))
  self.a = child
  self.b = Node()
  if view then self.b:add_view(view) end
  if locked then
    assert(type(locked) == 'table')
    self.b.locked = locked
    self.b.resizable = resizable or false
    core.set_active_view(last_active)
  end
  if dir == "up" or dir == "left" then
    self.a, self.b = self.b, self.a
    return self.a
  end
  return self.b
end

-- remove a view / document
function Node:remove_view(root, view)
  if #self.views > 1 then
    local idx = self:get_view_idx(view)
    local removed_view = table.remove(self.views, idx)
    -- table.insert(self.closed_views, removed_view)
    if self.active_view == view then
      self:set_active_view(self.views[idx] or self.views[#self.views])
    end
  else
    local parent = self:get_parent_node(root)
    local is_a = (parent.a == self)
    local other = parent[is_a and "b" or "a"]
    local locked_size_x, locked_size_y = other:get_locked_size()
    local locked_size
    if parent.type == "hsplit" then
      locked_size = locked_size_x
    else
      locked_size = locked_size_y
    end
    local next_primary
    if self.is_primary_node then
      next_primary = core.root_view:select_next_primary_node()
    end
    if locked_size or (self.is_primary_node and not next_primary) then
      self.views = {}
      self:add_view(EmptyView())
    else
      if other == next_primary then
        next_primary = parent
      end
      parent:consume(other)
      local p = parent
      while p.type ~= "leaf" do
        p = p[is_a and "a" or "b"]
      end
      p:set_active_view(p.active_view)
      if self.is_primary_node then
        next_primary.is_primary_node = true
      end
    end
  end
  core.last_active_view = nil
end

-- close a view / document
function Node:close_view(root, view)
  stderr.debug("close view")
  if view:try_close() then
    stderr.debug("remove view")
    self:remove_view(root, view)
  end
end


-- close active document
function Node:close_active_view(root)
  self:close_view(root, self.active_view)
end


-- add a view to a certain index
function Node:add_view(view, requested_idx)
  assert(self.type == "leaf", "Tried to add view to non-leaf node")
  assert(not self.locked, "Tried to add view to locked node")
  
  stderr.debug("add_view at requested_idx %d (total: %d)", requested_idx, #self.views)

  self:print_debug_tab_order()


  -- when views has one item but it is the EmptyView
  if self.views[1] and self.views[1]:is(EmptyView) then
    -- remove EmptyView
    table.remove(self.views)

    -- if index was requested, then decrease it by one
    -- because we have removed EmptyView
    if requested_idx and requested_idx > 1 then
      requested_idx = requested_idx - 1
    end
  end

  -- when specific index is requested
  if requested_idx then
    -- check if index too small
    if requested_idx < 1 then
      stderr.error("add_view requested_idx too small: %d", requested_idx)
    end
    -- check if index is too large
    if requested_idx > #self.views + 1 then
      stderr.error("add_view requested_idx %d is larger than total views + 1: %d", requested_idx, #self.views + 1)
    end

    -- use the requested index for insertion
    table.insert(self.views, requested_idx, view)
  else
    -- no index was requested, just insert at the end
    table.insert(self.views, view)
  end

  self:print_debug_tab_order()

  -- set view as active
  self:set_active_view(view)
end

function Node:print_debug_tab_order()
  local result = string.format("[%d tabs]:", #self.views)
  for i, v in ipairs(self.views) do
    -- result = result .. string.format("[#%d %s] ", i, self:get_tab_title_text(v))
    result = result .. string.format("[#%d %s] ", i, v:get_name())
  end
  stderr.debug(result)
end

-- select a specific view
function Node:set_active_view(view)
  assert(self.type == "leaf", "Tried to set active view on non-leaf node")
  stderr.debug("select active view")

  local last_active_view = self.active_view

  -- set active view
  self.active_view = view

  -- update text input handlers
  core.set_active_view(view)

  -- send "focus lost" (falsely named "mouse left") event
  -- to the last active view
  if last_active_view and last_active_view ~= view then
    last_active_view:on_mouse_left()
  end
end


function Node:get_view_idx(view)
  for i, v in ipairs(self.views) do
    if v == view then return i end
  end
end


function Node:get_node_for_view(view)
  for _, v in ipairs(self.views) do
    if v == view then return self end
  end
  if self.type ~= "leaf" then
    return self.a:get_node_for_view(view) or self.b:get_node_for_view(view)
  end
end


function Node:get_parent_node(root)
  if root.a == self or root.b == self then
    return root
  elseif root.type ~= "leaf" then
    return self:get_parent_node(root.a) or self:get_parent_node(root.b)
  end
end


function Node:get_children(t)
  t = t or {}
  for _, view in ipairs(self.views) do
    table.insert(t, view)
  end
  if self.a then self.a:get_children(t) end
  if self.b then self.b:get_children(t) end
  return t
end

-- return the width including the padding space and separately
-- the padding space itself
local function get_scroll_button_width()
  local w = style.icon_font:get_width(ICON_SCROLL_BUTTON_RIGHT)
  local pad = w/2
  -- local pad = w
  -- return w + 2 * pad, pad
  return w + pad, pad/2
end


function Node:get_divider_overlapping_point(px, py)
  if self.type ~= "leaf" then
    local axis = self.type == "hsplit" and "x" or "y"
    if self.a:is_resizable(axis) and self.b:is_resizable(axis) then
      local p = 6
      local x, y, w, h = self:get_divider_rect()
      x, y = x - p, y - p
      w, h = w + p * 2, h + p * 2
      if px > x and py > y and px < x + w and py < y + h then
        return self
      end
    end
    return self.a:get_divider_overlapping_point(px, py)
        or self.b:get_divider_overlapping_point(px, py)
  end
end


function Node:get_tab_overlapping_point(px, py)
  if not self:should_show_tabs() then return nil end

  for view_index, _ in ipairs(self.views) do
    local x1, y1, w, h = self:get_tab_rect(view_index)
    if px >= x1 and py >= y1 and px < x1 + w and py < y1 + h then
      return view_index
    end
  end

  return nil
end


function Node:should_show_tabs()
  if self.locked then return false end
  local dn = core.root_view.dragged_node
  if #self.views > 1
     or (dn and dn.dragging) then -- show tabs while dragging
    return true
  elseif config.always_show_tabs then
    return not self.views[1]:is(EmptyView)
  end
  return false
end


function Node:get_scroll_button_index(px, py)
  if #self.views == 1 then return end
  for i = 1, 2 do
    local x, y, w, h = self:get_scroll_button_rect(i)
    if px >= x and px < x + w and py >= y and py < y + h then
      return i
    end
  end
end

-- check if tab or scroll button is hovered
function Node:tab_hovered_update(px, py)
  -- check if tab is hovered
  local tab_index = self:get_tab_overlapping_point(px, py)
  self.hovered_tab = tab_index
  self.hovered_scroll_button = 0

  if tab_index then
    local x, y, w, h = self:get_tab_rect(tab_index)
  else
    self.hovered_scroll_button = self:get_scroll_button_index(px, py) or 0
  end
end


function Node:get_child_overlapping_point(x, y)
  local child
  if self.type == "leaf" then
    return self
  elseif self.type == "hsplit" then
    child = (x < self.b.position.x) and self.a or self.b
  elseif self.type == "vsplit" then
    child = (y < self.b.position.y) and self.a or self.b
  end
  return child:get_child_overlapping_point(x, y)
end

-- returns: total height, text padding, top margin
local function get_tab_y_sizes()
  local height = style.font:get_height()
  local padding = style.padding.y
  local margin = style.margin.tab.top
  return height + (padding * 2) + margin, padding, margin
end

-- get position of scroll button
function Node:get_scroll_button_rect(index)
  assert(index == 1 or index == 2, "get_scroll_button_rect can only handle index == 1 or 2 ")

  local w, pad = get_scroll_button_width()
  local h = get_tab_y_sizes()
  local x = self.position.x

  if index == 1 then
    -- x = x + self.size.x - w * 2
    x = x
  elseif index == 2 then
    -- x = x + self.size.x - w
    x = x + w 
  end

  return x, self.position.y, w, h, 0
end

-- get total width of all preceding tabs combined (without tab at position $idx)
function Node:get_total_width_of_all_preceding_tabs(idx)
  -- stderr.debug("get_total_width_of_all_preceding_tabs %d", idx)

  -- calculate width of all preceding tabs until this one
  local sum_width_of_all_preceding_tabs = 0
  -- local counter = idx - 1

  -- iterate over all tabs on left side of $idx
  for view_index, preceding_view in ipairs(self.views) do
    -- if we reach tab with index $idx, stop
    if view_index == idx then
      break
    end

    -- add to sum
    sum_width_of_all_preceding_tabs = sum_width_of_all_preceding_tabs + self:get_tab_width_by_view(preceding_view)
  end

  -- stderr.debug("idx %d sum_width_of_all_preceding_tabs %f", idx, sum_width_of_all_preceding_tabs)
  return sum_width_of_all_preceding_tabs
end


-- rect size for specific tab
function Node:get_tab_rect(idx)
  local scroll_button_x, _, scroll_button_width, _ =  self:get_scroll_button_rect(2)

  -- load view for this tab by index
  local view_for_this_tab = self.views[idx]

  -- start x of first (leftmost) tab in the line
  local x0 = scroll_button_x + scroll_button_width - self.tab_shift_by_x_so_that_active_tab_stays_visible

  -- calculate width of all preceding tabs until this one
  local total_width_of_all_preceding_tabs = self:get_total_width_of_all_preceding_tabs(idx)

  -- start x of tab at position $idx
  local x1 = x0 + total_width_of_all_preceding_tabs

  -- calculate width of my own tab
  local my_width = self:get_tab_width_by_view(view_for_this_tab)

  -- calculate height of tab
  local h, pad_y, margin_y = get_tab_y_sizes()
  
  local rect_x = x1
  local rect_y = self.position.y
  local rect_width = my_width
  local rect_height = h
  local rect_margin_y = margin_y

  -- stderr.debug("get_tab_rect for idx %d returning x %f and width %f with y %f and height %f (rect_margin_y %f)", idx, rect_x, rect_width, rect_y, rect_height, rect_margin_y)

  return rect_x, rect_y, rect_width, rect_height, rect_margin_y
end


function Node:get_divider_rect()
  local x, y = self.position.x, self.position.y
  if self.type == "hsplit" then
    return x + self.a.size.x, y, style.divider_size, self.size.y
  elseif self.type == "vsplit" then
    return x, y + self.a.size.y, self.size.x, style.divider_size
  end
end


-- Return two values for x and y axis and each of them is either falsy or a number.
-- A falsy value indicate no fixed size along the corresponding direction.
function Node:get_locked_size()
  if self.type == "leaf" then
    if self.locked then
      local size = self.active_view.size
      -- The values below should be either a falsy value or a number
      local sx = (self.locked and self.locked.x) and size.x
      local sy = (self.locked and self.locked.y) and size.y
      return sx, sy
    end
  else
    local x1, y1 = self.a:get_locked_size()
    local x2, y2 = self.b:get_locked_size()
    -- The values below should be either a falsy value or a number
    local sx, sy
    if self.type == 'hsplit' then
      if x1 and x2 then
        local dsx = (x1 < 1 or x2 < 1) and 0 or style.divider_size
        sx = x1 + x2 + dsx
      end
      sy = y1 or y2
    else
      if y1 and y2 then
        local dsy = (y1 < 1 or y2 < 1) and 0 or style.divider_size
        sy = y1 + y2 + dsy
      end
      sx = x1 or x2
    end
    return sx, sy
  end
end


function Node.copy_position_and_size(dst, src)
  dst.position.x, dst.position.y = src.position.x, src.position.y
  dst.size.x, dst.size.y = src.size.x, src.size.y
end


-- calculating the sizes is the same for hsplits and vsplits, except the x/y
-- axis are swapped; this function lets us use the same code for both
local function calc_split_sizes(self, x, y, x1, x2, y1, y2)
  local ds = ((x1 and x1 < 1) or (x2 and x2 < 1)) and 0 or style.divider_size
  local n = x1 and x1 + ds or (x2 and self.size[x] - x2 or math.floor(self.size[x] * self.divider))
  self.a.position[x] = self.position[x]
  self.a.position[y] = self.position[y]
  self.a.size[x] = n - ds
  self.a.size[y] = self.size[y]
  self.b.position[x] = self.position[x] + n
  self.b.position[y] = self.position[y]
  self.b.size[x] = self.size[x] - n
  self.b.size[y] = self.size[y]
end


function Node:update_layout()
  if self.type == "leaf" then
    local av = self.active_view
    if self:should_show_tabs() then
      local _, _, _, th = self:get_tab_rect(1)
      av.position.x, av.position.y = self.position.x, self.position.y + th
      av.size.x, av.size.y = self.size.x, self.size.y - th
    else
      Node.copy_position_and_size(av, self)
    end
  else
    local x1, y1 = self.a:get_locked_size()
    local x2, y2 = self.b:get_locked_size()
    if self.type == "hsplit" then
      calc_split_sizes(self, "x", "y", x1, x2)
    elseif self.type == "vsplit" then
      calc_split_sizes(self, "y", "x", y1, y2)
    end
    self.a:update_layout()
    self.b:update_layout()
  end
end


-- scroll tabs, with parameter
-- scroll_direction = 1 for backwards scroll and 
-- scroll_direction = 2 for forwards scroll
function Node:scroll_tabs(scroll_direction)
  assert(scroll_direction == 1 or scroll_direction == 2, "scroll_tabs requires scroll_direction to be 1 (backwards) or 2 (forwards)")

  -- get active view index
  local view_index = self:get_view_idx(self.active_view)

  -- determine next view index
  local go_to_view_index

  -- backwards scrolling
  if scroll_direction == 1 then
    if view_index > 1 then
      -- scroll backwards
      go_to_view_index = view_index - 1
    else 
      -- wrap over to last item
      go_to_view_index = #self.views
    end
  elseif scroll_direction == 2 then
    if view_index < #self.views then
    -- scroll forwards
      go_to_view_index = view_index + 1
    else
      -- wrap over to first item
      go_to_view_index = 1
    end
  end

  stderr.debug("scroll_tabs direction %d view_index %d -> go_to_view_index %d", scroll_direction, view_index, go_to_view_index)

  -- change to new index
  self:set_active_view(self.views[go_to_view_index])
end


function Node:update()
  if self.type == "leaf" then
    local total_tab_width = 0
    for view_index, view in ipairs(self.views) do
      view:update()
      total_tab_width = total_tab_width + self:get_tab_width_by_view(view)
      -- stderr.debug("view_index %d total_tab_width %f ", view_index, total_tab_width)
    end

    self:tab_hovered_update(core.root_view.mouse.x, core.root_view.mouse.y)
  else
    self.a:update()
    self.b:update()
  end
end

-- function Node:get_tab_title_text(view, font, w) 
--   local text = view and view:get_name() or ""
--   -- stderr.debug("get_tab_title_text", text)

--   -- local dots_width = font:get_width("…")
--   -- if font:get_width(text) > w then
--   --   for i = 1, #text do
--   --     local reduced_text = text:sub(1, #text - i)
--   --     if font:get_width(reduced_text) + dots_width <= w then
--   --       text = reduced_text .. "…"
--   --       break
--   --     end
--   --   end
--   -- end
--   return text
-- end

-- get width of a tab based on the tab view's file name length
function Node:get_tab_width_by_view(view) 
  stderr.debug("view %s", view)
  -- -- width of tab title text
  -- local text = self:get_tab_title_text(view, style.font, 0)
  -- local tab_title_width = style.font:get_width(text)

  -- add padding on both sides
  local padding_left_right = style.padding.x * 2

  -- -- total width is text width plus padding
  -- local tab_width = tab_title_width + padding_left_right

  -- return tab_width
  if not view["get_abs_filename"] then
    return 0
  end

  -- get absolute path for current document
  local absolute_path = view:get_abs_filename()

  -- get filename object for rendering
  local filename_for_rendering = FilenameInUI.get_filename_for_tab_title(absolute_path, false, false)

  -- get width of filename with icon and/or suffix
  local tab_width =  filename_for_rendering:get_width()

  stderr.debug("get_tab_width_by_view %f", tab_width)

  return tab_width + padding_left_right
end

function Node:draw_tab_title(view, font, is_active, is_hovered, x, y, w, h)
  -- -- stderr.debug("draw_tab_title", x, y, w, h)

  -- local text = self:get_tab_title_text(view, font, w)

  -- local align = "left"
  -- local color = style.text
  -- if is_active then color = style.accent end
  -- if is_hovered then color = style.accent end

  -- common.draw_text(font, color, text, align, x, y, w, h)


  -- get absolute path for current document
  local absolute_path = view:get_abs_filename()

  -- get filename object for rendering
  local filename_for_rendering = FilenameInUI.get_filename_for_tab_title(absolute_path, is_active, is_hovered)

  -- draw filename object
  filename_for_rendering:draw(x , y + style.font:get_height() / 2)
end

function Node:draw_tab_borders(view, is_active, is_hovered, x, y, w, h, standalone)
  -- stderr.debug("draw_tab_borders", x, y, w, h)

  -- Tabs deviders
  local ds = style.divider_size
  local color = style.dim
  local padding_y = style.padding.y
  
  renderer.draw_rect(x + w, y + padding_y, ds, h - padding_y*2, style.dim)

  if standalone then
    renderer.draw_rect(x-1, y-1, w+2, h+2, style.background2)
  end
  -- Full border
  if is_active then
    color = style.text
    renderer.draw_rect(x, y, w, h, style.background)
    renderer.draw_rect(x, y, w, ds, style.divider)
    renderer.draw_rect(x + w, y, ds, h, style.divider)
    renderer.draw_rect(x - ds, y, ds, h, style.divider)
  end
  return x + ds, y, w - ds*2, h
end

function Node:draw_tab(view, is_active, is_hovered, x, y, w, h, standalone)
  -- stderr.debug("draw_tab", x, y, w, h)

  -- stderr.debug("draw tab %s width %s", view, w)
  local _, padding_y, margin_y = get_tab_y_sizes()

  -- border
  x, y, w, h = self:draw_tab_borders(view, is_active, is_hovered, x, y + margin_y, w, h - margin_y, standalone)
  
  -- Title
  local text_start_x = x + style.padding.x
  local text_start_y = y
  local text_width = w
  local text_height = h

  core.push_clip_rect(text_start_x, text_start_y, text_width, text_height)
  self:draw_tab_title(view, style.font, is_active, is_hovered, text_start_x, text_start_y, text_width, text_height)

  core.pop_clip_rect()
end


-- return total width of all tabs
function Node:get_total_width_of_all_tabs () 
  local total_width = 0
  for view_index, view in ipairs(self.views) do 
    total_width = total_width + self:get_tab_width_by_view(view)
  end
  return total_width
end

function Node:draw_tabs()
  stderr.warn("draw_tabs()")

  -- ensure shift factor is not negative
  assert(self.tab_shift_by_x_so_that_active_tab_stays_visible >= 0, "self.tab_shift_by_x_so_that_active_tab_stays_visible should never be negative")

  local _, y, scroll_button_width, h, scroll_padding = self:get_scroll_button_rect(2)
  local x = self.position.x
  local ds = style.divider_size

  core.push_clip_rect(x, y, self.size.x, h)

  -- draw tab background
  renderer.draw_rect(x, y, self.size.x, h, style.background2)

  -- draw horizontal divider
  renderer.draw_rect(x, y + h - ds, self.size.x, ds, style.divider)

  -- if more than one tab is open, then we need to ensure that active tab 
  -- does not appear outside of the window 
  if #self.views > 1 then
    -- get index of active view
    local active_view_index = self:get_view_idx(self.active_view)

    -- get x position (start and end) for the active tab
    local active_tab_x, _, active_tab_w, _ = self:get_tab_rect(active_view_index)

    -- when shift factor is already set, figure out if it is still needed
    if self.tab_shift_by_x_so_that_active_tab_stays_visible > 0 then
      -- fetch total width of all tabs
      local total_width_of_all_tabs = self:get_total_width_of_all_tabs()

      -- check if total width fits into current tab bar width
      if self.size.x - 2 * scroll_button_width > total_width_of_all_tabs then
        -- if it fits, reset tab shift to zero
        self.tab_shift_by_x_so_that_active_tab_stays_visible = 0
      end
    end

    -- remember old shift factor
    local old_shift_factor_x = self.tab_shift_by_x_so_that_active_tab_stays_visible

    -- check if tab has grown outside right side
    if active_tab_x + active_tab_w > self.position.x + self.size.x then
      -- figure out shift factor
      self.tab_shift_by_x_so_that_active_tab_stays_visible = active_tab_x + active_tab_w + old_shift_factor_x - self.position.x - self.size.x

    -- check if tab is hidden on the left side
    elseif self.tab_shift_by_x_so_that_active_tab_stays_visible > 0 then
      -- get right corner x of the right scroll button
      local scroll_button_x, _, scroll_button_width, _ =  self:get_scroll_button_rect(2)
      local scroll_buttons_end_at_x = scroll_button_x + scroll_button_width

      -- check if active tab x is left of scroll button right side x
      if active_tab_x < scroll_buttons_end_at_x then
        -- in this case we need to move at least $active_tab_width to the left
        -- we achieve this by subtracting $active_tab_width from the current tab shift by x factor
        -- with math.max(.., 0) we ensure that it never goes below zero
        self.tab_shift_by_x_so_that_active_tab_stays_visible = math.max(old_shift_factor_x - active_tab_w, 0)
      end
    end
  end

  -- iterate over all views
  for view_index, view in ipairs(self.views) do
    -- get bounding box for tab
    local x, y, w, h = self:get_tab_rect(view_index)

    -- figure out if active / hovered
    local tab_is_active = view == self.active_view
    local tab_is_hovered = view_index == self.hovered_tab

    -- draw tab 
    self:draw_tab(view, tab_is_active, tab_is_hovered, x, y, w, h)
  end

  -- draw scroll buttons 
  -- styling for left scroll button
  local left_button_style
  if self.hovered_scroll_button == 1 then
    left_button_style = style.text 
  else 
    left_button_style = style.dim
  end

  -- styling for right scroll button
  local right_button_style
  if self.hovered_scroll_button == 2 then
    right_button_style = style.text 
  else
    right_button_style = style.dim
  end

  local scroll_button_text_align = "center"

  -- get padding for scroll buttons
  local _, pad = get_scroll_button_width()

  -- first scroll button width
  local xrb, yrb, wrb, hrb = self:get_scroll_button_rect(1)

  -- draw backgroudn for scroll button
  renderer.draw_rect(xrb + pad, yrb, wrb * 2, hrb, style.background2)

  -- draw left scroll button text
  common.draw_text(style.icon_font, left_button_style, ICON_SCROLL_BUTTON_LEFT, scroll_button_text_align, xrb, yrb, wrb, h)

  -- second scroll button
  xrb, yrb, wrb = self:get_scroll_button_rect(2)

  -- draw right scroll button text
  common.draw_text(style.icon_font, right_button_style, ICON_SCROLL_BUTTON_RIGHT, scroll_button_text_align, xrb, yrb, wrb, h)

  core.pop_clip_rect()
end


function Node:draw()
  if self.type == "leaf" then
    if self:should_show_tabs() then
      self:draw_tabs()
    end
    local pos, size = self.active_view.position, self.active_view.size
    core.push_clip_rect(pos.x, pos.y, size.x, size.y)
    self.active_view:draw()
    core.pop_clip_rect()
  else
    local x, y, w, h = self:get_divider_rect()
    renderer.draw_rect(x, y, w, h, style.divider)
    self:propagate("draw")
  end
end


function Node:is_empty()
  if self.type == "leaf" then
    return #self.views == 0 or (#self.views == 1 and self.views[1]:is(EmptyView))
  else
    return self.a:is_empty() and self.b:is_empty()
  end
end


function Node:is_in_tab_area(x, y)
  if not self:should_show_tabs() then return false end
  local _, ty, _, th = self:get_scroll_button_rect(1)
  return y >= ty and y < ty + th
end


function Node:close_all_docviews(keep_active)
  local node_active_view = self.active_view
  local lost_active_view = false
  if self.type == "leaf" then
    local i = 1
    while i <= #self.views do
      local view = self.views[i]
      if view.context == "session" and (not keep_active or view ~= self.active_view) then
        table.remove(self.views, i)
        if view == node_active_view then
          lost_active_view = true
        end
      else
        i = i + 1
      end
    end

    if #self.views == 0 and self.is_primary_node then
      -- if we are not the primary view and we had the active view it doesn't
      -- matter to reattribute the active view because, within the close_all_docviews
      -- top call, the primary node will take the active view anyway.
      -- Set the empty view and takes the active view.
      self:add_view(EmptyView())
    elseif #self.views > 0 and lost_active_view then
      -- In practice we never get there but if a view remain we need
      -- to reset the Node's active view.
      self:set_active_view(self.views[1])
    end
  else
    self.a:close_all_docviews(keep_active)
    self.b:close_all_docviews(keep_active)
    if self.a:is_empty() and not self.a.is_primary_node then
      self:consume(self.b)
    elseif self.b:is_empty() and not self.b.is_primary_node then
      self:consume(self.a)
    end
  end
end

-- Returns true for nodes that accept either "proportional" resizes (based on the
-- node.divider) or "locked" resizable nodes (along the resize axis).
function Node:is_resizable(axis)
  if self.type == 'leaf' then
    return not self.locked or not self.locked[axis] or self.resizable
  else
    local a_resizable = self.a:is_resizable(axis)
    local b_resizable = self.b:is_resizable(axis)
    return a_resizable and b_resizable
  end
end


-- Return true iff it is a locked pane along the rezise axis and is
-- declared "resizable".
function Node:is_locked_resizable(axis)
  return self.locked and self.locked[axis] and self.resizable
end


function Node:resize(axis, value)
  -- the application works fine with non-integer values but to have pixel-perfect
  -- placements of view elements, like the scrollbar, we round the value to be
  -- an integer.
  value = math.floor(value)
  if self.type == 'leaf' then
    -- If it is not locked we don't accept the
    -- resize operation here because for proportional panes the resize is
    -- done using the "divider" value of the parent node.
    if self:is_locked_resizable(axis) then
      return self.active_view:set_target_size(axis, value)
    end
  else
    if self.type == (axis == "x" and "hsplit" or "vsplit") then
      -- we are resizing a node that is splitted along the resize axis
      if self.a:is_locked_resizable(axis) and self.b:is_locked_resizable(axis) then
        local rem_value = value - self.a.size[axis]
        if rem_value >= 0 then
          return self.b.active_view:set_target_size(axis, rem_value)
        else
          self.b.active_view:set_target_size(axis, 0)
          return self.a.active_view:set_target_size(axis, value)
        end
      end
    else
      -- we are resizing a node that is splitted along the axis perpendicular
      -- to the resize axis
      local a_resizable = self.a:is_resizable(axis)
      local b_resizable = self.b:is_resizable(axis)
      if a_resizable and b_resizable then
        self.a:resize(axis, value)
        self.b:resize(axis, value)
      end
    end
  end
end

-- number of visible tabs
function Node:get_visible_tabs_number() 
  if self.views[1] and self.views[1]:is(EmptyView) then
    -- special case where we have one view but it is the
    -- "empty view" which is shown before any file is opened by the user
    return 0
  else 
    return #self.views
  end
end


function Node:get_split_type(mouse_x, mouse_y)
  local x, y = self.position.x, self.position.y
  local w, h = self.size.x, self.size.y
  local _, _, _, tab_h = self:get_scroll_button_rect(1)
  y = y + tab_h
  h = h - tab_h

  local local_mouse_x = mouse_x - x
  local local_mouse_y = mouse_y - y

  if local_mouse_y < 0 then
    return "tab"
  else
    local left_pct = local_mouse_x * 100 / w
    local top_pct = local_mouse_y * 100 / h
    if left_pct <= 30 then
      return "left"
    elseif left_pct >= 70 then
      return "right"
    elseif top_pct <= 30 then
      return "up"
    elseif top_pct >= 70 then
      return "down"
    end
    return "middle"
  end
end


function Node:get_drag_overlay_tab_position(x, y, dragged_node, dragged_index)
  local tab_index = self:get_tab_overlapping_point(x, y)
  if not tab_index then
    local first_tab_x = self:get_tab_rect(1)
    if x < first_tab_x then
      -- mouse before first visible tab
      tab_index = 1
    else
      -- mouse after last visible tab
      tab_index = self:get_visible_tabs_number() 
    end
  end
  local tab_x, tab_y, tab_w, tab_h, margin_y = self:get_tab_rect(tab_index)
  if x > tab_x + tab_w / 2 and tab_index <= #self.views then
    -- use next tab
    tab_x = tab_x + tab_w
    tab_index = tab_index + 1
  end
  if self == dragged_node and dragged_index and tab_index > dragged_index then
    -- the tab we are moving is counted in tab_index
    tab_index = tab_index - 1
    tab_x = tab_x - tab_w
  end
  return tab_index, tab_x, tab_y + margin_y, tab_w, tab_h - margin_y
end

return Node
