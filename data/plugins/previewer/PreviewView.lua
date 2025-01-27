local DocView = require "core.views.docview"
local stderr = require "libraries.stderr"

local PreviewView = DocView:extend()

PreviewView.context = "application"

function PreviewView:new(doc)
  if doc then
    PreviewView.super.new(self, doc)
  else
    stderr.error("error...")
  end
end

function PreviewView:get_name()
  return "[" .. PreviewView.super.get_name(self) .. "]"
end

function PreviewView:try_close(do_close)
  do_close()
end

return PreviewView
