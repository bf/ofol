
local config = {}

---The caret's blinking period, in seconds.
---
---Defaults to 0.8.
---@type number
config.blink_period = 0.8

---Disables caret blinking.
---
---Defaults to false.
---@type boolean
config.disable_blink = false

---Draws whitespaces as dots.
---This option is deprecated.
---Please use the drawwhitespace plugin instead.
---@deprecated
config.draw_whitespace = false

-- -- disable all plugins
-- config.disable_all_plugins = true

---Shows/hides the close buttons on tabs.
---When hidden, users can close tabs via keyboard shortcuts or commands.
---
---Defaults to true.
---@type boolean
config.tab_close_button = true

---Maximum number of clicks recognized by Lite XL.
---
---Defaults to 3.
---@type number
config.max_clicks = 3

-- holds the plugins real config table
local plugins_config = {}

---A table containing configuration for all the plugins.
---
---This is a metatable that automaticaly creates a minimal
---configuration when a plugin is initially configured.
---Each plugins will then call `table.merge()` to get the finalized
---plugin config.
---Do not use raw operations on this table.
---@type table
config.plugins = {}

-- allows virtual access to the plugins config table
setmetatable(config.plugins, {
  __index = function(_, k)
    if not plugins_config[k] then
      plugins_config[k] = { enabled = true, config = {} }
    end
    if plugins_config[k].enabled ~= false then
      return plugins_config[k].config
    end
    return false
  end,
  __newindex = function(_, k, v)
    if not plugins_config[k] then
      plugins_config[k] = { enabled = nil, config = {} }
    end
    if v == false and package.loaded["plugins."..k] then
      local core = require "core"
      stderr.warn("[%s] is already enabled, restart the editor for the change to take effect", k)
      return
    elseif plugins_config[k].enabled == false and v ~= false then
      plugins_config[k].enabled = true
    end
    if v == false then
      plugins_config[k].enabled = false
    elseif type(v) == "table" then
      plugins_config[k].enabled = true
      plugins_config[k].config = table.merge(plugins_config[k].config, v)
    end
  end,
  __pairs = function()
    return coroutine.wrap(function()
      for name, status in pairs(plugins_config) do
        coroutine.yield(name, status.config)
      end
    end)
  end
})


return config
