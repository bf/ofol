-- even though $style variable is not used in this file, 
-- if we remove this then the loading of style in views does not work
local style = require "themes.colors.default"


local PersistentUserSession
local command
local keymap
local dirwatch
local ime
local RootView
local TreeView
local ToolbarView
local StatusView
local SettingsView
local CommandView
local DocView
local Doc

local core = {}


-- TODO: refactor
local function update_recents_project(action, dir_path_abs)
  local dirname = fsutils.normalize_volume(dir_path_abs)
  if not dirname then return end
  local recents = core.recent_projects
  local n = #recents
  for i = 1, n do
    if dirname == recents[i] then
      table.remove(recents, i)
      break
    end
  end
  if action == "add" then
    table.insert(recents, 1, dirname)
  end
end


-- TODO: refactor
function core.set_project_dir(new_dir, change_project_fn)
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
  if core.set_project_dir(dir_path_abs, core.on_quit_project) then
    core.root_view:close_all_docviews()
    -- reload_customizations()
    update_recents_project("add", dir_path_abs)
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
    TRIGGER_REDRAW_NEXT_FRAME = true
    topdir.is_dirty = true
  end
  return change
end


-- Predicate function to inhibit directory recursion in get_directory_files
-- based on a time limit and the number of files.
local function timed_max_files_pred(dir, filename, entries_count, t_elapsed)
  local t_limit = t_elapsed < 20 / CONSTANT_FRAMES_PER_SECOND
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
  topdir.watch_thread = core.add_thread(function()
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
  TRIGGER_REDRAW_NEXT_FRAME = true
  return topdir
end

-- TODO: refactor
-- The function below is needed to reload the project directories
-- when the project's module changes.
function core.rescan_project_directories()
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


function core.init()
  core.info_items = {}
  stderr.debug("OFOL version %s", VERSION)

  command = require "core.command"
  keymap = require "core.keymap"
  dirwatch = require "core.dirwatch"
  ime = require "core.ime" 
  PersistentUserSession = require "persistence.persistent_user_session"

  RootView = require "core.views.rootview"
  StatusView = require "core.views.statusview"
  CommandView = require "core.views.commandview"
  
  DocView = require "core.views.docview"
  TreeView = require "core.views.treeview"
  ToolbarView = require "core.views.toolbarview"
  SettingsView = require "core.views.settingsview"
  
  Doc = require "core.doc"

  -- for WINDOWS: fix paths
  if PATHSEP == '\\' then
    USERDIR = fsutils.normalize_volume(USERDIR)
    DATADIR = fsutils.normalize_volume(DATADIR)
    EXEDIR  = fsutils.normalize_volume(EXEDIR)
  end

  -- check if user config directory ~/.config/ofol exists
  -- check if user directory exists
  local stat_dir = system.get_file_info(USERDIR)
  if not stat_dir then
    stderr.debug("user directory at %s does not exist. will create it now")

    -- create a directory using mkdir but may need to create the parent
    -- directories as well.
    local success, err = fsutils.mkdirp(USERDIR)
    if not success then
      stderr.error("cannot create user directory \"" .. USERDIR .. "\": " .. err)
    end
  end

  -- initialize window
  core.window = renwindow._restore()
  if core.window == nil then
    core.window = renwindow.create("OFOL2")
  end

  do
    -- load last session
    local stored_session_data = PersistentUserSession.load_user_session()
    stderr.debug("loaded stored_session_data %s", stored_session_data)

    -- -- apply stored settings to window
    -- if stored_session_data.window_mode == "normal" then
    --   -- attempt to set window size, but ignore if an error appears
    --   local ok, result = pcall(system.set_window_size, core.window, table.unpack(stored_session_data.window))
      
    --   -- handle error
    --   if not ok then
    --     for k,v in pairs(stored_session_data) do
    --       stderr.debug("stored_session_data k %s v %s", k, v)
    --     end
    --     stderr.error("set_window_size failed for stored_session_data.window %s with %s", stored_session_data, result)
    --   end
    -- elseif stored_session_data.window_mode == "maximized" then
    --   system.set_window_mode(core.window, "maximized")
    -- end

    -- apply other values from last session
    core.recent_projects = stored_session_data.recent_projects or {}
  end

  -- try to load recent projects
  local project_dir = core.recent_projects[1] or "."
  local project_dir_explicit = false
  local files = {}
  for i = 2, #ARGS do
    local arg_filename = fsutils.strip_trailing_slash(ARGS[i])
    local info = system.get_file_info(arg_filename) or {}
    if info.type == "dir" then
      project_dir = arg_filename
      project_dir_explicit = true
    else
      -- on macOS we can get an argument like "-psn_0_52353" that we just ignore.
      if not ARGS[i]:match("^-psn") then
        local file_abs = core.project_absolute_path(arg_filename)
        if file_abs then
          table.insert(files, file_abs)
          project_dir = file_abs:match("^(.+)[/\\].+$")
        end
      end
    end
  end

  core.frame_start = 0
  core.clip_rect_stack = {{ 0,0,0,0 }}
  core.docs = {}
  core.cursor_clipboard = {}
  core.cursor_clipboard_whole_line = {}
  core.previous_find = {}
  core.previous_replace = {}
  -- core.window_mode = "normal"
  core.threads = setmetatable({}, { __mode = "k" })

  -- -- flag when user is actively resizing window
  -- core.window_is_being_resized = false

  -- blinking cursor timer active
  core.blink_start = system.get_time()
  core.blink_timer = core.blink_start
  TRIGGER_REDRAW_NEXT_FRAME = true
  core.visited_files = {}
  core.restart_request = false
  core.quit_request = false

  -- We load core views before plugins that may need them.
  core.root_view = RootView()
  core.command_view = CommandView()
  core.status_view = StatusView()
  core.settings_view = SettingsView()

  -- Load default commands first so plugins can override them
  command.add_defaults()

  -- Some plugins (eg: console) require the nodes to be initialized to defaults
  local cur_node = core.root_view.root_node
  cur_node.is_primary_node = true
  cur_node:split("up", core.command_view, {y = true})
  cur_node = cur_node.b
  cur_node = cur_node:split("down", core.status_view, {y = true})

  -- init treeview
  core.tree_view = TreeView()
  core.tree_view.node = core.root_view:get_active_node():split("left", core.tree_view, {x = true}, true)

  -- init toolbar view
  core.toolbar_view = ToolbarView()
  core.toolbar_view.node = core.tree_view.node:split("up", core.toolbar_view, {y = true})

  -- set minimum width for treeview
  local min_toolbar_width = math.floor(core.toolbar_view:get_min_width())
  core.tree_view:set_minimum_target_size_x(min_toolbar_width)
  core.tree_view:set_target_size("x", min_toolbar_width)



  local project_dir_abs = system.absolute_path(project_dir)
  -- We prevent set_project_dir below to effectively add and scan the directory because the
  -- project module and its ignore files is not yet loaded.
  local set_project_ok = project_dir_abs and core.set_project_dir(project_dir_abs)
  if set_project_ok then
    -- got_project_error = not core.load_project_module()
    if project_dir_explicit then
      update_recents_project("add", project_dir_abs)
    end
  else
    if not project_dir_explicit then
      update_recents_project("remove", project_dir)
    end
    project_dir_abs = system.absolute_path(".")
    if not core.set_project_dir(project_dir_abs, function()
      -- got_project_error = not core.load_project_module()
    end) then
      stderr.error("cannot set project directory to cwd")
      system.show_fatal_error("Lite XL internal error", "cannot set project directory to cwd")
      os.exit(1)
    end
  end

  -- -- initialize settings
  -- require("core.settings")

  -- load syntax highlighting
  local syntax = require "lib.syntax"
  syntax.load_languages()

  -- load ide features
  local ide = require "core.ide"

  -- redraw
  TRIGGER_REDRAW_NEXT_FRAME = true

  do
    local pdir, pname = project_dir_abs:match("(.*)[/\\\\](.*)")
    stderr.info("Opening project %q from directory %s", pname, pdir)
  end

  -- We add the project directory now because the project's module is loaded.
  stderr.debug("project directory: %s", project_dir_abs)
  core.add_project_directory(project_dir_abs)

  stderr.debug("opening documents from last session")
  for _, filename in ipairs(files) do
    core.root_view:open_doc(core.open_doc(filename))
  end

  -- enable native borderes
  system.set_window_hit_test()
  system.set_window_bordered(true)
end

-- close all docs, prompt user about unsaved changes
function core.confirm_close_docs()
  stderr.debug("confirm closing docs")

  -- iterate over all open documents
  for _, doc in ipairs(core.docs) do
    -- try to close document
    -- this will prompt user about unsaved changes
    if not doc:try_close() then
      -- if user doesn't want to quit, return false
      stderr.warn("cannot be closed")
      return false
    end
  end

  stderr.debug("CAN BE CLOSED")
  return true
end

-- override to perform an operation before quitting or entering the
-- current project
do
  local do_nothing = function() end
  core.on_quit_project = do_nothing
  core.on_enter_project = do_nothing
end

-- quit with option for restarting
local function quit_with_function(quit_fn)
  if core.confirm_close_docs() then
    stderr.debug("quit_with_function will quit because confirm_close_docs() true")
    quit_fn()
  end

  stderr.debug("quit_with_function will not quit")
end

-- quit the application
function core.quit()
  stderr.debug("core.quit() called")
  quit_with_function(function() core.quit_request = true end)
end

-- restart the application
function core.restart()
  stderr.debug("core.restart() called")
  quit_with_function(function()
    core.restart_request = true
    core.window:_persist()
  end)
end

function core.set_visited(filename)
  for i = 1, #core.visited_files do
    if core.visited_files[i] == filename then
      table.remove(core.visited_files, i)
      break
    end
  end
  table.insert(core.visited_files, 1, filename)
end

-- this is called from node.set_active_view() in order to
-- re-focus the text input handling onto another view
function core.set_active_view(view)
  assert(view, "Tried to set active view to nil")
  stderr.debug("set_active_view")

  -- Reset the IME even if the focus didn't change
  ime.stop()
  if view ~= core.active_view then
    system.text_input(view:supports_text_input())
    if core.active_view and core.active_view.force_focus then
      core.next_active_view = view
      return
    end
    core.next_active_view = nil
    if view.doc and view.doc.filename then
      core.set_visited(view.doc.filename)
    end
    core.last_active_view = core.active_view
    core.active_view = view
  end
end


-- create thread
local thread_counter = 0
function core.add_thread(f, weak_ref, ...)
  stderr.debug_backtrace("adding thread")
  local key = weak_ref
  if not key then
    thread_counter = thread_counter + 1
    key = thread_counter
  end
  assert(core.threads[key] == nil, "Duplicate thread reference")
  local args = {...}
  local fn = function() return try_catch(f, table.unpack(args)) end
  core.threads[key] = { cr = coroutine.create(fn), wake = 0 }
  return key
end


function core.push_clip_rect(x, y, w, h)
  local x2, y2, w2, h2 = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  local r, b, r2, b2 = x+w, y+h, x2+w2, y2+h2
  x, y = math.max(x, x2), math.max(y, y2)
  b, r = math.min(b, b2), math.min(r, r2)
  w, h = r-x, b-y
  table.insert(core.clip_rect_stack, { x, y, w, h })
  renderer.set_clip_rect(x, y, w, h)
end


function core.pop_clip_rect()
  table.remove(core.clip_rect_stack)
  local x, y, w, h = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  renderer.set_clip_rect(x, y, w, h)
end


function core.normalize_to_project_dir(filename)
  filename = fsutils.normalize_path(filename)
  if fsutils.path_belongs_to(filename, core.project_dir) then
    filename = fsutils.relative_path(core.project_dir, filename)
  end
  return filename
end


function core.open_doc(filename)
  local new_file = not filename or not system.get_file_info(filename)

  if new_file then
    stderr.debug("open new file")
  else
    stderr.debug("open \"%s\"", filename)
  end

  local abs_filename
  if filename then
    -- normalize filename and set absolute filename then
    -- try to find existing doc for filename
    filename = core.normalize_to_project_dir(filename)
    abs_filename = core.project_absolute_path(filename)
    
    -- find already openend doc for this absolute path
    for _, doc in ipairs(core.docs) do
      if doc.abs_filename and abs_filename == doc.abs_filename then
        return doc
      end
    end
  end

  -- no existing doc for filename; create new
  local doc = Doc(filename, abs_filename, new_file)
  table.insert(core.docs, doc)

  stderr.debug("created new abs_filename %s", abs_filename)

  return doc
end


function core.get_views_referencing_doc(doc)
  local res = {}
  local views = core.root_view.root_node:get_children()
  for _, view in ipairs(views) do
    if view.doc == doc then table.insert(res, view) end
  end
  return res
end



function core.on_event(type, ...)
  if type ~= "mouse_moved" then
    stderr.debug("on_event", type)
  end

  local did_keymap = false
  if type == "text_input" then
    core.root_view:on_text_input(...)
  elseif type == "text_editing" then
    ime.on_text_editing(...)
  elseif type == "key_pressed" then
    -- In some cases during IME composition input is still sent to us
    -- so we just ignore it.
    if ime.editing then 
      stderr.error("key_pressed event should never be received when ime.editing == true, received", ...)
      return false 
    end
    did_keymap = keymap.on_key_pressed(...)
  elseif type == "key_released" then
    keymap.on_key_released(...)
  -- elseif type == "mouse_moved" then
  --   core.root_view:on_mouse_moved(...)
  -- elseif type == "mouse_pressed" then
  --   stderr.debug("core on_mouse_pressed")
  --   if not core.root_view:on_mouse_pressed(...) then
  --     did_keymap = keymap.on_mouse_pressed(...)
  --   end
  -- elseif type == "mouse_released" then
  --   core.root_view:on_mouse_released(...)
  -- elseif type == "mouse_left" then
  --   -- core.root_view:on_mouse_left()
  -- elseif type == "mouse_wheel" then
  --   if not core.root_view:on_mouse_wheel(...) then
  --     did_keymap = keymap.on_mouse_wheel(...)
  --   end
  -- elseif type == "window_resized" then
  --   -- core.window_mode = system.get_window_mode(core.window)
  -- elseif type == "window_minimized" or type == "window_maximized" or type == "window_restored" then
  --   core.window_mode = type == "window_restored" and "normal" or type
  elseif type == "filedropped" then
    core.root_view:on_file_dropped(...)
  -- elseif type == "window_focuslost" then
  --   core.root_view:on_focus_lost(...)
  elseif type == "quit" then
    core.quit()
  end
  return did_keymap
end


local StateMachine = require("models.state_machine")

-- cursor should be animated or not
AnimationState = StateMachine("AnimationState", {
  active = {},
  inactive = {},
  ["*"] = {
    window_focuslost = function() 
      return "inactive"
    end,
    window_focusgained = function()
      return "active"
    end
  }
}, "active")

-- window maxmized or not
WindowState = StateMachine("WindowState", { 
  normal = {},
  minimized = {},
  maximized = {},
  resizing = {},
  ["*"] = {
    window_exposed = function () 
      -- Window has been exposed and should be redrawn, and can be redrawn directly from event watchers for this event
      TRIGGER_REDRAW_NEXT_FRAME = true 
      -- return "normal"
    end,
    window_focuslost = function (event_name) 
      -- Window has lost focus, redraw
      TRIGGER_REDRAW_NEXT_FRAME = true
      AnimationState:handle_event(event_name)
    end,
    window_focusgained = function (event_name) 
      -- Window has lost focus, redraw
      TRIGGER_REDRAW_NEXT_FRAME = true
      AnimationState:handle_event(event_name)
    end,
    window_restored = function () 
      -- Window has been restored to normal size and position
      return "normal"
    end,
    window_resized = function () 
      -- TRIGGER_REDRAW_NEXT_FRAME = true 
      -- return "resizing" 
    end,
    window_minimized = function () 
      return "minimized"
    end,
    window_maximized = function () 
      return "maximized"
    end
  }
}, "normal")


-- globally store currently hovered item
State = {
  HoveredItem = nil,
  MousePosition = {
    x = nil,
    y = nil
  }
}
-- MouseHoveredState = StateMachine("MouseHoveredState", {
--   mouse_moved = {},
--   mouse_has_left_the_window = {
--     mouse_is_back_inside_window = function (event_name, x, y) 
--       return 
--     end
--   },
--   mouse_is_back_inside_window = {},
-- })

  -- position = {
  --   x = nil, 
  --   y = nil
  -- },
  -- mouse_wheel = {},
-- 
  -- mouse_pressed = {},
  -- mouse_released = {},

-- MouseCursorState = StateMachine("MouseCursorState")

-- remember if keymap is completed
local did_keymap = false

-- handling mouse event
function _handle_mouse_event(event_name, a, b, c, d) 
  stderr.debug("_handle_mouse_event", event_name, a, b, c, d)

  if event_name == "mouse_has_left_window" then
    -- when mouse outside window, reset hovered item
    State.HoveredItem = nil

  elseif event_name == "mouse_moved" then
    -- update mouse position
    State.MousePosition.x = a
    State.MousePosition.y = b

    -- redraw frame
    TRIGGER_REDRAW_NEXT_FRAME = true

    -- run on_mouse_moved function
    core.root_view:on_mouse_moved(a, b, c, d)

  elseif event_name == "mouse_pressed" then
    -- run on_mouse_pressed functions
    if not core.root_view:on_mouse_pressed(a, b, c, d) then
      did_keymap = keymap.on_mouse_pressed(a, b, c, d)
    end

  elseif event_name == "mouse_released" then
    core.root_view:on_mouse_released(a, b, c, d)

  elseif event_name == "mouse_wheel" then
    if not core.root_view:on_mouse_wheel(a, b, c, d) then
      did_keymap = keymap.on_mouse_wheel(a, b, c, d)
    end
    
  else
    stderr.warn("no handler found for", event_name)
  end
end

-- main stepping loop for event handling
function core.step()
  -- handle events
  -- local did_keymap = false

  for event_name, a,b,c,d in system.poll_event do
    if string.starts_with(event_name, "window_") then
      WindowState:handle_event(event_name)
    -- if event_name == "window_resized" then
    --   -- dont redraw while resizing
    --   core.window_is_being_resized = true
    --   TRIGGER_REDRAW_NEXT_FRAME = true
    -- elseif event_name == "window_exposed" then
    --   -- redraw only when exposed
    --   TRIGGER_REDRAW_NEXT_FRAME = true
    elseif string.starts_with(event_name, "mouse_") then
      _handle_mouse_event(event_name, a, b, c, d)
    elseif event_name == "text_input" and did_keymap then
      did_keymap = false
      TRIGGER_REDRAW_NEXT_FRAME = true
      -- core.window_is_being_resized = false
    -- elseif event_name == "mouse_moved" then
    --   try_catch(core.on_event, event_name, a, b, c, d)
      -- core.on_event(event_name, a,b,c,d)
      -- TRIGGER_REDRAW_NEXT_FRAME = true
      -- core.window_is_being_resized = false
    else
      -- handle all other cases
      -- local _, res = try_catch(core.on_event, event_name, a, b, c, d)
      local res = core.on_event(event_name, a,b,c,d)
      did_keymap = res or did_keymap
      
      TRIGGER_REDRAW_NEXT_FRAME = true
      -- core.window_is_being_resized = false
    end
  end

  local width, height = core.window:get_size()

  -- update
  core.root_view.size.x, core.root_view.size.y = width, height
  core.root_view:update()
  if not TRIGGER_REDRAW_NEXT_FRAME then return false end
  TRIGGER_REDRAW_NEXT_FRAME = false

  -- close unreferenced docs
  for i = #core.docs, 1, -1 do
    local doc = core.docs[i]
    if #core.get_views_referencing_doc(doc) == 0 then
      table.remove(core.docs, i)
      doc:on_close()
    end
  end

  -- update window title
  local window_title_from_filename

  -- when we have active view then take window title from view
  if core.active_view ~= nil then
    -- try to use get_filename() function for window title
    if core.active_view.get_filename  ~= nil and core.active_view:get_filename() then
      window_title_from_filename = core.active_view:get_filename()
    else 
      -- fallback use view:get_name() function
      window_title_from_filename = core.active_view:get_name()
    end

    -- handle case when view returns *default* name of "---"
    if window_title_from_filename == "---" then
      window_title_from_filename = ""
    end

    -- generate new window title    
    local new_window_title

    -- check if default window title should be sed
    if window_title_from_filename ~= nil  then
      -- use default window title
      new_window_title = "OFOL"
    else
      -- use filename in windows title
      new_window_title = window_title_from_filename
    end

    -- check if title needs to be changed
    if new_window_title and new_window_title ~= core.window_title then
      stderr.debug("new_window_title", new_window_title)

      -- set new window title
      system.set_window_title(core.window, new_window_title)
      core.window_title = new_window_title
    end
  end

  -- draw
  renderer.begin_frame(core.window)
  core.clip_rect_stack[1] = { 0, 0, width, height }
  renderer.set_clip_rect(table.unpack(core.clip_rect_stack[1]))
  core.root_view:draw()
  renderer.end_frame()
  return true
end


-- main threading loop which will interrupt threads to keep fps
local run_threads = coroutine.wrap(function()
  while true do
    local max_time = 1 / CONSTANT_FRAMES_PER_SECOND - 0.004
    local minimal_time_to_wake = math.huge

    local threads = {}
    -- We modify core.threads while iterating, both by removing dead threads,
    -- and by potentially adding more threads while we yielded early,
    -- so we need to extract the threads list and iterate over that instead.
    for k, thread in pairs(core.threads) do
      threads[k] = thread
    end

    for k, thread in pairs(threads) do
      -- Run thread if it wasn't deleted externally and it's time to resume it
      if core.threads[k] and thread.wake < system.get_time() then
        local _, wait = assert(coroutine.resume(thread.cr))
        if coroutine.status(thread.cr) == "dead" then
          core.threads[k] = nil
        else
          wait = wait or (1/30)
          thread.wake = system.get_time() + wait
          minimal_time_to_wake = math.min(minimal_time_to_wake, wait)
        end
      else
        minimal_time_to_wake =  math.min(minimal_time_to_wake, thread.wake - system.get_time())
      end

      -- stop running threads if we're about to hit the end of frame
      if system.get_time() - core.frame_start > max_time then
        coroutine.yield(0, false)
      end
    end

    coroutine.yield(minimal_time_to_wake, true)
  end
end)


-- main run loop for rendering
function core.run()
  local next_step
  local last_frame_time
  local run_threads_full = 0
  local HALF_BLINK_PERIOD = ConfigurationOptionStore.get_editor_blink_period() / 2

  while true do
    core.frame_start = system.get_time()
    local time_to_wake, threads_done = run_threads()
    if threads_done then
      run_threads_full = run_threads_full + 1
    end
    local did_redraw = false
    local did_step = false
    local force_draw = TRIGGER_REDRAW_NEXT_FRAME and last_frame_time and core.frame_start - last_frame_time > (1 / CONSTANT_FRAMES_PER_SECOND)
    if force_draw or not next_step or system.get_time() >= next_step then
      if core.step() then
        did_redraw = true
        last_frame_time = core.frame_start
      end
      next_step = nil
      did_step = true
    end

    if core.restart_request or core.quit_request then 
      stderr.debug("core.restart_request %s core.quit_request %s", core.restart_request, core.quit_request)
      os.exit(1)
      break 
    end

    if not did_redraw and not WindowState:is_resizing() then
      -- if system.window_has_focus(core.window) or not did_step or run_threads_full < 2 then
      if AnimationState:is_active() or not did_step or run_threads_full < 2 then
        local now = system.get_time()
        if not next_step then -- compute the time until the next blink
          local t = now - core.blink_start
          
          local dt = math.ceil(t / HALF_BLINK_PERIOD) * HALF_BLINK_PERIOD - t
          local cursor_time_to_wake = dt + 1 / CONSTANT_FRAMES_PER_SECOND
          next_step = now + cursor_time_to_wake
        end
        if system.wait_event(math.min(next_step - now, time_to_wake)) then
          next_step = nil -- if we've recevied an event, perform a step
        end
      else
        system.wait_event()
        next_step = nil -- perform a step when we're not in focus if get we an event
      end
    else -- if we redrew, then make sure we only draw at most FPS/sec
      run_threads_full = 0
      local now = system.get_time()
      local elapsed = now - core.frame_start
      local next_frame = math.max(0, 1 / CONSTANT_FRAMES_PER_SECOND - elapsed)
      next_step = next_step or (now + next_frame)
      system.sleep(math.min(next_frame, time_to_wake))
    end
  end
end

-- reset countdown timer for text edit caret blinking
-- todo: remove
function core.blink_reset()
  core.blink_start = system.get_time()
end


-- change cursor for the window
function core.request_cursor(value)
  -- check if requested cursor is same as current cursor
  -- if yes, then ignore request
  if core.cursor_change_req_previous ~= nil and core.cursor_change_req_previous == value then
    -- ignore cursor change request
    -- stderr.warn("ignoring cursor change request because new cursor is same as old cursor")
  else
    -- dispatch change request for handling by rootview
    core.cursor_change_req = value

    -- remember last cursor change request
    core.cursor_change_req_previous = value
  end
end

return core
