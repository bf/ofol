-- stores metadata for each file by absolute path
-- metadata used for file titles

local common = require "core.common"

local OpenFilesStore = {}

-- metadata storage object
local _store_metadata_by_file_absolute_path = {}

-- store counter for duplicate file basenames
local _store_number_of_files_with_same_file_basename = {}

-- store counter for duplicate absolute paths
local _store_number_of_files_with_same_absolute_path = {}

-- increase counter of open files with same basename
local function _counter_number_of_open_files_with_same_basename_increase(basename, absolute_path)
  -- initialize empty table if not set
  if not _store_number_of_files_with_same_file_basename[basename] then
    _store_number_of_files_with_same_file_basename[basename] = {}
  end

  -- insert absolute path to table
  _store_number_of_files_with_same_file_basename[basename][absolute_path] = true

  -- return new counter value
  return #_store_number_of_files_with_same_file_basename[basename]
end

-- decrease counter of open files with same basename
local function _counter_number_of_open_files_with_same_basename_decrease(basename, absolute_path)
  assert(_store_number_of_files_with_same_file_basename[basename][absolute_path], "absolute path should be stored in table")
    
  -- unset table object
  _store_number_of_files_with_same_file_basename[basename][absolute_path] = nil

  -- return new counter value
  return #_store_number_of_files_with_same_file_basename[basename]
end

-- increase counter of open files with same absolute path
local function _counter_number_of_open_files_with_same_absolute_path_increase(absolute_path)
  if _store_number_of_files_with_same_absolute_path[absolute_path] then
    _store_number_of_files_with_same_absolute_path[absolute_path] = _store_number_of_files_with_same_absolute_path[absolute_path] + 1
  else
    _store_number_of_files_with_same_absolute_path[absolute_path] = 1
  end

  -- return new counter value
  return _store_number_of_files_with_same_absolute_path[absolute_path]
end

-- decrease counter of open files with same absolute_path
local function _counter_number_of_open_files_with_same_absolute_path_decrease(absolute_path)
  assert(_store_number_of_files_with_same_absolute_path[absolute_path] > 0, "at least one file should be open when decreasing counter for open files with same absolute_path")
  _store_number_of_files_with_same_absolute_path[absolute_path] = _store_number_of_files_with_same_absolute_path[absolute_path] - 1

  -- return new counter value
  return _store_number_of_files_with_same_absolute_path[absolute_path]
end

-- react to new file opened in editor
-- receivecs doc object
function OpenFilesStore.handle_open_file(doc)
  -- get absolute path from doc
  local absolute_path = doc.abs_filename

  stderr.debug("handle open file %s", absolute_path)

  if absolute_path == nil then
    stderr.debug("absolute_path is nil, abort")
    return
  end

  -- increase counter for opened files with this absolute path
  _counter_number_of_open_files_with_same_absolute_path_increase(absolute_path)

  -- get file basename from absolute path
  local basename = common.basename(absolute_path)

  -- increase counter of duplicate file basenames
  _counter_number_of_open_files_with_same_basename_increase(basename, absolute_path)

  -- update store of metadata
  _store_metadata_by_file_absolute_path[absolute_path] = {
    basename = basename,
    doc = doc
  }
end

-- react to closing of file
function OpenFilesStore.handle_close_file(absolute_path)
  stderr.debug("handle close file %s", absolute_path)

  -- unsaved files dont have absolute path
  if absolute_path == nil then
    stderr.debug("absolute_path is nil, will abort")
    return 
  end

  assert(_store_metadata_by_file_absolute_path[absolute_path], "file metadata should exist when closing file")

  -- decrease counter for files open
  local num_total_times_still_open = _counter_number_of_open_files_with_same_absolute_path_decrease(absolute_path)

  -- if we have closed the last instance of this file do some cleanup
  if num_total_times_still_open == 0 then
    -- get metadata
    local metadata = _store_metadata_by_file_absolute_path[absolute_path]

    -- decrease counter of duplicate file basenames
    _counter_number_of_open_files_with_same_basename_decrease(metadata["basename"], absolute_path) 

    -- delete metadata object
    _store_metadata_by_file_absolute_path[absolute_path] = nil
  end
end

-- function OpenFilesStore.get_basename(absolute_path) 
--   if absolute_path == nil then
--     return nil
--   end
  
