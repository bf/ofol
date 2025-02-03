-- stores filename with optional icon and suffix text
-- metadata used for file titles

local Object = require "core.object"
local style = require "core.style"
local stderr = require "libraries.stderr"

local FilenameWithIcon = Object:extend()

-- initialize 
function FilenameWithIcon:new(filename_text, filename_color, filename_is_bold, icon_symbol, icon_color, suffix_text, suffix_color) 
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
function FilenameWithIcon:_has_icon() 
  return (self.icon_symbol and #self.icon_symbol > 0)
end

-- returns true if a suffix exists and should be drawn
function FilenameWithIcon:_has_suffix() 
  return (self.suffix_text and #self.suffix_text > 0)
end

-- returns width of filename text
function FilenameWithIcon:_get_filename_width() 
  if self.filename_is_bold then
   return style.bold_font:get_width(self.filename_text)
  else 
    return style.font:get_width(self.filename_text)
  end
end

-- returns width of icon
function FilenameWithIcon:_get_icon_width() 
  if self:_has_icon() then
    return style.padding.x + style.icon_font:get_width(self.icon_symbol) 
  else
    return 0
  end
end

-- returns width of suffix
function FilenameWithIcon:_get_suffix_width() 
  if self:_has_suffix() then
    return style.padding.x + style.font:get_width(self.suffix_text)
  else
    return 0
  end
end

-- return total width of text + icon + suffix
function FilenameWithIcon:get_width() 
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
function FilenameWithIcon:_get_line_height() 
  style.font:get_height(" ")
end

-- draw filename with icon at position x, y
function FilenameWithIcon:draw(x, y)
  local start_x = x

  if self:_has_icon() then
    -- draw icon symbol with icon font and update starting x position for next drawing operation
    start_x = renderer.draw_text(style.icon_font, self.icon_symbol, start_x, y, self.icon_color) + style.padding.x
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
    renderer.draw_text(style.font, self.suffix_text, start_x + style.padding.x, y, self.suffix_color)
  end
end

-- custom __tostring method
function FilenameWithIcon:__tostring()
  local output = self.filename_text

  if self:_has_icon() then
    output = self.icon_symbol .. " " .. output
  end

  if self:_has_suffix() then
    output = output .. " " .. self.suffix_text
  end

  return output
end


-- return object
return FilenameWithIcon
