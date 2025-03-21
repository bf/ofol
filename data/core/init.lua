-- even though $style variable is not used in this file, 
-- if we remove this then the loading of style in views does not work
local style = require "themes.colors.default"
local dirwatch = require "lib.dirwatch"
local PersistentUserSession = require "persistence.persistent_user_session"

local command
local keymap
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



function core.init()
  core.info_items = {}
  stderr.debug("OFOL version %s", VERSION)

  command = require "core.command"
  keymap = require "core.keymap"

  ime = require "core.ime" 

  RootView = require "core.views.rootview"
  StatusView = require "core.views.statusview"
  CommandView = require "core.views.commandview"
  
  DocView = require "core.views.docview"
  TreeView = require "core.views.treeview"
  ToolbarView = require "core.views.toolbarview"
  SettingsView = require "core.views.settingsview"
  
  Doc = require "models.doc"

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
    stderr.debug("loaded stored_session_data %s", json.encode(stored_session_data))

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

    -- load recent projects from last session
    -- core.recent_projects = stored_session_data.recent_projects or {}
  end

  
  core.docs = {}
  core.cursor_clipboard = {}
  core.cursor_clipboard_whole_line = {}
  core.previous_find = {}
  core.previous_replace = {}

  -- blinking cursor timer active
  core.blink_start = system.get_time()
  core.blink_timer = core.blink_start

  core.restart_request = false
  core.quit_request = false

  -- We load core views before plugins that may need them.
  core.root_view = RootView()
  core.command_view = CommandView()
  core.status_view = StatusView()
  core.settings_view = SettingsView()

  -- Load default commands first so plugins can override them
  command.add_defaults()

  -- get pointer to root node
  local cur_node = core.root_view.root_node

  -- mark root node as "primary node"
  cur_node.is_primary_node = true

  -- add command bar
  cur_node:split("up", core.command_view, {y = true})

  -- add address bar
  local NavigationBarView = require("core.views.navigationbarview")
  local navigation_bar = NavigationBarView()

  cur_node = cur_node.child_node_b
  local navigation_bar_node = cur_node:split("up", navigation_bar, {y = true})
  -- navigation_bar_node:set_target_size("y", 200)

  -- add status bar
  cur_node = cur_node.child_node_b
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

  -- load syntax highlighting
  local syntax = require "lib.syntax"
  syntax.load_languages()

  -- load ide features
  local ide = require "core.ide"

  -- redraw
  GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true

  -- enable native borderes
  system.set_window_hit_test()
  system.set_window_bordered(true)

  -- load file
  core.root_view:open_doc(core.open_doc("/home/beni/src/2025-ofol/LICENSE"))
  core.root_view:open_doc(core.open_doc("/home/beni/src/2025-ofol/README.md"))
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
    core.last_active_view = core.active_view
    core.active_view = view
  end
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
    filename = (filename)
    abs_filename = (filename)
    
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
      GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true 
      -- return "normal"
    end,
    window_focuslost = function (event_name) 
      -- Window has lost focus, redraw
      GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true
      AnimationState:handle_event(event_name)
    end,
    window_focusgained = function (event_name) 
      -- Window has lost focus, redraw
      GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true
      AnimationState:handle_event(event_name)
    end,
    window_restored = function () 
      -- Window has been restored to normal size and position
      return "normal"
    end,
    window_resized = function () 
      GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true 
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
InputState = {
  HoveredItem = nil,
  MousePosition = {
    x = nil,
    y = nil
  }
}

-- remember if keymap is completed
local did_keymap = false

