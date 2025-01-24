local stderr = {}

local EXIT_ON_ERROR = true

local HIDE_DEBUG_MESSAGES = false

-- print message to stderr
-- core.log() functions are not loaded at this point
-- so we need to make another function for this
function stderr.print(text) 
  io.stderr:write(system.get_time() .. " " .. text .. " \n")
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

function stderr.print_with_tag(tag, text)
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

  stderr.print(string.format("%-5s %s", tag, text))
end

function stderr.info(text)
  stderr.print_with_tag("INFO", text)
end

function stderr.debug(text)
  if not HIDE_DEBUG_MESSAGES then
    stderr.print_with_tag("DEBUG", text)
  end
end

function stderr.warn(text)
  stderr.print_with_tag('WARN', text)
end

function stderr.error(text)
  stderr.print_with_tag("WARN", text)

  if EXIT_ON_ERROR then
    stderr.print("will exit now because EXIT_ON_ERROR is set to true")
    os.exit(3)
  end
end

return stderr