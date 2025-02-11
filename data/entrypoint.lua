-- 
-- 
-- MAIN ENTRYPOINT !
-- THIS LUA FILE LOADS ALL OTHER LUA FILES
--
--

local CONSTANT_FRAMES_PER_SECOND = 60

-- this file is used by lite-xl to setup the Lua environment when starting
VERSION = "@PROJECT_VERSION@"
PROJECT_NAME="ofol"

SCALE = tonumber(os.getenv("LITE_SCALE") or os.getenv("GDK_SCALE") or os.getenv("QT_SCALE_FACTOR")) or 1
PATHSEP = package.config:sub(1, 1)

EXEDIR = EXEFILE:match("^(.+)[/\\][^/\\]+$")
if MACOS_RESOURCES then
  DATADIR = MACOS_RESOURCES
else
  local prefix = os.getenv('LITE_PREFIX') or EXEDIR:match("^(.+)[/\\]bin$")
  DATADIR = prefix and (prefix .. PATHSEP .. 'share' .. PATHSEP .. PROJECT_NAME) or (EXEDIR .. PATHSEP .. 'data')
end
USERDIR = (system.get_file_info(EXEDIR .. PATHSEP .. 'user') and (EXEDIR .. PATHSEP .. 'user'))
       or os.getenv("LITE_USERDIR")
       or ((os.getenv("XDG_CONFIG_HOME") and os.getenv("XDG_CONFIG_HOME") .. PATHSEP .. PROJECT_NAME))
       or (HOME and (HOME .. PATHSEP .. '.config' .. PATHSEP .. PROJECT_NAME))




package.path = DATADIR .. '/?.lua;'
package.path = DATADIR .. '/?/init.lua;' .. package.path
-- TODO: check if this is needed
-- package.path = USERDIR .. '/?.lua;' .. package.path
-- package.path = USERDIR .. '/?/init.lua;' .. package.path

-- do not load random .so files from many places
-- local suffix = PLATFORM == "Windows" and 'dll' or 'so'
-- package.cpath =
-- USERDIR .. '/?.' .. ARCH .. "." .. suffix .. ";" ..
-- USERDIR .. '/?/init.' .. ARCH .. "." .. suffix .. ";" ..
-- USERDIR .. '/?.' .. suffix .. ";" ..
-- USERDIR .. '/?/init.' .. suffix .. ";" ..
--   DATADIR .. '/?.' .. ARCH .. "." .. suffix .. ";" ..
--   DATADIR .. '/?/init.' .. ARCH .. "." .. suffix .. ";" ..
--   DATADIR .. '/?.' .. suffix .. ";" ..
--   DATADIR .. '/?/init.' .. suffix .. ";"

package.native_plugins = {}

-- do not load .so files from lua lib dir
-- local function search_for_module_in_these_directories(modname)
--   local path, err = package.searchpath(modname, package.cpath)
--   if not path then return err end
--   return system.load_native_plugin, path
-- end

-- limit package searcher to local diretories
package.searchers = { 
  package.searchers[1], 
  package.searchers[2], 

  -- do not load .so files from lua lib dir
  -- search_for_module_in_these_directories
}

table.pack = table.pack or pack or function(...) return {...} end
table.unpack = table.unpack or unpack

-- global include of stderr logging
stderr = require("lib.stderr")

