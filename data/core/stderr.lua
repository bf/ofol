local stderr = {}

-- print message to stderr
-- core.log() functions are not loaded at this point
-- so we need to make another function for this
function stderr.print(text) 
  io.stderr:write(text .. " \n")
end

function stderr.print_with_tag(tag, text)
  stderr.print(string.format("%-5s %s", tag, text))
end

function stderr.info(text)
  stderr.print_with_tag("INFO", text)
end

function stderr.debug(text)
  stderr.print_with_tag("DEBUG", text)
end

function stderr.warn(text)
  stderr.print_with_tag("WARN", text)
end

function stderr.error(text)
  stderr.print_with_tag("WARN", text)
end

return stderr