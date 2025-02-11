-- stores metadata for each file by absolute path
-- metadata used for file titles

local stderr = require "libraries.stderr"

local FileMetadataStore = {}

-- storage object for status from version control
local _store_status_from_version_control = {}

-- storage object for status from compiler
local _store_status_from_compiler = {}

-- set version control status
function FileMetadataStore.set_status_from_version_control(absolute_path, new_status_from_version_control)
  -- stderr.debug("set_status_from_version_control %s %s", absolute_path, new_status_from_version_control)
  _store_status_from_version_control[absolute_path] = new_status_from_version_control
end

-- get version control status
function FileMetadataStore.get_status_from_version_control(absolute_path)
  return _store_status_from_version_control[absolute_path]
end

-- set compiler status
function FileMetadataStore.set_status_from_compiler(absolute_path, new_status_from_compiler)
  stderr.debug("set_status_from_compiler %s %s", absolute_path, new_status_from_compiler)
  _store_status_from_compiler[absolute_path] = new_status_from_compiler
end

-- get compiler status
function FileMetadataStore.get_status_from_compiler(absolute_path)
  return _store_status_from_compiler[absolute_path]
end

-- get file metadata for displaying in the ui
-- returns basename, file differentiator, status_has_been_saved, status from version control (git), status from compiler (lsp)
function FileMetadataStore.get_file_metadata(absolute_path) 
  stderr.debug("absolute_path %s", absolute_path)

  -- get version control status
  local status_from_version_control = FileMetadataStore.get_status_from_version_control(absolute_path)

  -- get compiler status
  local status_from_compiler = FileMetadataStore.get_status_from_compiler(absolute_path)

  return {
    status_from_version_control=status_from_version_control, 
    status_from_compiler=status_from_compiler
  }
end

return FileMetadataStore