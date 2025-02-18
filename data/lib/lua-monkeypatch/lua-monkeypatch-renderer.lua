---Draws text onto the window.
---The function returns the X and Y coordinates of the bottom-right
---corner of the text.
---@param font renderer.font
---@param color renderer.color
---@param text string
---@param align string
---| '"left"'   # Align text to the left of the bounding box
---| '"right"'  # Align text to the right of the bounding box
---| '"center"' # Center text in the bounding box
---@param x number
---@param y number
---@param w number
---@param h number
---@return number x_advance
---@return number y_advance
renderer.draw_text_aligned_in_box = function (font, color, text, align, x,y,w,h)
  stderr.deprecated_soon("renderer.draw_text() should be directly called instead")

  local tw, th = font:get_width(text), font:get_height()
  if align == "center" then
    x = x + (w - tw) / 2
  elseif align == "right" then
    x = x + (w - tw)
  end
  y = math.round(y + (h - th) / 2)
  return renderer.draw_text(font, text, x, y, color), y + th
end
