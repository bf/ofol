-- stores metadata for each file by absolute path
-- metadata used for file titles

local Object = require "core.object"
local common = require "core.common"
local stderr = require "libraries.stderr"

local FileMetadata = Object:extend()

-- initialize 
function FileMetadata:new()
  -- metadata storage object
  self._store_metadata_by_file_absolute_path = {}

  -- store counter for duplicate file basenames
  self._store_number_of_files_with_same_file_basename = {}

  -- store counter for duplicate absolute paths
  self._store_number_of_files_with_same_absolute_path = {}
end

-- increase counter of open files with same basename
function FileMetadata:_counter_number_of_open_files_with_same_basename_increase(basename, absolute_path)
  -- initialize empty table if not set
  if not self._store_number_of_files_with_same_file_basename[basename] then
    self._store_number_of_files_with_same_file_basename[basename] = {}
  end

  -- insert absolute path to table
  self._store_number_of_files_with_same_file_basename[basename][absolute_path] = true

  -- return new counter value
  return #self._store_number_of_files_with_same_file_basename[basename]
end

-- decrease counter of open files with same basename
function FileMetadata:_counter_number_of_open_files_with_same_basename_decrease(basename, absolute_path)
  assert(self._store_number_of_files_with_same_file_basename[basename][absolute_path], "absolute path should be stored in table")
    
  -- unset table object
  self._store_number_of_files_with_same_file_basename[basename][absolute_path] = nil

  -- return new counter value
  return #self._store_number_of_files_with_same_file_basename[basename]
end

-- increase counter of open files with same absolute path
function FileMetadata:_counter_number_of_open_files_with_same_absolute_path_increase(absolute_path)
  if self._store_number_of_files_with_same_absolute_path[absolute_path] then
    self._store_number_of_files_with_same_absolute_path[absolute_path] = self._store_number_of_files_with_same_absolute_path[absolute_path] + 1
  else
    self._store_number_of_files_with_same_absolute_path[absolute_path] = 1
  end

  -- return new counter value
  return self._store_number_of_files_with_same_absolute_path[absolute_path]
end

-- decrease counter of open files with same absolute_path
function FileMetadata:_counter_number_of_open_files_with_same_absolute_path_decrease(absolute_path)
  assert(self._store_number_of_files_with_same_absolute_path[absolute_path] > 0, "when decreasing counter for open files with same absolute_path, at least one file should be opened")
  self._store_number_of_files_with_same_absolute_path[absolute_path] = self._store_number_of_files_with_same_absolute_path[absolute_path] - 1

  -- return new counter value
  return self._store_number_of_files_with_same_absolute_path[absolute_path]
end

-- react to new file opened in editor
-- receivecs doc object
function FileMetadata:handle_open_file(doc)
  -- get absolute path from doc
  local absolute_path = doc.abs_filename

  stderr.debug("handle open file %s", absolute_path)

  -- increase counter for opened files with this absolute path
  self:_counter_number_of_open_files_with_same_absolute_path_increase(absolute_path)

  -- check if metadata already exists, then do nothing
  if self._store_metadata_by_file_absolute_path[absolute_path] then
    stderr.debug("already have metadata for %s, will do nothing", absolute_path)
    return
  end

  -- get file basename from absolute path
  local basename = common.basename(absolute_path)

  -- increase counter of duplicate file basenames
  self:_counter_number_of_open_files_with_same_basename_increase(basename, absolute_path)

  -- update store of metadata
  self._store_metadata_by_file_absolute_path[absolute_path] = {
    basename = basename,
    doc = doc,
    status_from_compiler = nil,
    status_from_source_control = nil
  }
end

-- react to closing of file
function FileMetadata:handle_close_file(absolute_path)
  stderr.debug("handle close file %s", absolute_path)

  assert(self._store_metadata_by_file_absolute_path[absolute_path], "file metadata should exist when closing file")

  -- decrease counter for files open
  local num_total_times_still_open = self:_counter_number_of_open_files_with_same_absolute_path_decrease(absolute_path)

  -- if we have closed the last instance of this file do some cleanup
  if num_total_times_still_open == 0 then
    -- get metadata
    local metadata = self._store_metadata_by_file_absolute_path[absolute_path]

    -- decrease counter of duplicate file basenames
    self:_counter_number_of_open_files_with_same_basename_decrease(metadata["basename"], absolute_path) 

    -- delete metadata object
    self._store_metadata_by_file_absolute_path[absolute_path] = nil
  end
end

-- returns true if more than one file with this basename is open
function FileMetadata:_more_than_one_file_with_this_basename_is_open(basename)
  local counter = 0
  for _, _ in pairs(self._store_number_of_files_with_same_file_basename[basename]) do
    if counter > 1 then
      -- early exit
      return true
    end
    counter = counter + 1
  end

  return (counter > 1)
end

-- returns differentiator suffix for when files with same basename are opened at the same time
function FileMetadata:_get_filename_differentiator(absolute_path, basename) 
  -- file is opened more then once, so we should use the directory name next to the filenames
  if not self:_more_than_one_file_with_this_basename_is_open(basename) then
    return ""
  end

  -- for each file with this common basename, we create an array with parts of the path 
  local tmp_arr_path_parts = {}

  -- stores boolean if file needs differentiator
  local needs_unique_differentiator = {}

  -- stores unique differentiator by file
  local unique_differentiators = {}

  -- loop over each file
  for absolute_path_for_basename, _ in pairs(self._store_number_of_files_with_same_file_basename[basename]) do
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


-- get filename styled for display
-- returns filename, styling, suffix
function FileMetadata:get_filename_for_display_unstyled(absolute_path) 
  assert(self._store_metadata_by_file_absolute_path[absolute_path], "metadata should exist when get_text_for_display is called")

  -- load metadata
  local metadata = self._store_metadata_by_file_absolute_path[absolute_path]

  -- prepare filename variable
  local filename = metadata["basename"]

  -- add * at the end of filename for unsaved docs
  if metadata["doc"]:is_dirty() then
    filename = filename .. "*"
  end
  
  -- when multiple files have same basename we need to use a part of the directory name
  -- in order to differentiate between these files
  local filename_differentiator = self:_get_filename_differentiator(absolute_path, metadata["basename"])

  if #filename_differentiator > 0 then
    -- add differentiator to filename if needed
    filename = filename .. " - " .. filename_differentiator
  end

  return filename
end



return FileMetadata