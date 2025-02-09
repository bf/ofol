local style = require "core.style"
local stderr = require "libraries.stderr"

local FileMetadataStore = require "core.stores.file_metadata_store"
local OpenFilesStore = require "core.stores.open_files_store"
local common = require "core.common"

local FilenameWithIcon = require "core.ui.render.filename_with_icon"

local FilenameInUI = {}

-- returns string for filename display in window title
function FilenameInUI.get_filename_for_window_title(absolute_path) 
  -- stderr.debug("absolute_path %s", absolute_path)

  if absolute_path == nil then
    return "untitled window_title"
  end

  -- get file basename
  local window_title = common.basename(absolute_path)

  -- get status for unsaved docs
  local status_file_has_unsaved_changes = OpenFilesStore.get_file_has_unsaved_changes(absolute_path)

  if status_file_has_unsaved_changes then
    window_title = window_title .. "*"
  end 
  
  -- when multiple files have same basename we need to use a part of the directory name
  -- in order to differentiate between these files
  local filename_differentiator = OpenFilesStore.get_filename_differentiator(absolute_path)

  if filename_differentiator then
    window_title = window_title .. " — " .. filename_differentiator
  end

  return window_title
end

-- returns FilenameWithIcon object for rendering in tab title
function FilenameInUI.get_filename_for_tab_title(absolute_path,  is_active, is_hovered)
  -- stderr.debug("absolute_path %s is_active:%s is_hovered:%s", absolute_path, is_active, is_hovered)
  
  -- get file basename
  local filename_text
  local filename_color = style.text
  local filename_is_bold = false
  local icon_symbol 
  local icon_color
  local suffix_text
  local suffix_color = style.dim

  -- handle case when filename_text is nil (e.g. new, unsaved document)
  if absolute_path == nil then
    filename_text = "untitled"
  else
    filename_text = common.basename(absolute_path)
  end

  -- active tabs have bold text
  if is_active then
    -- filename_is_bold = true
    filename_color = style.accent
    suffix_color = style.accent
  end

  -- hovered tabs have different color
  if is_hovered then
    filename_color = style.accent
    suffix_color = style.accent
  end

  -- get status for unsaved docs
  local status_file_has_unsaved_changes = OpenFilesStore.get_file_has_unsaved_changes(absolute_path)

  if status_file_has_unsaved_changes then
    filename_text = filename_text .. "*"
  end 

  -- when multiple files have same basename we need to use a part of the directory name
  -- in order to differentiate between these files
  local filename_differentiator = OpenFilesStore.get_filename_differentiator(absolute_path)

  local suffix_text
  if filename_differentiator then
    suffix_text = "— " .. filename_differentiator
  end

  -- check version control status
  local status_from_version_control = FileMetadataStore.get_status_from_version_control(absolute_path)
  if status_from_version_control and #status_from_version_control > 0 then
    if status_from_version_control ~= "untracked" then
      filename_is_bold = true
    end
  end

  -- check compiler status
  local status_from_compiler = FileMetadataStore.get_status_from_compiler(absolute_path)
  if status_from_compiler and #status_from_compiler > 0 then
    if status_from_compiler == "error" then
      icon_symbol = "!" 
      icon_color = style.error
      filename_color = style.error
    elseif status_from_compiler == "warning" then
      icon_symbol = "!"
      icon_color = style.warn
      filename_color = style.warn
    end
  end

  -- create rendering object
  -- (filename_text, filename_color, filename_is_bold, icon_symbol, icon_color, suffix_text, suffix_color) 
  local object_for_rendering = FilenameWithIcon(filename_text, filename_color, filename_is_bold, icon_symbol, icon_color, suffix_text, suffix_color)

  -- stderr.debug("object_for_rendering %s", object_for_rendering)

  return object_for_rendering
end

return FilenameInUI