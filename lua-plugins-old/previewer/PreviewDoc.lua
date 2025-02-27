local Doc = require "core.doc"

local PreviewDoc = Doc:extend()

function PreviewDoc:new(filename, abs_filename, new_file)
  PreviewDoc.super.new(self, filename, abs_filename, new_file)
end

function PreviewDoc:reset_syntax()
  -- disable syntax
  self.syntax = { name = "Preview", patterns = {}, symbols = {} }
end

return PreviewDoc
