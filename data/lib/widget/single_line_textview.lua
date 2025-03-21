local core = require "core"
local style = require "themes.style"
local keymap = require "core.keymap"
local translate  = require "lib.widget.single_line_document_translate"

local ime = require "core.ime"
local View = require "core.view"

local SingleLineDoc = require "lib.widget.single_line_document"

local SingleLineDocView = View:extend()

SingleLineDocView.context = "application"

local function move_to_line_offset(dv, line, col, offset)
  local xo = dv.last_x_offset
  if xo.line ~= line or xo.col ~= col then
    xo.offset = dv:get_col_x_offset(line, col)
  end
  xo.line = line + offset
  xo.col = dv:get_x_offset_col(line + offset, xo.offset)
  return xo.line, xo.col
end


SingleLineDocView.translate = {
  ["previous_page"] = function(doc, line, col, dv)
    local min, max = dv:get_visible_line_range()
    return line - (max - min), 1
  end,

  ["next_page"] = function(doc, line, col, dv)
    if line == #doc.lines then
      return #doc.lines, #doc.lines[line]
    end
    local min, max = dv:get_visible_line_range()
    return line + (max - min), 1
  end,

  ["previous_line"] = function(doc, line, col, dv)
    if line == 1 then
      return 1, 1
    end
    return move_to_line_offset(dv, line, col, -1)
  end,

  ["next_line"] = function(doc, line, col, dv)
    if line == #doc.lines then
      return #doc.lines, math.huge
    end
    return move_to_line_offset(dv, line, col, 1)
  end,
}


function SingleLineDocView:new(doc)
  SingleLineDocView.super.new(self)
  self.cursor = "ibeam"
  self.scrollable = true
  self.doc = assert(doc)
  self.font = "code_font"
  self.last_x_offset = {}
  self.ime_selection = { from = 0, size = 0 }
  self.ime_status = false
  self.hovering_gutter = false
end


-- try closing something, return true if it can be closed, false if it should be stopped
function SingleLineDocView:try_close()
  if self.doc:is_dirty() and #core.get_views_referencing_doc(self.doc) == 1 then
    -- let doc handle close request
    return self.doc:try_close()
  else
    -- non-dirty docs can be closed
    return true
  end
end


-- render doc name for window title
function SingleLineDocView:get_name()
  stderr.warn("single line textview get name")
  -- return FilenameInUI.get_filename_for_window_title(self.doc.abs_filename)
end

-- return absolute filename
function SingleLineDocView:get_abs_filename()
  if self.doc.abs_filename then
    return self.doc.abs_filename
  else
    return nil
  end
end

function SingleLineDocView:get_filename()
  if self.doc.abs_filename then
    local post = self.doc:is_dirty() and "*" or ""
    return fsutils.home_encode(self.doc.abs_filename) .. post
  end
  return self:get_name()
end


