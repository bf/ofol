stderr.deprecated("unused file")


-- TODO: refactor
function core.set_project_dir(new_dir, change_project_fn)
  stderr.error("set project dir to %s", new_dir)

  local chdir_ok = pcall(system.chdir, new_dir)
  if chdir_ok then
    if change_project_fn then change_project_fn() end
    core.project_dir = fsutils.normalize_volume(new_dir)
    core.project_directories = {}
  end
  return chdir_ok
end


-- TODO: refactor
function core.open_folder_project(dir_path_abs)
  stderr.error("open folder project %s", dir_path_abs)

  if core.set_project_dir(dir_path_abs, core.on_quit_project) then
    core.root_view:close_all_docviews()
    core.add_project_directory(dir_path_abs)
    core.on_enter_project(dir_path_abs)
  end
end


-- TODO: refactor
function core.project_subdir_is_shown(dir, filename)
  return not dir.files_limit or dir.shown_subdir[filename]
end



-- TODO: refactor
-- bisects the sorted file list to get to things in ln(n)
local function file_bisect(files, is_superior, start_idx, end_idx)
  local inf, sup = start_idx or 1, end_idx or #files
  while sup - inf > 8 do
    local curr = math.floor((inf + sup) / 2)
    if is_superior(files[curr]) then
      sup = curr - 1
    else
      inf = curr
    end
  end
  while inf <= sup and not is_superior(files[inf]) do
    inf = inf + 1
  end
  return inf
end

-- TODO: refactor
local function file_search(files, info)
  local idx = file_bisect(files, function(file)
    return system.path_compare(info.filename, info.type, file.filename, file.type)
  end)
  if idx > 1 and files[idx-1].filename == info.filename then
    return idx - 1, true
  end
  return idx, false
end

-- TODO: refactor
local function files_info_equal(a, b)
  return (a == nil and b == nil) or (a and b and a.filename == b.filename and a.type == b.type)
end

-- TODO: refactor
local function project_subdir_bounds(dir, filename, start_index)
  local found = true
  if not start_index then
    start_index, found = file_search(dir.files, { type = "dir", filename = filename })
  end
  if found then
    local end_index = file_bisect(dir.files, function(file)
      return not fsutils.path_belongs_to(file.filename, filename)
    end, start_index + 1)
    return start_index, end_index - start_index, dir.files[start_index]
  end
end

-- TODO: refactor
-- Should be called on any directory that registers a change, or on a directory we open if we're over the file limit.
-- Uses relative paths at the project root (i.e. target = "", target = "first-level-directory", target = "first-level-directory/second-level-directory")
local function refresh_directory(topdir, target)
  local directory_start_idx, directory_end_idx = 1, #topdir.files
  if target and target ~= "" then
    directory_start_idx, directory_end_idx = project_subdir_bounds(topdir, target)
    directory_end_idx = directory_start_idx + directory_end_idx - 1
    directory_start_idx = directory_start_idx + 1
  end

  local files = dirwatch.get_directory_files(topdir, topdir.name, (target or ""), 0, function() return false end)
  local change = false

  -- If this file doesn't exist, we should be calling this on our parent directory, assume we'll do that.
  -- Unwatch just in case.
  if files == nil then
    topdir.watch:unwatch(topdir.name .. PATHSEP .. (target or ""))
    return true
  end

  local new_idx, old_idx = 1, directory_start_idx
  local new_directories = {}
  -- Run through each sorted list and compare them. If we find a new entry, insert it and flag as new. If we're missing an entry
  -- remove it and delete the entry from the list.
  while old_idx <= directory_end_idx or new_idx <= #files do
    local old_info, new_info = topdir.files[old_idx], files[new_idx]
    if not files_info_equal(new_info, old_info) then
      change = true
      -- If we're a new file, and we exist *before* the other file in the list, then add to the list.
      if not old_info or (new_info and system.path_compare(new_info.filename, new_info.type, old_info.filename, old_info.type)) then
        table.insert(topdir.files, old_idx, new_info)
        old_idx, new_idx = old_idx + 1, new_idx + 1
        if new_info.type == "dir" then
          table.insert(new_directories, new_info)
        end
        directory_end_idx = directory_end_idx + 1
      else
      -- If it's not there, remove the entry from the list as being out of order.
        table.remove(topdir.files, old_idx)
        if old_info.type == "dir" then
          topdir.watch:unwatch(topdir.name .. PATHSEP .. old_info.filename)
        end
        directory_end_idx = directory_end_idx - 1
      end
    else
      -- If this file is a directory, determine in ln(n) the size of the directory, and skip every file in it.
      local size = old_info and old_info.type == "dir" and select(2, project_subdir_bounds(topdir, old_info.filename, old_idx)) or 1
      old_idx, new_idx = old_idx + size, new_idx + 1
    end
  end
  for i, v in ipairs(new_directories) do
    topdir.watch:watch(topdir.name .. PATHSEP .. v.filename)
    if not topdir.files_limit or core.project_subdir_is_shown(topdir, v.filename) then
      refresh_directory(topdir, v.filename)
    end
  end
  if change then
    GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true
    topdir.is_dirty = true
  end
  return change
