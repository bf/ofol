local stderr = {}

local EXIT_ON_ERROR = true
local HIDE_DEBUG_MESSAGES = false
local BENCHMARK = false


local function try_string_format_into_text(fmt, ...) 
  local ARGS = {...}
  if #ARGS == 0 then
    -- when no further args given, then fmt is the actual text
    return fmt
  end

  -- try format text
  local success, formatted_text = pcall(string.format, fmt, ...)
  if success then
    -- if successful, use formatted text 
    return formatted_text
  end

  -- format string failed, show second error
  stderr.print("ERROR", string.format("Second error while trying to format error message: %s", formatted_text))

  -- combine strings
  return fmt .. " " .. table.concat(ARGS, " ")
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

  stderr.print(string.format("%-5s %s", tag, text))
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

function stderr.error(...)
  stderr.print_with_tag("ERROR", ...)
  io.stderr:write(debug.traceback("", 1))
  io.stderr:write("\n")

  if EXIT_ON_ERROR then
    stderr.print("will exit now because EXIT_ON_ERROR is set to true")
    os.exit(3)
  end
end

return stderr