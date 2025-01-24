local stderr = {}

-- print message to stderr
-- core.log() functions are not loaded at this point
-- so we need to make another function for this
function stderr.print(text) 
  io.stderr:write(text .. " \n")
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
  end

  stderr.print(string.format("%-5s %s", tag, text))
end

function stderr.info(text)
  stderr.print_with_tag("INFO", text)
end

function stderr.debug(text)
  stderr.print_with_tag("DEBUG", text)
end

function stderr.warn(text)
  stderr.print_with_tag('WARN', text)
end

function stderr.error(text)
  stderr.print_with_tag("WARN", text)
end

return stderr