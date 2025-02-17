
local fsutils = {}
-- file system utilities

function fsutils.normalize_path(path)
  if PLATFORM == "Windows" then
    return path:gsub('\\', '/')
  else
    return path
  end
end

-- FIXME: does not work for windows
function fsutils.parent_directory(path)
  if PLATFORM == "Windows" then
    error("this function is not adapted for windows yet")
  end

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


--- from old fsutils.lua
---Returns a list of paths that are relative to the input path.
---
---If a root directory is specified, the function returns paths
---that are relative to the root directory.
---@param text string The input path.
---@param root? string The root directory.
---@return string[]
function fsutils.path_suggest(text, root)
  if root and root:sub(-1) ~= PATHSEP then
    root = root .. PATHSEP
  end

  local pathsep = PATHSEP
  if PLATFORM == "Windows" then
    pathsep = "\\/"
  end
  local path = text:match("^(.-)[^"..pathsep.."]*$")
  local clean_dotslash = false
  -- ignore root if path is absolute
  local is_absolute = fsutils.is_absolute_path(text)
  if not is_absolute then
    if path == "" then
      path = root or "."
      clean_dotslash = not root
    else
      path = (root or "") .. path
    end
  end

  -- Only in Windows allow using both styles of PATHSEP
  if (PATHSEP == "\\" and not string.match(path:sub(-1), "[\\/]")) or
     (PATHSEP ~= "\\" and path:sub(-1) ~= PATHSEP) then
    path = path .. PATHSEP
  end
  local files = system.list_dir(path) or {}
  local res = {}
  for _, file in ipairs(files) do
    file = path .. file
    local info = system.get_file_info(file)
    if info then
      if info.type == "dir" then
        file = file .. PATHSEP
      end
      if root then
        -- remove root part from file path
        local s, e = file:find(root, nil, true)
        if s == 1 then
          file = file:sub(e + 1)
        end
      elseif clean_dotslash then
        -- remove added dot slash
        local s, e = file:find("." .. PATHSEP, nil, true)
        if s == 1 then
          file = file:sub(e + 1)
        end
      end
      if file:lower():find(text:lower(), nil, true) == 1 then
        table.insert(res, file)
      end
    end
  end
  return res
end


---Returns a list of directories that are related to a path.
---@param text string The input path.
---@return string[]
function fsutils.dir_path_suggest(text)
  local path, name = text:match("^(.-)([^"..PATHSEP.."]*)$")
  local files = system.list_dir(path == "" and "." or path) or {}
  local res = {}
  for _, file in ipairs(files) do
    file = path .. file
    local info = system.get_file_info(file)
    if info and info.type == "dir" and file:lower():find(text:lower(), nil, true) == 1 then
      table.insert(res, file)
    end
  end
  return res
end


---Filters a list of paths to find those that are related to the input path.
---@param text string The input path.
---@param dir_list string[] A list of paths to filter.
---@return string[]
function fsutils.dir_list_suggest(text, dir_list)
  local path, name = text:match("^(.-)([^"..PATHSEP.."]*)$")
  local res = {}
  for _, dir_path in ipairs(dir_list) do
    if dir_path:lower():find(text:lower(), nil, true) == 1 then
      table.insert(res, dir_path)
    end
  end
  return res
end




---Returns the last portion of a path.
---@param path string
---@return string
function fsutils.basename(path)
  -- a path should never end by / or \ except if it is '/' (unix root) or
  -- 'X:\' (windows drive)
  return path:match("[^"..PATHSEP.."]+$") or path
end


---Returns the directory name of a path.
---If the path doesn't have a directory, this function may return nil.
---@param path string
---@return string|nil
function fsutils.dirname(path)
  return path:match("(.+)["..PATHSEP.."][^"..PATHSEP.."]+$")
end


---Returns a path where the user's home directory is replaced by `"~"`.
---@param text string
---@return string
function fsutils.home_encode(text)
  if HOME and string.find(text, HOME, 1, true) == 1 then
    local dir_pos = #HOME + 1
    -- ensure we don't replace if the text is just "$HOME" or "$HOME/" so
    -- it must have a "/" following the $HOME and some characters following.
    if string.find(text, PATHSEP, dir_pos, true) == dir_pos and #text > dir_pos then
      return "~" .. text:sub(dir_pos)
    end
  end
  return text
end


---Returns a list of paths where the user's home directory is replaced by `"~"`.
---@param paths string[] A list of paths to encode
---@return string[]
function fsutils.home_encode_list(paths)
  local t = {}
  for i = 1, #paths do
    t[i] = fsutils.home_encode(paths[i])
  end
  return t
end


---Expands the `"~"` prefix in a path into the user's home directory.
---This function is not guaranteed to return an absolute path.
---@param text string
---@return string
function fsutils.home_expand(text)
  return HOME and text:gsub("^~", HOME) or text
end


