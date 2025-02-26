
local EXIT_ON_ERROR = true
local HIDE_DEBUG_MESSAGES = false
local BENCHMARK = false

-- base path to show relative path of script file errors
local BASE_PATH = DATADIR

local stderr = {}

local function try_string_format_into_text(fmt, ...) 
  local num_format_string_arguments = select('#', ...)
  if num_format_string_arguments == 0 then
    -- when no further args given, then fmt is the actual text
    return fmt
  end

  -- check if format string has as many replacements as we have arguments
  local _, num_format_string_placeholders = fmt:gsub("%%","")

  -- if format string has as many placeholders as we have variables,
  -- then use string.format to create string
  if num_format_string_placeholders == num_format_string_arguments then
    -- try format text
    local success, formatted_text = pcall(string.format, fmt, ...)
    if success then
      -- if successful, use formatted text 
      return formatted_text
    end
  end

  -- try to combine arguments into string
  local text = "" .. fmt
  for _, item in pairs({...}) do
    text = text .. " " .. tostring(item)
  end

  return text
end

-- print message to stderr
-- stderr.info() functions are not loaded at this point
-- so we need to make another function for this
function stderr.print(fmt, ...) 
  local text = try_string_format_into_text(fmt, ...)

  if BENCHMARK then
    io.stderr:write(system.get_time() .. " " .. text .. " \n")
  else
    io.stderr:write(text .. " \n")
  end
end

local c27 = string.char(27)
local function ansi_color(text, color, bold) 
  if bold == true then
    bold = '1'
  else
    bold = '0'
  end

  return c27 .. '[' .. bold .. 'm' .. c27 .. '[' .. color .. 'm' .. text .. c27 .. '[0m'
 end


function stderr.print_with_tag(tag, fmt, ...)
  if tag == 'WARN' then
    tag = ansi_color(tag, '31', true)
  elseif tag == 'ERROR' then
    tag = ansi_color(tag, '91', true)
  elseif tag == 'INFO' then
    tag = ansi_color(tag, '0', true)
  elseif tag == 'DEBUG' then
    if HIDE_DEBUG_MESSAGES then
      return
    end
  end

  local text = try_string_format_into_text(fmt, ...)

  -- get info about calling function
  local depth = 1
  local info
  
  while true do
    info = debug.getinfo(depth, "Sln")

    -- abort if no info found
    if not info or info == nil then
      break
    end

    -- when error is forwarded via strict.lua (e.g. undefined variable)
    -- then we need to look 4 function calls deep to get proper failing function
    if not info.source:match("strict.lua$") 
      and not info.source:match("stderr.lua$") 
      -- and info.name ~= nil
      and info.name ~= "xpcall"
      and info.name ~= "pcall"
      and info.name ~= "try" then
      -- we have found proper trace, stop looping
      break
    end

    -- increase depth
    depth = depth + 1
  end

  -- print("fond info", info.source, info.name)
 
  -- get path of calling function
  local at
  if #BASE_PATH > 0 and #info.source > 2 and fsutils ~= nil then
     -- figure out relative path if possible
    local relative_path = fsutils.relative_path(BASE_PATH, string.sub(info.source, 2))
    at = string.format("%s:%d", relative_path, info.currentline)
  else 
     -- use absolute path as fallback
    at = info.source
  end

  -- from https://stackoverflow.com/a/64271511
  local text_with_func_details = string.format("[%s] %s(): %s", at, info.name, text)

  stderr.print(string.format("%-5s %s", tag, text_with_func_details))
end

function stderr.info(...)
  stderr.print_with_tag("INFO", ...)
end

function stderr.debug(...)
  if not HIDE_DEBUG_MESSAGES then
    stderr.print_with_tag("DEBUG", ...)
  end
end

function stderr.warn(...)
  stderr.print_with_tag("WARN", ...)
end

function stderr.backtrace() 
  io.stderr:write(debug.traceback("", 2))
  io.stderr:write("\n")
end

function stderr.debug_backtrace(...)
  if not HIDE_DEBUG_MESSAGES then
    stderr.debug(...)
    stderr.backtrace()
  end
end

function stderr.warn_backtrace(...)
  stderr.warn(...)
  stderr.backtrace()
end

function stderr.info_backtrace(...)
  stderr.info(...)
  stderr.backtrace()
end

function stderr.deprecated(...)
  stderr.error("DEPRECATED CODE", ...)
  -- stderr.warn("DEPRECATED CODE", ...)
  -- stderr.backtrace()
end

function stderr.deprecated_soon(...)
  stderr.warn("DEPRECATED SOON", ...)
  stderr.backtrace()
end

function stderr.error(...)
  stderr.print_with_tag("ERROR", ...)
  stderr.backtrace()
  
  if EXIT_ON_ERROR then
    stderr.print("will exit now because EXIT_ON_ERROR is set to true")
    os.exit(3)
  end
end

return stderr