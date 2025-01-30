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

  -- store counter for duplicate filenames
  self._store_number_of_files_with_same_filename = {}

  -- store counter for duplicate absolute paths
  self._store_number_of_files_with_same_absolute_path = {}
end

-- increase counter of open files with same basename
function FileMetadata:_counter_number_of_open_files_with_same_basename_increase(basename)
  if self._store_number_of_files_with_same_filename[basename] then
    self._store_number_of_files_with_same_filename[basename] = self._store_number_of_files_with_same_filename[basename] + 1
  else
    self._store_number_of_files_with_same_filename[basename] = 1
  end

  -- return new counter value
  return self._store_number_of_files_with_same_filename[basename]
end

-- decrease counter of open files with same basename
function FileMetadata:_counter_number_of_open_files_with_same_basename_decrease(basename)
  assert(self._store_number_of_files_with_same_filename[basename] > 0, "when decreasing counter for open files with same basename, at least one file should be opened")
  self._store_number_of_files_with_same_filename[basename] = self._store_number_of_files_with_same_filename[basename] - 1

  -- return new counter value
  return self._store_number_of_files_with_same_filename[basename]
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
function FileMetadata:handle_open_file(absolute_path)
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
  self:_counter_number_of_open_files_with_same_basename_increase(basename)

  -- update store of metadata
  self._store_metadata_by_file_absolute_path[absolute_path] = {
    basename = basename,
    file_is_dirty = nil,
    file_is_unsaved = nil,
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
    -- decrease counter of duplicate file basenames
    self:_counter_number_of_open_files_with_same_basename_decrease(self._store_metadata_by_file_absolute_path[absolute_path]["basename"]) 

    -- delete metadata object
    self._store_metadata_by_file_absolute_path[absolute_path] = nil
  end
end


return FileMetadata