function SingleLineDocView:get_scrollable_size()
  if not ConfigurationOptionStore.get_editor_scroll_past_end() then
    local _, _, _, h_scroll = self.h_scrollbar:get_track_rect()
    return self:get_editor_line_height() * (#self.doc.lines) + style.padding.y * 2 + h_scroll
  end
  return self:get_editor_line_height() * (#self.doc.lines - 1) + self.size.y
end

function SingleLineDocView:get_h_scrollable_size()
  return math.huge
end


function SingleLineDocView:get_font()
  return style[self.font]
end

local CONSTANT_LINE_HEIGHT = 1.2
function SingleLineDocView:get_editor_line_height()
  return math.floor(self:get_font():get_height() * CONSTANT_LINE_HEIGHT)
end


function SingleLineDocView:get_gutter_width()
  local padding = style.padding.x * 2
  return self:get_font():get_width(#self.doc.lines) + padding, padding
end


function SingleLineDocView:get_line_screen_position(line, col)
  local x, y = self:get_content_offset()
  local lh = self:get_editor_line_height()
  local gw = self:get_gutter_width()
  y = y + (line-1) * lh + style.padding.y
  if col then
    return x + gw + self:get_col_x_offset(line, col), y
  else
    return x + gw, y
  end
end

function SingleLineDocView:get_line_text_y_offset()
  local lh = self:get_editor_line_height()
  local th = self:get_font():get_height()
  return (lh - th) / 2
end


function SingleLineDocView:get_visible_line_range()
  local x, y, x2, y2 = self:get_content_bounds()
  local lh = self:get_editor_line_height()
  local minline = math.max(1, math.floor((y - style.padding.y) / lh) + 1)
  local maxline = math.min(#self.doc.lines, math.floor((y2 - style.padding.y) / lh) + 1)
  return minline, maxline
end


function SingleLineDocView:get_col_x_offset(line, col)
  local default_font = self:get_font()
  local _, indent_size = self.doc:get_indent_info()
  default_font:set_tab_size(indent_size)
  local column = 1
  local xoffset = 0
  -- for _, type, text in self.doc.highlighter:each_token(line) do
  local text = self.doc.lines[line]
    -- local font = style.syntax_fonts[type] or default_font
    local font = style.font
    if font ~= default_font then font:set_tab_size(indent_size) end
    local length = #text
    if column + length <= col then
      xoffset = xoffset + font:get_width(text, {tab_offset = xoffset})
      column = column + length
      if column >= col then
        return xoffset
      end
    else
      for char in string.utf8_chars(text) do
        if column >= col then
          return xoffset
        end
        xoffset = xoffset + font:get_width(char, {tab_offset = xoffset})
        column = column + #char
      end
    end
  -- end

  return xoffset
end


function SingleLineDocView:get_x_offset_col(line, x)
  local line_text = self.doc.lines[line]

  -- local xoffset, last_i, i = 0, 1, 1
  -- local default_font = self:get_font()
  -- local _, indent_size = self.doc:get_indent_info()
  -- default_font:set_tab_size(indent_size)
  -- for _, type, text in self.doc.highlighter:each_token(line) do
  --   local font = style.syntax_fonts[type] or default_font
  --   if font ~= default_font then font:set_tab_size(indent_size) end
  --   -- tab_offset is the actual number of pixels a tab should use from renderer.c
  --   local width = font:get_width(text, {tab_offset = xoffset})
  --   -- Don't take the shortcut if the width matches x,
  --   -- because we need last_i which should be calculated using utf-8.
  --   if xoffset + width < x then
  --     xoffset = xoffset + width
  --     i = i + #text
  --   else
  --     for char in string.utf8_chars(text) do
  --       -- tab_offset is the actual number of pixels a tab should use from renderer.c
  --       local w = font:get_width(char, {tab_offset = xoffset})
  --       if xoffset >= x then
  --         return (xoffset - x > w / 2) and last_i or i
  --       end
  --       xoffset = xoffset + w
  --       last_i = i
  --       i = i + #char
  --     end
  --   end
  -- end

  return #line_text
end


function SingleLineDocView:resolve_screen_position(x, y)
  local ox, oy = self:get_line_screen_position(1)
  local line = math.floor((y - oy) / self:get_editor_line_height()) + 1
  line = math.clamp(line, 1, #self.doc.lines)
  local col = self:get_x_offset_col(line, x - ox)
  return line, col
end


function SingleLineDocView:scroll_to_line(line, ignore_if_visible, instant)
  local min, max = self:get_visible_line_range()
  if not (ignore_if_visible and line > min and line < max) then
    local x, y = self:get_line_screen_position(line)
    local ox, oy = self:get_content_offset()
    local _, _, _, scroll_h = self.h_scrollbar:get_track_rect()
    self.scroll.to.y = math.max(0, y - oy - (self.size.y - scroll_h) / 2)
    if instant then
      self.scroll.y = self.scroll.to.y
    end
  end
end


function SingleLineDocView:supports_text_input()
  return true
end


function SingleLineDocView:scroll_to_make_visible(line, col)
  local _, oy = self:get_content_offset()
  local _, ly = self:get_line_screen_position(line, col)
  local lh = self:get_editor_line_height()
  local _, _, _, scroll_h = self.h_scrollbar:get_track_rect()
  local overscroll = math.min(lh * 2, self.size.y) -- always show the previous / next line when possible
  self.scroll.to.y = math.clamp(self.scroll.to.y, ly - oy - self.size.y + scroll_h + overscroll, ly - oy - lh)
  local gw = self:get_gutter_width()
  local xoffset = self:get_col_x_offset(line, col)
  local xmargin = 3 * self:get_font():get_width(' ')
  local xsup = xoffset + gw + xmargin
  local xinf = xoffset - xmargin
  local _, _, scroll_w = self.v_scrollbar:get_track_rect()
  local size_x = math.max(0, self.size.x - scroll_w)
  if xsup > self.scroll.x + size_x then
    self.scroll.to.x = xsup - size_x
  elseif xinf < self.scroll.x then
    self.scroll.to.x = math.max(0, xinf)
  end
end

function SingleLineDocView:on_mouse_moved(x, y, ...)
  SingleLineDocView.super.on_mouse_moved(self, x, y, ...)

  self.hovering_gutter = false
  local gw = self:get_gutter_width()

  if self:scrollbar_hovering() or self:scrollbar_dragging() then
    self.cursor = "arrow"
  elseif gw > 0 and x >= self.position.x and x <= (self.position.x + gw) then
    self.cursor = "arrow"
    self.hovering_gutter = true
  else
    self.cursor = "ibeam"
  end

  if self.mouse_selecting then
    local l1, c1 = self:resolve_screen_position(x, y)
    local l2, c2, snap_type = table.unpack(self.mouse_selecting)
    if keymap.modkeys["ctrl"] then
      if l1 > l2 then l1, l2 = l2, l1 end
      self.doc.selections = { }
      for i = l1, l2 do
        self.doc:set_selections(i - l1 + 1, i, math.min(c1, #self.doc.lines[i]), i, math.min(c2, #self.doc.lines[i]))
      end
    else
      if snap_type then
        l1, c1, l2, c2 = self:mouse_selection(self.doc, snap_type, l1, c1, l2, c2)
      end
      self.doc:set_selection(l1, c1, l2, c2)
    end
  end
end


function SingleLineDocView:mouse_selection(doc, snap_type, line1, col1, line2, col2)
  local swap = line2 < line1 or line2 == line1 and col2 <= col1
  if swap then
    line1, col1, line2, col2 = line2, col2, line1, col1
  end
  if snap_type == "word" then
    line1, col1 = translate.start_of_word(doc, line1, col1)
    line2, col2 = translate.end_of_word(doc, line2, col2)
  elseif snap_type == "lines" then
    col1, col2, line2 = 1, 1, line2 + 1
  end
  if swap then
    return line2, col2, line1, col1
  end
  return line1, col1, line2, col2
end


function SingleLineDocView:on_mouse_pressed(button, x, y, clicks)
  stderr.debug("on_mouse_pressed %d %d %d", x, y, clicks)
  if button ~= "left" or not self.hovering_gutter then
    return SingleLineDocView.super.on_mouse_pressed(self, button, x, y, clicks)
  end
  local line = self:resolve_screen_position(x, y)
  if keymap.modkeys["shift"] then
    local sline, scol, sline2, scol2 = self.doc:get_selection(true)
    if line > sline then
      self.doc:set_selection(sline, 1, line,  #self.doc.lines[line])
    else
      self.doc:set_selection(line, 1, sline2, #self.doc.lines[sline2])
    end
  else
    if clicks == 1 then
      self.doc:set_selection(line, 1, line, 1)
    elseif clicks == 2 then
      self.doc:set_selection(line, 1, line, #self.doc.lines[line])
    end
  end
  return true
end


function SingleLineDocView:on_mouse_released(...)
  SingleLineDocView.super.on_mouse_released(self, ...)
  self.mouse_selecting = nil
end


function SingleLineDocView:on_text_input(text)
  self.doc:text_input(text)
end

function SingleLineDocView:on_ime_text_editing(text, start, length)
  self.doc:ime_text_editing(text, start, length)
  self.ime_status = #text > 0
  self.ime_selection.from = start
  self.ime_selection.size = length

  -- Set the composition bounding box that the system IME
  -- will consider when drawing its interface
  local line1, col1, line2, col2 = self.doc:get_selection(true)
  local col = math.min(col1, col2)
  self:update_ime_location()
  self:scroll_to_make_visible(line1, col + start)
end

---Update the composition bounding box that the system IME
---will consider when drawing its interface
function SingleLineDocView:update_ime_location()
  if not self.ime_status then return end

  local line1, col1, line2, col2 = self.doc:get_selection(true)
  local x, y = self:get_line_screen_position(line1)
  local h = self:get_editor_line_height()
  local col = math.min(col1, col2)

  local x1, x2 = 0, 0

  if self.ime_selection.size > 0 then
    -- focus on a part of the text
    local from = col + self.ime_selection.from
    local to = from + self.ime_selection.size
    x1 = self:get_col_x_offset(line1, from)
    x2 = self:get_col_x_offset(line1, to)
  else
    -- focus the whole text
    x1 = self:get_col_x_offset(line1, col1)
    x2 = self:get_col_x_offset(line2, col2)
  end

  ime.set_location(x + x1, y, x2 - x1, h)
end

function SingleLineDocView:update()
  -- scroll to make caret visible and reset blink timer if it moved
  local line1, col1, line2, col2 = self.doc:get_selection()
  if (line1 ~= self.last_line1 or col1 ~= self.last_col1 or
      line2 ~= self.last_line2 or col2 ~= self.last_col2) and self.size.x > 0 then
    if core.active_view == self and not ime.editing then
      self:scroll_to_make_visible(line1, col1)
    end
    core.blink_reset()
    self.last_line1, self.last_col1 = line1, col1
    self.last_line2, self.last_col2 = line2, col2
  end

  -- update blink timer
  -- if self == core.active_view and not self.mouse_selecting and not core.window_is_being_resized then
  if self == core.active_view and not self.mouse_selecting and not WindowState:is_resizing() then
    local T = ConfigurationOptionStore.get_editor_blink_period()
    local t0 = core.blink_start
    local ta = core.blink_timer
    local tb = system.get_time()
    if ((tb - t0) % T < T / 2) ~= ((ta - t0) % T < T / 2) then
      GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true
    end
    core.blink_timer = tb
  end

  self:update_ime_location()

  SingleLineDocView.super.update(self)
end


function SingleLineDocView:draw_line_highlight(x, y)
  local lh = self:get_editor_line_height()
  renderer.draw_rect(x, y, self.size.x, lh, style.line_highlight)
end


function SingleLineDocView:draw_line_text(line, x, y)
  -- local default_font = self:get_font()
  local tx, ty = x, y + self:get_line_text_y_offset()
  local last_token = nil
  local line_text = self.doc.lines[line]

  renderer.draw_text(style.font, line_text, tx, ty, style.syntax["normal"])

  -- local tokens = self.doc.highlighter:get_line(line).tokens
  -- local tokens_count = #tokens
  -- if string.sub(tokens[tokens_count], -1) == "\n" then
  --   last_token = tokens_count - 1
  -- end
  -- local start_tx = tx
  -- for tidx, type, text in self.doc.highlighter:each_token(line) do
  --   local color = style.syntax[type]
  --   local font = style.syntax_fonts[type] or default_font
  --   -- do not render newline, fixes issue #1164
  --   if tidx == last_token then text = text:sub(1, -2) end
  --   tx = renderer.draw_text(font, text, tx, ty, color, {tab_offset = tx - start_tx})
  --   if tx > self.position.x + self.size.x then break end
  -- end
  return self:get_editor_line_height()
end


function SingleLineDocView:draw_overwrite_caret(x, y, width)
  local lh = self:get_editor_line_height()
  renderer.draw_rect(x, y + lh - style.caret_width, width, style.caret_width, style.caret)
end


function SingleLineDocView:draw_caret(x, y)
  local lh = self:get_editor_line_height()
  renderer.draw_rect(x, y, style.caret_width, lh, style.caret)
end

function SingleLineDocView:draw_line_body(line, x, y)
  -- draw highlight if any selection ends on this line
  local draw_highlight = false
  local hcl = ConfigurationOptionStore.get_editor_highlight_current_line()
  if hcl ~= false then
    for lidx, line1, col1, line2, col2 in self.doc:get_selections(false) do
      if line1 == line then
        if hcl == "no_selection" then
          if (line1 ~= line2) or (col1 ~= col2) then
            draw_highlight = false
            break
          end
        end
        draw_highlight = true
        break
      end
    end
  end
  if draw_highlight and core.active_view == self then
    self:draw_line_highlight(x + self.scroll.x, y)
  end

  -- draw selection if it overlaps this line
  local lh = self:get_editor_line_height()
  for lidx, line1, col1, line2, col2 in self.doc:get_selections(true) do
    if line >= line1 and line <= line2 then
      local text = self.doc.lines[line]
      if line1 ~= line then col1 = 1 end
      if line2 ~= line then col2 = #text + 1 end
      local x1 = x + self:get_col_x_offset(line, col1)
      local x2 = x + self:get_col_x_offset(line, col2)
      if x1 ~= x2 then
        renderer.draw_rect(x1, y, x2 - x1, lh, style.selection)
      end
    end
  end

  -- draw line's text
  return self:draw_line_text(line, x, y)
end


function SingleLineDocView:draw_line_gutter(line, x, y, width)
  local color = style.line_number
  for _, line1, _, line2 in self.doc:get_selections(true) do
    if line >= line1 and line <= line2 then
      color = style.line_number2
      break
    end
  end
  x = x + style.padding.x
  local lh = self:get_editor_line_height()
  renderer.draw_text_aligned_in_box(self:get_font(), color, line, "right", x, y, width, lh)
  return lh
end


function SingleLineDocView:draw_ime_decoration(line1, col1, line2, col2)
  local x, y = self:get_line_screen_position(line1)
  local line_size = math.max(1, SCALE)
  local lh = self:get_editor_line_height()

  -- Draw IME underline
  local x1 = self:get_col_x_offset(line1, col1)
  local x2 = self:get_col_x_offset(line2, col2)
  renderer.draw_rect(x + math.min(x1, x2), y + lh - line_size, math.abs(x1 - x2), line_size, style.text)

  -- Draw IME selection
  local col = math.min(col1, col2)
  local from = col + self.ime_selection.from
  local to = from + self.ime_selection.size
  x1 = self:get_col_x_offset(line1, from)
  if from ~= to then
    x2 = self:get_col_x_offset(line1, to)
    line_size = style.caret_width
    renderer.draw_rect(x + math.min(x1, x2), y + lh - line_size, math.abs(x1 - x2), line_size, style.caret)
  end
  self:draw_caret(x + x1, y)
end


function SingleLineDocView:draw_overlay()
  -- dont draw overlay if animations are not active
  if not AnimationState:is_active() then
    return 
  end

  if core.active_view == self then
    local minline, maxline = self:get_visible_line_range()
    -- draw caret if it overlaps this line
    local T = ConfigurationOptionStore.get_editor_blink_period()
    for _, line1, col1, line2, col2 in self.doc:get_selections() do
      if line1 >= minline and line1 <= maxline then
      -- and system.window_has_focus(core.window) then
        if ime.editing then
          self:draw_ime_decoration(line1, col1, line2, col2)
        else
          if ConfigurationOptionStore.get_editor_disable_blink() or (core.blink_timer - core.blink_start) % T < T / 2 then
            local x, y = self:get_line_screen_position(line1, col1)
            if self.doc.overwrite then
              self:draw_overwrite_caret(x, y, self:get_font():get_width(self.doc:get_char(line1, col1)))
            else
              self:draw_caret(x, y)
            end
          end
        end
      end
    end
  end
end

function SingleLineDocView:draw()
  if not self.visible then return end
  
  self:draw_background(style.background)
  local _, indent_size = self.doc:get_indent_info()
  self:get_font():set_tab_size(indent_size)

  local minline, maxline = self:get_visible_line_range()
  local lh = self:get_editor_line_height()

  local x, y = self:get_line_screen_position(minline)
  local gw, gpad = self:get_gutter_width()
  for i = minline, maxline do
    y = y + (self:draw_line_gutter(i, self.position.x, y, gpad and gw - gpad or gw) or lh)
  end

  local pos = self.position
  x, y = self:get_line_screen_position(minline)
  -- the clip below ensure we don't write on the gutter region. On the
  -- right side it is redundant with the Node's clip.
  clipping.push_clip_rect(pos.x + gw, pos.y, self.size.x - gw, self.size.y)
  for i = minline, maxline do
    y = y + (self:draw_line_body(i, x, y) or lh)
  end
  self:draw_overlay()
  clipping.pop_clip_rect()

  self:draw_scrollbar()
end

local SingleLineTextView = SingleLineDocView:extend()

function SingleLineTextView:new()
  SingleLineTextView.super.new(self, SingleLineDoc())
  -- self.doc = SingleLineDoc()
  self.gutter_width = 0
  self.hide_lines_gutter = true
  self.gutter_text_brightness = 0
  self.scrollable = true
  self.font = "font"
  self.name = View.get_name(self)

  -- self.cursor = "ibeam"

  self.size.y = 0
  self.label = ""

  -- self.ime_selection = { from = 0, size = 0 }
  -- self.ime_status = false
end


function SingleLineTextView:on_text_input(text)
  self.doc:text_input(text)
end

function SingleLineTextView:on_ime_text_editing(text, start, length)
  self.doc:ime_text_editing(text, start, length)
  self.ime_status = #text > 0
  self.ime_selection.from = start
  self.ime_selection.size = length

  -- Set the composition bounding box that the system IME
  -- will consider when drawing its interface
  local line1, col1, line2, col2 = self.doc:get_selection(true)
  local col = math.min(col1, col2)
  self:update_ime_location()
  self:scroll_to_make_visible(line1, col + start)
end

function SingleLineTextView:get_name()
  return self.name
end

function SingleLineTextView:get_scrollable_size()
  return 0
end

function SingleLineTextView:get_text()
  return self.doc:get_text(1, 1, 1, math.huge)
end

function SingleLineTextView:set_text(text, select)
  self.doc:remove(1, 1, math.huge, math.huge)
  self.doc:text_input(text)
  if select then
    self.doc:set_selection(math.huge, math.huge, 1, 1)
  end
end

function SingleLineTextView:get_gutter_width()
  return self.gutter_width or 0
end

function SingleLineTextView:get_editor_line_height()
  return math.floor(self:get_font():get_height() * 1.2)
end

function SingleLineTextView:draw_line_gutter(idx, x, y)
  if self.hide_lines_gutter then
    return
  end
  SingleLineTextView.super.draw_line_gutter(self, idx, x, y)
end

function SingleLineTextView:draw_line_highlight()
  -- no-op function to disable this functionality
end

-- Overwrite this function just to disable the clipping.push_clip_rect
function SingleLineTextView:draw()
  self:draw_background(style.background)
  local _, indent_size = self.doc:get_indent_info()
  self:get_font():set_tab_size(indent_size)

  local minline, maxline = self:get_visible_line_range()
  local lh = self:get_editor_line_height()

  local x, y = self:get_line_screen_position(minline)
  for i = minline, maxline do
    self:draw_line_gutter(i, self.position.x, y)
    y = y + lh
  end

  x, y = self:get_line_screen_position(minline)
  for i = minline, maxline do
    self:draw_line_body(i, x, y)
    y = y + lh
  end
  self:draw_overlay()

  self:draw_scrollbar()
end

return SingleLineTextView
