
local Doc = require "core.doc"

---@class core.commandview.input : core.doc
---@field super core.doc
local SingleLineDoc = Doc:extend()

function SingleLineDoc:insert(line, col, text)
  SingleLineDoc.super.insert(self, line, col, text:gsub("\n", ""))
end

return SingleLineDoc