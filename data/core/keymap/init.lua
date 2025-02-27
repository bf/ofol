local core = require "core"
local command = require "core.command"
local ime = require "core.ime"


local keymap = {}

---@alias keymap.shortcut string
---@alias keymap.command string
---@alias keymap.modkey string
---@alias keymap.pressed boolean
---@alias keymap.map table<keymap.shortcut,keymap.command|keymap.command[]>
---@alias keymap.rmap table<keymap.command, keymap.shortcut|keymap.shortcut[]>

---Pressed status of mod keys.
---@type table<keymap.modkey, keymap.pressed>
keymap.modkeys = {}

---List of commands assigned to a shortcut been the key of the map the shortcut.
---@type keymap.map
keymap.map = {}

---List of shortcuts assigned to a command been the key of the map the command.
---@type keymap.rmap
keymap.reverse_map = {}

local macos = PLATFORM == "Mac OS X"

-- Thanks to mathewmariani, taken from his lite-macos github repository.
local modkeys_os = require("core.keymap.modkeys-" .. (macos and "macos" or "generic"))

---@type table<keymap.modkey, keymap.modkey>
local modkey_map = modkeys_os.map

---@type keymap.modkey[]
local modkeys = modkeys_os.keys


---Normalizes a stroke sequence to follow the modkeys table
---@param stroke string
---@return string
local function normalize_stroke(stroke)
  local stroke_table = {}
  for key in stroke:gmatch("[^+]+") do
    table.insert(stroke_table, key)
  end
  table.sort(stroke_table, function(a, b)
    if a == b then return false end
    for _, mod in ipairs(modkeys) do
      if a == mod or b == mod then
        return a == mod
      end
    end
    return a < b
  end)
  return table.concat(stroke_table, "+")
end


---Generates a stroke sequence including currently pressed mod keys.
---@param key string
---@return string
local function key_to_stroke(key)
  local keys = { key }
  for _, mk in ipairs(modkeys) do
    if keymap.modkeys[mk] then
      table.insert(keys, mk)
    end
  end
  return normalize_stroke(table.concat(keys, "+"))
end


---Remove the given value from an array associated to a key in a table.
---@param tbl table<string, string> The table containing the key
---@param k string The key containing the array
---@param v? string The value to remove from the array
local function remove_only(tbl, k, v)
  if tbl[k] then
    if v then
      local j = 0
      for i=1, #tbl[k] do
        while tbl[k][i + j] == v do
          j = j + 1
        end
        tbl[k][i] = tbl[k][i + j]
      end
    else
      tbl[k] = nil
    end
  end
end


---Removes from a keymap.map the bindings that are already registered.
---@param map keymap.map
local function remove_duplicates(map)
  for stroke, commands in pairs(map) do
    local normalized_stroke = normalize_stroke(stroke)
    if type(commands) == "string" or type(commands) == "function" then
      commands = { commands }
    end
    if keymap.map[normalized_stroke] then
      for _, registered_cmd in ipairs(keymap.map[normalized_stroke]) do
        local j = 0
        for i=1, #commands do
          while commands[i + j] == registered_cmd do
            j = j + 1
          end
          commands[i] = commands[i + j]
        end
      end
    end
    if #commands < 1 then
      map[stroke] = nil
    else
      map[stroke] = commands
    end
  end
end

---Add bindings by replacing commands that were previously assigned to a shortcut.
---@param map keymap.map
function keymap.add_direct(map)
  for stroke, commands in pairs(map) do
    stroke = normalize_stroke(stroke)

    if type(commands) == "string" or type(commands) == "function" then
      commands = { commands }
    end
    if keymap.map[stroke] then
      for _, cmd in ipairs(keymap.map[stroke]) do
        remove_only(keymap.reverse_map, cmd, stroke)
      end
    end
    keymap.map[stroke] = commands
    for _, cmd in ipairs(commands) do
      keymap.reverse_map[cmd] = keymap.reverse_map[cmd] or {}
      table.insert(keymap.reverse_map[cmd], stroke)
    end
  end
end


