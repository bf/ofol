-- add try/catch functionality
function try_catch(fn, ...)
  -- stderr.debug("trying function call")

  local err
  local ok, res = xpcall(fn, function(msg)
    local item = stderr.warn("try_catch failed: %s", msg)
    item.info = debug.traceback("", 2):gsub("\t", "")
    err = msg
  end, ...)
  
  if ok then
    return true, res
  end
  
  return false, err
end