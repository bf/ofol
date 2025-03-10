-- clipping code
-- interacting with renderer.set_clip_rect and .pop_clip_rect
-- refactored to clean up core

local clip_rect_stack = {{ 0,0,0,0 }}

local clipping = {}

-- clipping logic
function clipping.push_clip_rect(x, y, w, h)
  local x2, y2, w2, h2 = table.unpack(clip_rect_stack[#clip_rect_stack])
  local r, b, r2, b2 = x+w, y+h, x2+w2, y2+h2
  x, y = math.max(x, x2), math.max(y, y2)
  b, r = math.min(b, b2), math.min(r, r2)
  w, h = r-x, b-y
  table.insert(clip_rect_stack, { x, y, w, h })
  renderer.set_clip_rect(x, y, w, h)
end

-- clipping logic
function clipping.pop_clip_rect()
  table.remove(clip_rect_stack)
  local x, y, w, h = table.unpack(clip_rect_stack[#clip_rect_stack])
  renderer.set_clip_rect(x, y, w, h)
end

-- limit clipping to window size?
function clipping.limit_clip_rect_to_window_size(width, height)
  clip_rect_stack[1] = { 0, 0, width, height }
  renderer.set_clip_rect(table.unpack(clip_rect_stack[1]))
end

return clipping