---Adds bindings by appending commands to already registered shortcut or by
---replacing currently assigned commands if overwrite is specified.
---@param map keymap.map
---@param overwrite? boolean
function keymap.add(map, overwrite)
  remove_duplicates(map)
  for stroke, commands in pairs(map) do
    if macos then
      stroke = stroke:gsub("%f[%a]ctrl%f[%A]", "cmd")
    end
    stroke = normalize_stroke(stroke)
    if overwrite then
      if keymap.map[stroke] then
        for _, cmd in ipairs(keymap.map[stroke]) do
          remove_only(keymap.reverse_map, cmd, stroke)
        end
      end
      keymap.map[stroke] = commands
    else
      keymap.map[stroke] = keymap.map[stroke] or {}
      for i = #commands, 1, -1 do
        table.insert(keymap.map[stroke], 1, commands[i])
      end
    end
    for _, cmd in ipairs(commands) do
      keymap.reverse_map[cmd] = keymap.reverse_map[cmd] or {}
      table.insert(keymap.reverse_map[cmd], stroke)
    end
  end
end


---Unregisters the given shortcut and associated command.
---@param shortcut string
---@param cmd string
function keymap.unbind(shortcut, cmd)
  shortcut = normalize_stroke(shortcut)
  remove_only(keymap.map, shortcut, cmd)
  remove_only(keymap.reverse_map, cmd, shortcut)
end


---Returns all the shortcuts associated to a command unpacked for easy assignment.
---@param cmd string
---@return ...
function keymap.get_binding(cmd)
  return table.unpack(keymap.reverse_map[cmd] or {})
end


---Returns all the shortcuts associated to a command packed in a table.
---@param cmd string
---@return table<integer, string> | nil shortcuts
function keymap.get_bindings(cmd)
  return keymap.reverse_map[cmd]
end


--------------------------------------------------------------------------------
-- Events listening
--------------------------------------------------------------------------------
function keymap.on_key_pressed(k, ...)
  stderr.debug("keymap.on_key_pressed", k )
  local mk = modkey_map[k]
  if mk then
    keymap.modkeys[mk] = true
    -- work-around for windows where `altgr` is treated as `ctrl+alt`
    if mk == "altgr" then
      keymap.modkeys["ctrl"] = false
    end
  else
    local stroke = key_to_stroke(k)
    local commands, performed = keymap.map[stroke], false
    if commands then
      for _, cmd in ipairs(commands) do
        if type(cmd) == "function" then
          local ok, res = try_catch(cmd, ...)
          if ok then
            performed = not (res == false)
          else
            performed = true
          end
        else
          performed = command.perform(cmd, ...)
        end
        if performed then break end
      end
      return performed
    end
  end
  return false
end

function keymap.on_mouse_wheel(delta_y, delta_x, ...)
  local y_direction = delta_y > 0 and "up" or "down"
  local x_direction = delta_x > 0 and "left" or "right"
  -- Try sending a "cumulative" event for both scroll directions
  if delta_y ~= 0 and delta_x ~= 0 then
    local result = keymap.on_key_pressed("wheel" .. y_direction .. x_direction, delta_y, delta_x, ...)
    if not result then
      result = keymap.on_key_pressed("wheelyx", delta_y, delta_x, ...)
    end
    if result then return true end
  end
  -- Otherwise send each direction as its own separate event
  local y_result, x_result
  if delta_y ~= 0 then
    y_result = keymap.on_key_pressed("wheel" .. y_direction, delta_y, ...)
    if not y_result then
      y_result = keymap.on_key_pressed("wheel", delta_y, ...)
    end
  end
  if delta_x ~= 0 then
    x_result = keymap.on_key_pressed("wheel" .. x_direction, delta_x, ...)
    if not x_result then
      x_result = keymap.on_key_pressed("hwheel", delta_x, ...)
    end
  end
  return y_result or x_result
end

function keymap.on_mouse_pressed(button, x, y, clicks)
  stderr.debug("on_mouse_pressed %s %d %d %d", button, x, y, clicks)
  local click_number = (((clicks - 1) % ConfigurationOptionStore.get_max_clicks()) + 1)
  return not (keymap.on_key_pressed(click_number  .. button:sub(1,1) .. "click", x, y, clicks) or
    keymap.on_key_pressed(button:sub(1,1) .. "click", x, y, clicks) or
    keymap.on_key_pressed(click_number .. "click", x, y, clicks) or
    keymap.on_key_pressed("click", x, y, clicks))
end

function keymap.on_key_released(k)
  local mk = modkey_map[k]
  if mk then
    keymap.modkeys[mk] = false
  end
end


--------------------------------------------------------------------------------
-- Register default bindings
--------------------------------------------------------------------------------
if macos then
  local keymap_macos = require(".keymap-macos")
  keymap_macos(keymap)
  return keymap
else 
  local keymap_generic = require(".keymap-generic")
  keymap_generic(keymap)
  return keymap
end