-- fixme: sep_pattern is defined but not used
local function split_on_slash(s, sep_pattern)
  local t = {}
  if s:match("^["..PATHSEP.."]") then
    t[#t + 1] = ""
  end
  for fragment in string.gmatch(s, "([^"..PATHSEP.."]+)") do
    t[#t + 1] = fragment
  end
  return t
end


function fsutils.split_on_slash(str) 
  return split_on_slash(str)
end

---Normalizes the drive letter in a Windows path to uppercase.
---This function expects an absolute path, e.g. a path from `system.absolute_path`.
---
---This function is needed because the path returned by `system.absolute_path`
---may contain drive letters in upper or lowercase.
---@param filename string|nil The input path.
---@return string|nil
function fsutils.normalize_volume(filename)
  if not filename then return end
  if PATHSEP == '\\' then
    local drive, rem = filename:match('^([a-zA-Z]:\\)(.-)'..PATHSEP..'?$')
    if drive then
      return drive:upper() .. rem
    end
  end
  return filename
end


---Normalizes a path into the same format across platforms.
---
---On Windows, all drive letters are converted to uppercase.
---UNC paths with drive letters are converted back to ordinary Windows paths.
---All path separators (`"/"`, `"\\"`) are converted to platform-specific ones.
---@param filename string|nil
---@return string|nil
function fsutils.normalize_path(filename)
  if not filename then return end
  local volume
  if PATHSEP == '\\' then
    filename = filename:gsub('[/\\]', '\\')
    local drive, rem = filename:match('^([a-zA-Z]:\\)(.*)')
    if drive then
      volume, filename = drive:upper(), rem
    else
      drive, rem = filename:match('^(\\\\[^\\]+\\[^\\]+\\)(.*)')
      if drive then
        volume, filename = drive, rem
      end
    end
  else
    local relpath = filename:match('^/(.+)')
    if relpath then
      volume, filename = "/", relpath
    end
  end
  local parts = split_on_slash(filename, PATHSEP)
  local accu = {}
  for _, part in ipairs(parts) do
    if part == '..' then
      if #accu > 0 and accu[#accu] ~= ".." then
        table.remove(accu)
      elseif volume then
        error("invalid path " .. volume .. filename)
      else
        table.insert(accu, part)
      end
    elseif part ~= '.' then
      table.insert(accu, part)
    end
  end
  local npath = table.concat(accu, PATHSEP)
  return (volume or "") .. (npath == "" and PATHSEP or npath)
end


function fsutils.strip_trailing_slash(filename)
  if filename:match("[^:]["..PATHSEP.."]$") then
    return filename:sub(1, -2)
  end
  return filename
end

function fsutils.strip_leading_path(filename)
    return filename:sub(2)
end

---Checks whether a path is absolute or relative.
---@param path string
---@return boolean
function fsutils.is_absolute_path(path)
  return path:sub(1, 1) == PATHSEP or path:match("^(%a):\\")
end


---Checks whether a path belongs to a parent directory.
---@param filename string The path to check.
---@param path string The parent path.
---@return boolean
function fsutils.path_belongs_to(filename, path)
  return string.find(filename, path .. PATHSEP, 1, true) == 1
end


---Checks whether a path is relative to another path.
---@param ref_dir string The path to check against.
---@param dir string The input path.
---@return boolean
function fsutils.relative_path(ref_dir, dir)
  local drive_pattern = "^(%a):\\"
  local drive, ref_drive = dir:match(drive_pattern), ref_dir:match(drive_pattern)
  if drive and ref_drive and drive ~= ref_drive then
    -- Windows, different drives, system.absolute_path fails for C:\..\D:\
    return dir
  end
  local ref_ls = split_on_slash(ref_dir)
  local dir_ls = split_on_slash(dir)
  local i = 1
  while i <= #ref_ls do
    if dir_ls[i] ~= ref_ls[i] then
      break
    end
    i = i + 1
  end
  local ups = ""
  for k = i, #ref_ls do
    ups = ups .. ".." .. PATHSEP
  end
  local rel_path = ups .. table.concat(dir_ls, PATHSEP, i)
  return rel_path ~= "" and rel_path or "."
end


---Creates a directory recursively if necessary.
---@param path string
---@return boolean success
---@return string|nil error
---@return string|nil path The path where an error occured.
function fsutils.mkdirp(path)
  local stat = system.get_file_info(path)
  if stat and stat.type then
    return false, "path exists", path
  end
  local subdirs = {}
  while path and path ~= "" do
    local success_mkdir = system.mkdir(path)
    if success_mkdir then break end
    local updir, basedir = path:match("(.*)["..PATHSEP.."](.+)$")
    table.insert(subdirs, 1, basedir or path)
    path = updir
  end
  for _, dirname in ipairs(subdirs) do
    path = path and path .. PATHSEP .. dirname or dirname
    if not system.mkdir(path) then
      return false, "cannot create directory", path
    end
  end
  return true
end


---Removes a path.
---@param path string
---@param recursively boolean If true, the function will attempt to remove everything in the specified path.
---@return boolean success
---@return string|nil error
---@return string|nil path The path where the error occured.
function fsutils.rm(path, recursively)
  local stat = system.get_file_info(path)
  if not stat or (stat.type ~= "file" and stat.type ~= "dir") then
    return false, "invalid path given", path
  end

  if stat.type == "file" then
    local removed, error = os.remove(path)
    if not removed then
      return false, error, path
    end
  else
    local contents = system.list_dir(path)
    if #contents > 0 and not recursively then
      return false, "directory is not empty", path
    end

    for _, item in pairs(contents) do
      local item_path = path .. PATHSEP .. item
      local item_stat = system.get_file_info(item_path)

      if not item_stat then
        return false, "invalid file encountered", item_path
      end

      if item_stat.type == "dir" then
        local deleted, error, ipath = fsutils.rm(item_path, recursively)
        if not deleted then
          return false, error, ipath
        end
      elseif item_stat.type == "file" then
        local removed, error = os.remove(item_path)
        if not removed then
          return false, error, item_path
        end
      end
    end

    local removed, error = system.rmdir(path)
    if not removed then
      return false, error, path
    end
  end

  return true
end



return fsutils
