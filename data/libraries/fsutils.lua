local core = require "core"

local fsutils = {}
-- file system utilities

function fsutils.normalize_path(path)
  if PLATFORM == "Windows" then
    return path:gsub('\\', '/')
  else
    return path
  end
end

function fsutils.parent_directory(path)
  path = fsutils.normalize_path(path)
  path = path:match("^(.-)/*$")
  local last_slash_pos = -1
  for i = #path, 1, -1 do
    if path:sub(i, i) == '/' then
      last_slash_pos = i
      break
    end
  end
  if last_slash_pos < 0 then
    return nil
  end
  return path:sub(1, last_slash_pos - 1)
end


--- Checks whether a file or directory exists
-- @param string path Path of object to be checked
function fsutils.is_object_exist(path)
  local stat = system.get_file_info(path)
  if not stat or (stat.type ~= "file" and stat.type ~= "dir") then
    return false
  end
  return true
end

--- Checks whether an object is a directory
-- @param string path Path of object to be checked
function fsutils.is_dir(path)
  local file_info = system.get_file_info(path)
  if (file_info ~= nil) then
    return file_info.type == "dir"
  end

  return false
end

--- Moves object (file or directory) to another path
-- @param string old_abs_filename Absolute old filename
-- @param string new_abs_filename Absolute new filename
function fsutils.move_object(old_abs_filename, new_abs_filename)
  local res, err = os.rename(old_abs_filename, new_abs_filename)
  if res then -- successfully renamed
    stderr.info("[treeview-extender] Moved \"%s\" to \"%s\"", old_abs_filename, new_abs_filename)
  else
    stderr.error("[treeview-extender] Error while moving \"%s\" to \"%s\": %s", old_abs_filename, new_abs_filename, err)
  end
end

--- Copy source file to destination path
-- @param string source_abs_filename Absolute source filename
-- @param string dest_abs_filename Absolute destination filename
function fsutils.copy_file(source_abs_filename, dest_abs_filename)
  local source_file = io.open(source_abs_filename, "rb")
  local dest_file = io.open(dest_abs_filename, "wb")

  if source_file ~= nil and dest_file ~= nil then

    local chunk_size = 2^13 -- 8KB
    while true do
      local chunk = source_file:read(chunk_size)
      if not chunk then break end
      dest_file:write(chunk)
    end

    source_file:close()
    dest_file:close()

  end
end

return fsutils