end


-- Predicate function to inhibit directory recursion in get_directory_files
-- based on a time limit and the number of files.
local function timed_max_files_pred(dir, filename, entries_count, t_elapsed)
  local t_limit = t_elapsed < 20 / GLOBAL_CONSTANT_FRAMES_PER_SECOND
  return t_limit and core.project_subdir_is_shown(dir, filename)
end

-- TODO: refactor
function core.add_project_directory(path)
  -- top directories has a file-like "item" but the item.filename
  -- will be simply the name of the directory, without its path.
  -- The field item.topdir will identify it as a top level directory.
  path = fsutils.normalize_volume(path)
  local topdir = {
    name = path,
    item = {filename = fsutils.basename(path), type = "dir", topdir = true},
    files_limit = false,
    is_dirty = true,
    shown_subdir = {},
    watch_thread = nil,
    watch = dirwatch.new()
  }
  table.insert(core.project_directories, topdir)

  local fstype = PLATFORM == "Linux" and system.get_fs_type(topdir.name) or "unknown"
  topdir.force_scans = (fstype == "nfs" or fstype == "fuse")

  -- load all files recursively
  local t, complete, entries_count = dirwatch.get_directory_files(topdir, topdir.name, "", 0, timed_max_files_pred)

  topdir.files = t
  if not complete then
    topdir.slow_filesystem = not complete 
    topdir.files_limit = true
    refresh_directory(topdir)
  else
    for i,v in ipairs(t) do
      if v.type == "dir" then topdir.watch:watch(path .. PATHSEP .. v.filename) end
    end
  end
  topdir.watch:watch(topdir.name)
  -- each top level directory gets a watch thread. if the project is small, or
  -- if the ablity to use directory watches hasn't been compromised in some way
  -- either through error, or amount of files, then this should be incredibly
  -- quick; essentially one syscall per check. Otherwise, this may take a bit of
  -- time; the watch will yield in this coroutine after 0.01 second, for 0.1 seconds.
  topdir.watch_thread = threading.add_thread(function()
    while true do
      local changed = topdir.watch:check(function(target)
        if target == topdir.name then return refresh_directory(topdir) end
        local dirpath = target:sub(#topdir.name + 2)
        local abs_dirpath = topdir.name .. PATHSEP .. dirpath
        if dirpath then
          -- check if the directory is in the project files list, if not exit.
          local dir_index, dir_match = file_search(topdir.files, {filename = dirpath, type = "dir"})
          if not dir_match or not core.project_subdir_is_shown(topdir, topdir.files[dir_index].filename) then return end
        end
        return refresh_directory(topdir, dirpath)
      end, 0.01, 0.01)
      -- properly exit coroutine if project not open anymore to clear dir watch
      local project_dir_open = false
      for _, prj in ipairs(core.project_directories) do
        if topdir == prj then
          project_dir_open = true
          break
        end
      end
      if project_dir_open then
        coroutine.yield(changed and 0 or 0.05)
      else
        return
      end
    end
  end)

  if path == core.project_dir then
    core.project_files = topdir.files
  end
  GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true
  return topdir
end

-- TODO: refactor
-- The function below is needed to reload the project directories
-- when the project's module changes.
function core.rescan_project_directories()
  stderr.error("rescan project directories")

  local save_project_dirs = {}
  local n = #core.project_directories
  for i = 1, n do
    local dir = core.project_directories[i]
    save_project_dirs[i] = {name = dir.name, shown_subdir = dir.shown_subdir}
  end
  core.project_directories = {}
  for i = 1, n do -- add again the directories in the project
    local dir = core.add_project_directory(save_project_dirs[i].name)
    if dir.files_limit then
      -- We need to sort the list of shown subdirectories so that higher level
      -- directories are populated first. We use the function system.path_compare
      -- because it order the entries in the appropriate order.
      -- TODO: we may consider storing the table shown_subdir as a sorted table
      -- since the beginning.
      local subdir_list = {}
      for subdir in pairs(save_project_dirs[i].shown_subdir) do
        table.insert(subdir_list, subdir)
      end
      table.sort(subdir_list, function(a, b) return system.path_compare(a, "dir", b, "dir") end)
      for _, subdir in ipairs(subdir_list) do
        local show = save_project_dirs[i].shown_subdir[subdir]
        for j = 1, #dir.files do
          if dir.files[j].filename == subdir then
            -- The instructions below match when happens in TreeView:on_mouse_pressed.
            -- We perform the operations only once iff the subdir is in dir.files.
            -- In theory set_show below may fail and return false but is it is listed
            -- there it means it succeeded before so we are optimistically assume it
            -- will not fail for the sake of simplicity.
            core.update_project_subdir(dir, subdir, show)
            break
          end
        end
      end
    end
  end
end

-- TODO: refactor
function core.project_dir_by_name(name)
  for i = 1, #core.project_directories do
    if core.project_directories[i].name == name then
      return core.project_directories[i]
    end
  end
end

-- TODO: refactor
function core.update_project_subdir(dir, filename, expanded)
  assert(dir.files_limit, "function should be called only when directory is in files limit mode")
  dir.shown_subdir[filename] = expanded
  if expanded then
    dir.watch:watch(dir.name .. PATHSEP .. filename)
  else
    dir.watch:unwatch(dir.name .. PATHSEP .. filename)
  end
  return refresh_directory(dir, filename)
end


-- TODO: refactor
-- Find files and directories recursively reading from the filesystem.
-- Filter files and yields file's directory and info table. This latter
-- is filled to be like required by project directories "files" list.
local function find_files_recursively(root, path)
  local all = system.list_dir(root .. path) or {}
  for _, file in ipairs(all) do
    local file = path .. PATHSEP .. file
    local info = system.get_file_info(root .. file)
    if info then
      info.filename = fsutils.strip_leading_path(file)
      if info.type == "file" then
        coroutine.yield(root, info)
      elseif not string.match_pattern(fsutils.basename(info.filename), ConfigurationOptionStore.get_editor_ignore_files()) then
        find_files_recursively(root, PATHSEP .. info.filename)
      end
    end
  end
end


-- Iterator function to list all project files
local function project_files_iter(state)
  local dir = core.project_directories[state.dir_index]
  if state.co then
    -- We have a coroutine to fetch for files, use the coroutine.
    -- Used for directories that exceeds the files nuumber limit.
    local ok, name, file = coroutine.resume(state.co, dir.name, "")
    if ok and name then
      return name, file
    else
      -- The coroutine terminated, increment file/dir counter to scan
      -- next project directory.
      state.co = false
      state.file_index = 1
      state.dir_index = state.dir_index + 1
      dir = core.project_directories[state.dir_index]
    end
  else
    -- Increase file/dir counter
    state.file_index = state.file_index + 1
    while dir and state.file_index > #dir.files do
      state.dir_index = state.dir_index + 1
      state.file_index = 1
      dir = core.project_directories[state.dir_index]
    end
  end
  if not dir then return end
  if dir.files_limit then
    -- The current project directory is files limited: create a couroutine
    -- to read files from the filesystem.
    state.co = coroutine.create(find_files_recursively)
    return project_files_iter(state)
  end
  return dir.name, dir.files[state.file_index]
end


function core.get_project_files()
  local state = { dir_index = 1, file_index = 0 }
  return project_files_iter, state
end


function core.project_files_number()
  local n = 0
  for i = 1, #core.project_directories do
    if core.project_directories[i].files_limit then return end
    n = n + #core.project_directories[i].files
  end
  return n
end

function core.remove_project_directory(path)
  -- skip the fist directory because it is the project's directory
  for i = 2, #core.project_directories do
    local dir = core.project_directories[i]
    if dir.name == path then
      table.remove(core.project_directories, i)
      return true
    end
  end
  return false
end



-- The function below works like system.absolute_path except it
-- doesn't fail if the file does not exist. We consider that the
-- current dir is core.project_dir so relative filename are considered
-- to be in core.project_dir.
-- Please note that .. or . in the filename are not taken into account.
-- This function should get only filenames normalized using
-- fsutils.normalize_path function.
function core.project_absolute_path(filename)
  if fsutils.is_absolute_path(filename) then
    return fsutils.normalize_path(filename)
  elseif not core.project_dir then
    local cwd = system.absolute_path(".")
    return cwd .. PATHSEP .. fsutils.normalize_path(filename)
  else
    return core.project_dir .. PATHSEP .. filename
  end
end


function core.normalize_to_project_dir(filename)
  filename = fsutils.normalize_path(filename)
  if fsutils.path_belongs_to(filename, core.project_dir) then
    filename = fsutils.relative_path(core.project_dir, filename)
  end
  return filename
end

  -- -- try to load recent projects
  -- local project_dir = core.recent_projects[1] or "."
  -- local project_dir_explicit = false
  -- local files = {}
  -- for i = 2, #ARGS do
  --   local arg_filename = fsutils.strip_trailing_slash(ARGS[i])
  --   local info = system.get_file_info(arg_filename) or {}
  --   if info.type == "dir" then
  --     project_dir = arg_filename
  --     project_dir_explicit = true
  --   else
  --     -- on macOS we can get an argument like "-psn_0_52353" that we just ignore.
  --     if not ARGS[i]:match("^-psn") then
  --       local file_abs = core.project_absolute_path(arg_filename)
  --       if file_abs then
  --         table.insert(files, file_abs)
  --         project_dir = file_abs:match("^(.+)[/\\].+$")
  --       end
  --     end
  --   end
  -- end






  
  -- do
  --   local pdir, pname = project_dir_abs:match("(.*)[/\\\\](.*)")
  --   stderr.info("Opening project %q from directory %s", pname, pdir)
  -- end

  -- -- We add the project directory now because the project's module is loaded.
  -- stderr.debug("project directory: %s", project_dir_abs)
  -- core.add_project_directory(project_dir_abs)

  stderr.debug("opening documents from last session")
  local files = {}
  for _, filename in ipairs(files) do
    core.root_view:open_doc(core.open_doc(filename))
  end