--   -- if _store_metadata_by_file_absolute_path[absolute_path] == nil then
--   --   return nil
--   -- end

--   return _store_metadata_by_file_absolute_path[absolute_path]["basename"]
-- end

-- returns differentiator suffix for when files with same basename are opened at the same time
function OpenFilesStore.get_filename_differentiator(absolute_path) 
  -- stderr.debug("absolute_path %s", absolute_path)

  if absolute_path == nil then
    return nil
  end

  -- load metadata
  local metadata = _store_metadata_by_file_absolute_path[absolute_path]

  if metadata == nil then
    return nil
  end

  -- get basename
  local basename = metadata["basename"]

  -- file is opened more then once, so we should use the directory name next to the filenames
  local counter = 0
  for _, _ in pairs(_store_number_of_files_with_same_file_basename[basename]) do
    if counter > 1 then
      -- early exit
      break
    end
    counter = counter + 1
  end

  -- not needed if less than two files with same basename are open
  if (counter <= 1) then
    return nil
  end

  -- for each file with this common basename, we create an array with parts of the path 
  local tmp_arr_path_parts = {}

  -- stores boolean if file needs differentiator
  local needs_unique_differentiator = {}

  -- stores unique differentiator by file
  local unique_differentiators = {}

  -- loop over each file
  for absolute_path_for_basename, _ in pairs(_store_number_of_files_with_same_file_basename[basename]) do
    -- split up into directories
    local tmp_path_parts = common.split_on_slash(absolute_path_for_basename)

    -- get rid of last item, because last item is the file basename 
    table.remove(tmp_path_parts)

    -- store all dirnames as reversed string so we can figure out common prefix
    tmp_arr_path_parts[absolute_path_for_basename] = tmp_path_parts

    -- also, prepare object with absolute path to store when we found proper differentiator
    needs_unique_differentiator[absolute_path_for_basename] = true
    unique_differentiators[absolute_path_for_basename] = ""
  end

  -- now that we have this array of arrays, we need to figure out where the file paths start to differ
  local counter = 0

  while true do
    -- mark differentiators that have been used
    local tmp_seen_differentiators = {}

    local is_finished = true

    -- iterate over file paths for each individual file with same basename
    for absolute_path_for_basename, path_parts in pairs(tmp_arr_path_parts) do
      -- only look for differentiator when none has been found yet
      if needs_unique_differentiator[absolute_path_for_basename] then
        -- get last part of path based on counter
        local last_dir_part = path_parts[#path_parts - counter]

        -- construct differentiator 
        local differentiator_candidate = last_dir_part .. " " .. unique_differentiators[absolute_path_for_basename]

        -- check if this differentiator has already been seen
        if tmp_seen_differentiators[differentiator_candidate] then
          -- if it has been seen already, it is useless, so mark everyone who uses it as such
          for looped_absolute_path, looped_differentiator_candidate in pairs(unique_differentiators) do
            -- delete entries with same differentiator as the rejected candidate
            if looped_differentiator_candidate == differentiator_candidate then
              unique_differentiators[looped_absolute_path] = nil
              needs_unique_differentiator[looped_absolute_path] = true
            end
          end

          -- we cannot finish like this
          is_finished = false
        else
          -- if differentiator has not been seen, use it for this file
          unique_differentiators[absolute_path_for_basename] = differentiator_candidate
          needs_unique_differentiator[absolute_path_for_basename] =false
          -- mark differentiator as seen
          tmp_seen_differentiators[differentiator_candidate] = true
        end
      end
    end

    -- if no duplicate differentiators were found, we can stop
    if is_finished then 
      break
    end

    -- otherwise increase counter and loop
    counter = counter + 1
  end

  -- get relative path base on the prefix
 return unique_differentiators[absolute_path]
end

-- return true if file has no unsaved changes
function OpenFilesStore.get_file_has_unsaved_changes(absolute_path) 
  if absolute_path == nil then 
    return false 
  end

  if _store_metadata_by_file_absolute_path[absolute_path] == nil then
    return false
  end

  if _store_metadata_by_file_absolute_path[absolute_path]["doc"] == nil then
    return false
  end

  -- is_dirty == true when doc has unsaved changes
  return _store_metadata_by_file_absolute_path[absolute_path]["doc"]:is_dirty()
end

return OpenFilesStore