local common = {}

---Returns a list of paths that are relative to the input path.
---
---If a root directory is specified, the function returns paths
---that are relative to the root directory.
---@param text string The input path.
---@param root? string The root directory.
---@return string[]
function common.path_suggest(text, root)
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
  local is_absolute = common.is_absolute_path(text)
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
function common.dir_path_suggest(text)
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
function common.dir_list_suggest(text, dir_list)
  local path, name = text:match("^(.-)([^"..PATHSEP.."]*)$")
  local res = {}
  for _, dir_path in ipairs(dir_list) do
    if dir_path:lower():find(text:lower(), nil, true) == 1 then
      table.insert(res, dir_path)
    end
  end
  return res
end


---Matches a string against a list of patterns.
---
---If a match was found, its start and end index is returned.
---Otherwise, false is returned.
---@param text string
---@param pattern string|string[]
---@param ... any Other options for string.find().
---@return number|boolean start_index
---@return number|nil end_index
function common.match_pattern(text, pattern, ...)
  if type(pattern) == "string" then
    return text:find(pattern, ...)
  end
  for _, p in ipairs(pattern) do
    local s, e = common.match_pattern(text, p, ...)
    if s then return s, e end
  end
  return false
end


---Draws text onto the window.
---The function returns the X and Y coordinates of the bottom-right
---corner of the text.
---@param font renderer.font
---@param color renderer.color
---@param text string
---@param align string
---| '"left"'   # Align text to the left of the bounding box
---| '"right"'  # Align text to the right of the bounding box
---| '"center"' # Center text in the bounding box
---@param x number
---@param y number
---@param w number
---@param h number
---@return number x_advance
---@return number y_advance
function common.draw_text(font, color, text, align, x,y,w,h)
  local tw, th = font:get_width(text), font:get_height()
  if align == "center" then
    x = x + (w - tw) / 2
  elseif align == "right" then
    x = x + (w - tw)
  end
  y = math.round(y + (h - th) / 2)
  return renderer.draw_text(font, text, x, y, color), y + th
end



---Returns the last portion of a path.
---@param path string
---@return string
function common.basename(path)
  -- a path should never end by / or \ except if it is '/' (unix root) or
  -- 'X:\' (windows drive)
  return path:match("[^"..PATHSEP.."]+$") or path
end


---Returns the directory name of a path.
---If the path doesn't have a directory, this function may return nil.
---@param path string
---@return string|nil
function common.dirname(path)
  return path:match("(.+)["..PATHSEP.."][^"..PATHSEP.."]+$")
end


---Returns a path where the user's home directory is replaced by `"~"`.
---@param text string
---@return string
function common.home_encode(text)
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
function common.home_encode_list(paths)
  local t = {}
  for i = 1, #paths do
    t[i] = common.home_encode(paths[i])
  end
  return t
end


---Expands the `"~"` prefix in a path into the user's home directory.
---This function is not guaranteed to return an absolute path.
---@param text string
---@return string
function common.home_expand(text)
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


function common.split_on_slash(str) 
  return split_on_slash(str)
end

---Normalizes the drive letter in a Windows path to uppercase.
---This function expects an absolute path, e.g. a path from `system.absolute_path`.
---
---This function is needed because the path returned by `system.absolute_path`
---may contain drive letters in upper or lowercase.
---@param filename string|nil The input path.
---@return string|nil
function common.normalize_volume(filename)
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
function common.normalize_path(filename)
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


function common.strip_trailing_slash(filename)
  if filename:match("[^:]["..PATHSEP.."]$") then
    return filename:sub(1, -2)
  end
  return filename
end

function common.strip_leading_path(filename)
    return filename:sub(2)
end

---Checks whether a path is absolute or relative.
---@param path string
---@return boolean
function common.is_absolute_path(path)
  return path:sub(1, 1) == PATHSEP or path:match("^(%a):\\")
end


---Checks whether a path belongs to a parent directory.
---@param filename string The path to check.
---@param path string The parent path.
---@return boolean
function common.path_belongs_to(filename, path)
  return string.find(filename, path .. PATHSEP, 1, true) == 1
end


---Checks whether a path is relative to another path.
---@param ref_dir string The path to check against.
---@param dir string The input path.
---@return boolean
function common.relative_path(ref_dir, dir)
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
function common.mkdirp(path)
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
function common.rm(path, recursively)
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
        local deleted, error, ipath = common.rm(item_path, recursively)
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


return common
