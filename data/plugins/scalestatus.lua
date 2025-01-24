-- mod-version:3
--[[
    scalestatus.lua
    displays current scale (zoom) in status view
    version: 20200628_155804
    originally by SwissalpS
--]]
local core = require "core"
local common = require "core.common"
local config = require "core.config"
local scale = require "plugins.scale"
local StatusView = require "core.views.statusview"

config.plugins.scalestatus = common.merge({
  enabled = true,
  format = '%.0f%%',
  -- The config specification used by the settings gui
  config_spec = {
    name = "Scale Status",
    {
      label = "Enabled",
      description = "Show or hide the scale status from the status bar.",
      path = "enabled",
      type = "toggle",
      default = true,
      on_apply = function(enabled)
        core.add_thread(function()
          if enabled then
            core.status_view:get_item("status:scale"):show()
          else
            core.status_view:get_item("status:scale"):hide()
          end
        end)
      end
    }
  }
}, config.plugins.scalestatus)

core.status_view:add_item({
  -- predicate = function()
  --   -- only show if scale changed
  --   return (scale.get() <> 1)
  -- end,
  name = "status:scale",
  alignment = StatusView.Item.RIGHT,
  get_item = function()
    local current_scale = scale.get() * 100

    if current_scale == 100 then 
      return {}
    else
      return {string.format(
        config.plugins.scalestatus.format,
        current_scale
      )}
    end
  end,
  position = 1,
  tooltip = "scale",
  separator = core.status_view.separator2
})

return true