-- handling mouse event
function _handle_mouse_event(event_name, a, b, c, d) 
  stderr.debug("_handle_mouse_event", event_name, a, b, c, d)

  if event_name == "mouse_has_left_window" then
    -- when mouse outside window, reset hovered item
    InputState.HoveredItem = nil

  elseif event_name == "mouse_moved" then
    -- update mouse position
    InputState.MousePosition.x = a
    InputState.MousePosition.y = b

    -- redraw frame
    GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true

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
    -- window events
    if string.starts_with(event_name, "window_") then
      WindowState:handle_event(event_name)

    -- mouse events
    elseif string.starts_with(event_name, "mouse_") then
      _handle_mouse_event(event_name, a, b, c, d)
    
    -- text input events
    elseif string.starts_with(event_name, "text_") then
      stderr.warn("text_ event", event_name, a, b, c, d)

      if event_name == "text_input" then
        if did_keymap then
          did_keymap = false
          GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = true
        else
          core.root_view:on_text_input(a,b,c,d)
        end
      elseif event_name == "text_editing" then
        ime.on_text_editing(a,b,c,d)
      end

    -- keyboard events
    elseif string.starts_with(event_name, "key_") then
      stderr.warn("key_ event", event_name, a, b, c, d)
      if event_name == "key_pressed" then
        -- In some cases during IME composition input is still sent to us
        -- so we just ignore it.
        if ime.editing then 
          stderr.error("key_pressed event should never be received when ime.editing == true, received", a, b, c, d)
          did_keymap = false
        else
          did_keymap = keymap.on_key_pressed(a, b, c, d)
        end
      elseif event_name == "key_released" then
        keymap.on_key_released(a, b, c, d)
      end

    -- quit request sent from main executable
    elseif event_name == "quit" then  
      stderr.warn("event: quit", a, b, c, d)
      core.quit()

    -- file dropped into app
    elseif event_name == "filedropped" then
      stderr.warn("event: file dropped", a, b, c, d)
      core.root_view:on_file_dropped(a, b, c, d)

    -- handle unknown events
    else
      stderr.error("unknown/unexpected event received:", event_name, a, b, c, d)
    end
  end

  local width, height = core.window:get_size()

  -- update
  core.root_view.size.x, core.root_view.size.y = width, height
  core.root_view:update()
  if not GLOBAL_TRIGGER_REDRAW_NEXT_FRAME then return false end
  GLOBAL_TRIGGER_REDRAW_NEXT_FRAME = false

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

  -- drawing logic

  -- begin frame generation
  renderer.begin_frame(core.window)

  -- ensure clipping rect is same as window size
  clipping.limit_clip_rect_to_window_size(width, height)

  -- call draw() functions recursively on all nodes
  core.root_view:draw()

  -- end frame generation
  renderer.end_frame()

  return true
end



-- main run loop for rendering
function core.run()
  local next_step
  local last_frame_start_timestamp
  local run_threads_full = 0
  local HALF_BLINK_PERIOD = ConfigurationOptionStore.get_editor_blink_period() / 2

  while true do
    GLOBAL_CURRENT_FRAME_START_TIMESTAMP = system.get_time()
    local time_to_wake, threads_done = threading.run_threads()
    if threads_done then
      run_threads_full = run_threads_full + 1
    end
    local did_redraw = false
    local did_step = false
    local force_draw = GLOBAL_TRIGGER_REDRAW_NEXT_FRAME and last_frame_start_timestamp and GLOBAL_CURRENT_FRAME_START_TIMESTAMP - last_frame_start_timestamp > (1 / GLOBAL_CONSTANT_FRAMES_PER_SECOND)
    if force_draw or not next_step or system.get_time() >= next_step then
      if core.step() then
        did_redraw = true
        last_frame_start_timestamp = GLOBAL_CURRENT_FRAME_START_TIMESTAMP
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
      if AnimationState:is_active() or not did_step or run_threads_full < 2 then
        local now = system.get_time()
        if not next_step then -- compute the time until the next blink
          local t = now - core.blink_start
          
          local dt = math.ceil(t / HALF_BLINK_PERIOD) * HALF_BLINK_PERIOD - t
          local cursor_time_to_wake = dt + 1 / GLOBAL_CONSTANT_FRAMES_PER_SECOND
          next_step = now + cursor_time_to_wake
        end
        if system.wait_event(math.min(next_step - now, time_to_wake)) then
          next_step = nil -- if we've recevied an event, perform a step
        end
      else
        system.wait_event()
        next_step = nil -- perform a step when we're not in focus if get we an event
      end
    else 
      -- if we redrew, then make sure we only draw at most FPS/sec
      run_threads_full = 0
      local now = system.get_time()
      local time_elapsed = now - GLOBAL_CURRENT_FRAME_START_TIMESTAMP

      -- calculate time until next frame
      local next_frame = math.max(0, 1 / GLOBAL_CONSTANT_FRAMES_PER_SECOND - time_elapsed)
      next_step = next_step or (now + next_frame)

      -- sleep until next frame
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
