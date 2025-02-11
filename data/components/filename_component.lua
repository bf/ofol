-- stores filename with optional icon and suffix text
-- metadata used for file titles

local Object = require "core.object"
local style = require "core.style"
local stderr = require "libraries.stderr"

-- constants for padding between icon/suffix and text
local SPACING_BETWEEN_ICON_AND_TEXT = style.font:get_width(" ")
local SPACING_BETWEEN_SUFFIX_AND_TEXT = style.font:get_width(" ")

-- singleton object
local FilenameComponent = Object:extend()

-- initialize 
function FilenameComponent:new(filename_text, filename_color, filename_is_bold, icon_symbol, icon_color, suffix_text, suffix_color) 
  -- filename can have color and be bold
  self.filename_text = filename_text
  self.filename_color = filename_color
  self.filename_is_bold = filename_is_bold

  -- optional icon can have color
  self.icon_symbol = icon_symbol
  self.icon_color = icon_color

  -- optional suffix text can have color
  self.suffix_text = suffix_text
  self.suffix_color = suffix_color
end

-- returns true if icon exists and should be drawn
function FilenameComponent:_has_icon() 
  return (self.icon_symbol and #self.icon_symbol > 0)
end

-- returns true if a suffix exists and should be drawn
function FilenameComponent:_has_suffix() 
  return (self.suffix_text and #self.suffix_text > 0)
end

-- returns width of filename text
function FilenameComponent:_get_filename_width() 
  if self.filename_is_bold then
    return style.bold_font:get_width(self.filename_text)
  else 
    return style.font:get_width(self.filename_text)
  end
end


-- returns width of icon
function FilenameComponent:_get_icon_width() 
  if self:_has_icon() then
    return style.icon_font:get_width(self.icon_symbol) + SPACING_BETWEEN_ICON_AND_TEXT
  else
    return 0
  end
end

-- returns width of suffix
function FilenameComponent:_get_suffix_width() 
  if self:_has_suffix() then
    return style.font:get_width(self.suffix_text) + SPACING_BETWEEN_SUFFIX_AND_TEXT
  else
    return 0
  end
end

-- return total width of text + icon + suffix
function FilenameComponent:get_width() 
  local width = 0

  -- icon width
  width = width + self:_get_icon_width()

  -- text width
  width = width + self:_get_filename_width()

  -- suffix width
  width = width + self:_get_suffix_width()

  return width
end

-- return line height
function FilenameComponent:_get_line_height() 
  style.font:get_height(" ")
end

-- draw filename with icon at position x, y
function FilenameComponent:draw(x, y)
  local start_x = x

  if self:_has_icon() then
    -- draw icon symbol with icon font and update starting x position for next drawing operation
    start_x = renderer.draw_text(style.icon_font, self.icon_symbol, start_x, y, self.icon_color) + SPACING_BETWEEN_ICON_AND_TEXT
  end
  
  if self.filename_is_bold then
    -- draw filename text in bold font for bold text
    start_x = renderer.draw_text(style.bold_font, self.filename_text, start_x, y, self.filename_color)  
  else
    -- draw filename text in normal font for normal text
    start_x = renderer.draw_text(style.font, self.filename_text, start_x, y, self.filename_color)
  end
  
  if self:_has_suffix() then
    -- draw suffix text
    renderer.draw_text(style.font, self.suffix_text, start_x + SPACING_BETWEEN_SUFFIX_AND_TEXT, y, self.suffix_color)
  end
end

-- custom __tostring method
function FilenameComponent:__tostring()
  local output = ""

  if self.filename_text then
    output = self.filename_text
  end

  if self:_has_icon() then
    output = self.icon_symbol .. " " .. output
  end

  if self:_has_suffix() then
    output = output .. " " .. self.suffix_text
  end

  return output
end


-- return object
return FilenameComponent
