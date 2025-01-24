local DocView = require "core.views.docview"
local core = require "core"

local PreviewView = DocView:extend()

PreviewView.context = "application"

function PreviewView:new(doc)
  if doc then
    PreviewView.super.new(self, doc)
  else
    core.error("error...")
  end
end

function PreviewView:get_name()
  return "[" .. PreviewView.super.get_name(self) .. "]"
end

function PreviewView:try_close(do_close)
  do_close()
end

return PreviewView