local lua_require = require
local require_stack = { "" }
---Loads the given module, returns any value returned by the searcher (`true` when `nil`).
---Besides that value, also returns as a second result the loader data returned by the searcher,
---which indicates how `require` found the module.
---(For instance, if the module came from a file, this loader data is the file path.)
---
---This is a variant that also supports relative imports.
---
---For example `require ".b"` will require `b` in the same path of the current
---file.
---This also supports multiple levels traversal. For example `require "...b"`
---will require `b` from two levels above the current one.
---This method has a few caveats: it uses the last `require` call to get the
---current "path", so this only works if the relative `require` is called inside
---its parent `require`.
---Calling a relative `require` in a function called outside the parent
---`require`, will result in the wrong "path" being used.
---
---It's possible to save the current "path" with `get_current_require_path`
---called inside the parent `require`, and use its return value to populate
---future requires.
---@see get_current_require_path
---@param modname string
---@return unknown
---@return unknown loaderdata
function require(modname, ...)
  if modname then
    local level, rel_path = string.match(modname, "^(%.*)(.*)")
    level = #(level or "")
    
    if level > 0 then
      if #require_stack == 0 then
        return stderr.error("Require stack underflowed.")
      else
        local base_path = require_stack[#require_stack]
        -- stderr.info(string.format("[start.lua] require(%d): %s\tbase_path before: %s", level, modname, base_path))
        while level > 1 do
          base_path = string.match(base_path, "^(.*)%.") or ""
          level = level - 1
        end
        -- stderr.info(string.format("[start.lua] require(%d): %s\tbase_path after: %s", level, modname, base_path))
        modname = base_path
        if #base_path > 0 then
          modname = modname .. "."
        end
        modname = modname .. rel_path
      end
    else
      -- stderr.info(string.format("[start.lua] require(%d): %s\trel_path: %s", level, modname, rel_path))
    end
  else
    stderr.error("[start.lua] require called without modname?")
  end

  -- increase require stack
  table.insert(require_stack, modname)

  -- try to load required module
  local ok, result, loaderdata = pcall(lua_require, modname, ...)

  -- decrease require stack
  table.remove(require_stack)

  -- handle module loading error
  if not ok then
    stderr.error(string.format("[start.lua] require(%s): %s", modname, result))
    return error(result)
  end

  return result, loaderdata
end



---Returns the current `require` path.
---@see require for details and caveats
---@return string
function get_current_require_path()
  return require_stack[#require_stack]
end


-- from core/bit.lua
local bit = {}

local LUA_NBITS = 32
local ALLONES = (~(((~0) << (LUA_NBITS - 1)) << 1))

local function trim(x)
  return (x & ALLONES)
end

local function mask(n)
  return (~((ALLONES << 1) << ((n) - 1)))
end

local function check_args(field, width)
  assert(field >= 0, "field cannot be negative")
  assert(width > 0, "width must be positive")
  assert(field + width < LUA_NBITS and field + width >= 0,
         "trying to access non-existent bits")
end

function bit.extract(n, field, width)
  local w = width or 1
  check_args(field, w)
  local m = trim(n)
  return m >> field & mask(w)
end

function bit.replace(n, v, field, width)
  local w = width or 1
  check_args(field, w)
  local m = trim(n)
  local x = v & mask(width);
  return m & ~(mask(w) << field) | (x << field)
end

bit32 = bit32 or bit


-- from core/utf8string.lua
--------------------------------------------------------------------------------
-- inject utf8 functions to strings
--------------------------------------------------------------------------------

local utf8 = require "utf8extra"

string.ubyte = utf8.byte
string.uchar = utf8.char
string.ufind = utf8.find
string.ugmatch = utf8.gmatch
string.ugsub = utf8.gsub
string.ulen = utf8.len
string.ulower = utf8.lower
string.umatch = utf8.match
string.ureverse = utf8.reverse
string.usub = utf8.sub
string.uupper = utf8.upper

string.uescape = utf8.escape
string.ucharpos = utf8.charpos
string.unext = utf8.next
string.uinsert = utf8.insert
string.uremove = utf8.remove
string.uwidth = utf8.widthp
string.uwidthindex = utf8.widthindex
string.utitle = utf8.title
string.ufold = utf8.fold
string.uncasecmp = utf8.ncasecmp

string.uoffset = utf8.offset
string.ucodepoint = utf8.codepoint
string.ucodes = utf8.codes


-- from core/process.lua

---An abstraction over the standard input and outputs of a process
---that allows you to read and write data easily.
---@class process.stream
---@field private fd process.streamtype
---@field private process process
---@field private buf string[]
---@field private len number
process.stream = {}
process.stream.__index = process.stream

---Creates a stream from a process.
---@param proc process The process to wrap.
---@param fd process.streamtype The standard stream of the process to wrap.
function process.stream.new(proc, fd)
  return setmetatable({ fd = fd, process = proc, buf = {}, len = 0 }, process.stream)
end

---@alias process.stream.readtype
---| `"line"` # Reads a single line
---| `"all"`  # Reads the entire stream
---| `"L"`    # Reads a single line, keeping the trailing newline character.

---Options that can be passed to stream.read().
---@class process.stream.readoption
---@field public timeout number The number of seconds to wait before the function throws an error. Reads do not time out by default.
---@field public scan number The number of seconds to yield in a coroutine. Defaults to `1/CONSTANT_FRAMES_PER_SECOND`.

---Reads data from the stream.
---
---When called inside a coroutine such as `core.add_thread()`,
---the function yields to the main thread occassionally to avoid blocking the editor. <br>
---If the function is not called inside the coroutine, the function returns immediately
---without waiting for more data.
---@param bytes process.stream.readtype|integer The format or number of bytes to read.
---@param options? process.stream.readoption Options for reading from the stream.
---@return string|nil data The string read from the stream, or nil if no data could be read.
function process.stream:read(bytes, options)
  if type(bytes) == 'string' then bytes = bytes:gsub("^%*", "") end
  options = options or {}
  local start = system.get_time()
  local target = 0
  if bytes == "line" or bytes == "l" or bytes == "L" then
    if #self.buf > 0 then
      for i,v in ipairs(self.buf) do
        local s = v:find("\n")
        if s then
          target = target + s
          break
        elseif i < #self.buf then
          target = target + #v
        else
          target = 1024*1024*1024*1024
        end
      end
    else
      target = 1024*1024*1024*1024
    end
  elseif bytes == "all" or bytes == "a" then
    target = 1024*1024*1024*1024
  elseif type(bytes) == "number" then
    target = bytes
  else
    error("'" .. bytes .. "' is an unsupported read option for this stream")
  end

  while self.len < target do
    local chunk = self.process.process:read(self.fd, math.max(target - self.len, 0))
    if not chunk then break end
    if #chunk > 0 then
      table.insert(self.buf, chunk)
      self.len = self.len + #chunk
      if bytes == "line" or bytes == "l" or bytes == "L" then
        local s = chunk:find("\n")
        if s then target = self.len - #chunk + s end
      end
    elseif coroutine.running() then
      if options.timeout and system.get_time() - start > options.timeout then
        error("timeout expired")
      end
      coroutine.yield(options.scan or (1 / CONSTANT_FRAMES_PER_SECOND))
    else
      break
    end
  end
  if #self.buf == 0 then return nil end
  local str = table.concat(self.buf)
  self.len = math.max(self.len - target, 0)
  self.buf = self.len > 0 and { str:sub(target + 1) } or {}
  return str:sub(1, target + ((bytes == "line" or bytes == "l") and str:byte(target) == 10 and -1 or 0))
end


---Options that can be passed into stream.write().
---@class process.stream.writeoption
---@field public scan number The number of seconds to yield in a coroutine. Defaults to `1/CONSTANT_FRAMES_PER_SECOND`.

---Writes data into the stream.
---
---When called inside a coroutine such as `core.add_thread()`,
---the function yields to the main thread occassionally to avoid blocking the editor. <br>
---If the function is not called inside the coroutine,
---the function writes as much data as possible before returning.
---@param bytes string The bytes to write into the stream.
---@param options? process.stream.writeoption Options for writing to the stream.
---@return integer num_bytes The number of bytes written to the stream.
function process.stream:write(bytes, options)
  options = options or {}
  local buf = bytes
  while #buf > 0 do
    local len = self.process.process:write(buf)
    if not len then break end
    if not coroutine.running() then return len end
    buf = buf:sub(len + 1)
    coroutine.yield(options.scan or (1 / CONSTANT_FRAMES_PER_SECOND))
  end
  return #bytes - #buf
end


---Closes the stream and its underlying resources.
function process.stream:close()
  return self.process.process:close_stream(self.fd)
end


---Waits for the process to exit.
---When called inside a coroutine such as `core.add_thread()`,
---the function yields to the main thread occassionally to avoid blocking the editor. <br>
---Otherwise, the function blocks the editor until the process exited or the timeout has expired.
---@param timeout? number The amount of seconds to wait. If omitted, the function will wait indefinitely.
---@param scan? number The amount of seconds to yield while scanning. If omittted, the scan rate will be the FPS.
---@return integer|nil exit_code The exit code for this process, or nil if the wait timed out.
function process:wait(timeout, scan)
  if not coroutine.running() then return self.process:wait(timeout) end
  local start = system.get_time()
  while self.process:running() and (system.get_time() - start > (timeout or math.huge)) do
    coroutine.yield(scan or (1 / CONSTANT_FRAMES_PER_SECOND))
  end
  return self.process:returncode()
end


function process:__index(k)
  if process[k] then return process[k] end
  if type(self.process[k]) == 'function' then return function(newself, ...) return self.process[k](self.process, ...) end end
  return self.process[k]
end

local function env_key(str)
  if PLATFORM == "Windows" then return str:upper() else return str end
end

---Sorts the environment variable by its key, converted to uppercase.
---This is only needed on Windows.
local function compare_env(a, b)
  return env_key(a:match("([^=]*)=")) < env_key(b:match("([^=]*)="))
end

local old_start = process.start
function process.start(command, options)
  assert(type(command) == "table" or type(command) == "string", "invalid argument #1 to process.start(), expected string or table, got "..type(command))
  assert(type(options) == "table" or type(options) == "nil", "invalid argument #2 to process.start(), expected table or nil, got "..type(options))
  if PLATFORM == "Windows" then
    if type(command) == "table" then
      -- escape the arguments into a command line string
      -- https://github.com/python/cpython/blob/48f9d3e3faec5faaa4f7c9849fecd27eae4da213/Lib/subprocess.py#L531
      local arglist = {}
      for _, v in ipairs(command) do
        local backslash, arg = 0, {}
        for c in v:gmatch(".") do
          if     c == "\\" then backslash = backslash + 1
          elseif c == '"'  then arg[#arg+1] = string.rep("\\", backslash * 2 + 1)..'"'; backslash = 0
          else                  arg[#arg+1] = string.rep("\\", backslash) .. c;         backslash = 0 end
        end
        arg[#arg+1] = string.rep("\\", backslash) -- add remaining backslashes
        if #v == 0 or v:find("[\t\v\r\n ]") then arglist[#arglist+1] = '"'..table.concat(arg, "")..'"'
        else                                     arglist[#arglist+1] = table.concat(arg, "") end
      end
      command = table.concat(arglist, " ")
    end
  else
    command = type(command) == "table" and command or { command }
  end
  if type(options) == "table" and options.env then
    local user_env = options.env --[[@as table]]
    options.env = function(system_env)
      local final_env, envlist = {}, {}
      for k, v in pairs(system_env) do final_env[env_key(k)] = k.."="..v end
      for k, v in pairs(user_env)   do final_env[env_key(k)] = k.."="..v end
      for _, v in pairs(final_env)  do envlist[#envlist+1] = v end
      if PLATFORM == "Windows" then table.sort(envlist, compare_env) end
      return table.concat(envlist, "\0").."\0\0"
    end
  end
  local self = setmetatable({ process = old_start(command, options) }, process)
  self.stdout = process.stream.new(self, process.STREAM_STDOUT)
  self.stderr = process.stream.new(self, process.STREAM_STDERR)
  self.stdin  = process.stream.new(self, process.STREAM_STDIN)
  return self
end



-- Because AppImages change the working directory before running the executable,
-- we need to change it back to the original one.
-- https://github.com/AppImage/AppImageKit/issues/172
-- https://github.com/AppImage/AppImageKit/pull/191
local appimage_owd = os.getenv("OWD")
if os.getenv("APPIMAGE") and appimage_owd then
  system.chdir(appimage_owd)
end
