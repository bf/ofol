--
-- Source Control Management plugin.
-- @copyright Jefferson Gonzalez <jgmdev@gmail.com>
-- @license MIT
--
-- Note: Some ideas and bits taken from:
-- https://github.com/vincens2005/lite-xl-gitdiff-highlight
-- https://github.com/lite-xl/lite-xl-plugins/blob/master/plugins/gitstatus.lua
-- Thanks to everyone involved!
local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local style = require "themes.style"
local Doc = require "models.doc"

local StatusView = require "core.views.statusview"
local DocView = require "core.views.docview"

local util = require ".util"
local changes = require ".changes"
local ReadDoc = require ".readdoc"
local Git = require ".backend.git"
local Fossil = require ".backend.fossil"

local MessageBox = require "lib.widget.messagebox"

local FileMetadataStore = require "stores.file_metadata_store"


---@class settings_source_code_management
---@field highlighter boolean
---@field highlighter_alignment "right" | "left"
local settings_source_code_management = {
  highlighter = true,
  highlighter_alignment = "right",
}

---@class plugins.scm.filechange : plugins.scm.backend.filechange
---@field color renderer.color?
---@field text string?

---@class plugins.scm
local scm = {}

---Backends shipped with the plugin.
---@type plugins.scm.backend[]
local BACKENDS = { Git(), Fossil() }

---List of loaded projects current branch.
---@type table<string, string>
local BRANCHES = {}

---List of loaded projects current stats.
---@type table<string, plugins.scm.backend.stats>
local STATS = {}

---List of loaded project changes.
---@type table<string,table<string,plugins.scm.filechange>>
local CHANGES = {}

---Opened projects SCM backends list
---@type table<string,plugins.scm.backend>
local PROJECTS = {}
setmetatable(PROJECTS, {
  __index = function(t, k)
    if k == nil then return nil end
    local v = rawget(t, k)
    if v == nil then
      for _, backend in ipairs(BACKENDS) do
        if backend:detect(k) then
          v = backend
          backend:get_branch(k, function(branch)
            BRANCHES[k] = branch
            backend:get_stats(k, function(stats) STATS[k] = stats end)
          end)
          rawset(t, k, v)
        end
      end
    end
    return v
  end
})

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------
---@param doc core.doc
local function update_doc_diff(doc)
  if doc.abs_filename then
    local project_dir = util.get_file_project_dir(doc.abs_filename)
    if project_dir and PROJECTS[project_dir] then
      local backend = PROJECTS[project_dir]
      backend:get_file_diff(doc.abs_filename, project_dir, function(diff)
        if diff and diff ~= "" then
          local parsed_diff = changes.parse(diff)
          doc.scm_diff = nil
          for _, _ in pairs(parsed_diff) do
            doc.scm_diff = parsed_diff
            break
          end
        else
          doc.scm_diff = nil
        end
      end)
      return
    end
  end
  doc.scm_diff = nil
end

---@param path string
---@param nonblocking? boolean
local function update_doc_status(path, nonblocking)
  local project_dir = util.get_file_project_dir(path)
  local backend = PROJECTS[project_dir]
  if backend then
    if not nonblocking then backend:set_blocking_mode(true) end
    backend:get_file_status(path, project_dir, function(status)
      if status and status ~= "" then
        local color
        if status == "added" then
          color = style.good
        elseif status == "edited" then
          color = style.warn
        elseif status == "renamed" then
          color = style.warn
        elseif status == "deleted" then
          color = style.error
        elseif status == "untracked" then
          color = style.dim
        end
        if color then
          if not CHANGES[project_dir] then CHANGES[project_dir] = {} end
          CHANGES[project_dir][path] = {
            path = path,
            color = color,
            status = status
          }
        else
          if CHANGES[project_dir] and CHANGES[project_dir][path] then
            CHANGES[project_dir][path] = nil
          end
        end
      end
    end)
    if not nonblocking then backend:set_blocking_mode(true) end
  end
end

--------------------------------------------------------------------------------
-- Source Control Management API
--------------------------------------------------------------------------------
---Get a file branch or current project branch if no file given.
---@param abs_filename? string
---@return string?
function scm.get_branch(abs_filename)
  local project = util.get_project_dir(abs_filename)
  return BRANCHES[project]
end

---Get current project insert and delete stats.
---@return plugins.scm.backend.stats?
function scm.get_stats()
  local project = util.get_current_project()
  return STATS[project]
end

---Get current project scm backend
---@return plugins.scm.backend?
function scm.get_backend()
  local project = util.get_current_project()
  return PROJECTS[project]
end

---@param path string
---@param is_changed? boolean Only get backend if file has changed
---@param is_tracked? boolean Only get backend if file is tracked
---@return plugins.scm.backend?
function scm.get_path_backend(path, is_changed, is_tracked)
  local project_dir = util.get_project_dir(path)
  if project_dir then
    if is_changed then
      if CHANGES[project_dir] and CHANGES[project_dir][path] then
        if is_tracked then
          if
            CHANGES[project_dir][path].status
            and
            CHANGES[project_dir][path].status == "untracked"
          then
            return nil
          end
        end
        return PROJECTS[project_dir]
      end
    else
      local backend = PROJECTS[project_dir]
      if is_tracked and backend then
        ---@type plugins.scm.backend.filestatus
        local status
        backend:set_blocking_mode(true)
        backend:get_file_status(path, project_dir, function(file_status)
          status = file_status
        end)
        backend:set_blocking_mode(false)
        if status == "untracked" then return nil end
      end
      return backend
    end
  end
  return nil
end

---@return plugins.scm.backend.filestatus
function scm.get_path_status(path)
  local backend = scm.get_path_backend(path)
  local project_dir = util.get_project_dir(path)
  if backend and project_dir then
    local status
    backend:set_blocking_mode(true)
    backend:get_file_status(path, project_dir, function(file_status)
      status = file_status
    end)
    backend:set_blocking_mode(false)
    return status
  end
  return "untracked"
end

---@return plugins.scm.filechange?
function scm.get_path_changes(path)
  local project_dir = util.get_project_dir(path)
  if CHANGES[project_dir] and CHANGES[project_dir][path] then
    return CHANGES[project_dir] and CHANGES[project_dir][path]
  end
  return nil
end

---@return boolean
function scm.is_staged(path)
  local backend = scm.get_path_backend(path)
  local project_dir = util.get_project_dir(path)
  if backend and project_dir then
    if CHANGES[project_dir] and CHANGES[project_dir][path] then
      if
        CHANGES[project_dir][path].path
        and
        CHANGES[project_dir][path].new_path
        and
        not system.get_file_info(CHANGES[project_dir][path].path)
        and
        system.get_file_info(CHANGES[project_dir][path].new_path)
      then
        path = CHANGES[project_dir][path].new_path
      else
        return CHANGES[project_dir][path].staged
      end
    end
    local staged_files
    local path_rel = fsutils.relative_path(project_dir, path)
    backend:set_blocking_mode(true)
    backend:get_staged(project_dir, function(files)
      staged_files = files
    end)
    backend:set_blocking_mode(false)
    if staged_files[path_rel] then return true end
  end
  return false
end

---Check if the given project path is source control managed.
---@param path string
---@return boolean
function scm.is_scm_project(path)
  for _, project in ipairs(core.project_directories) do
    if path == project.name and PROJECTS[path] then
      return true
    end
  end
  return false
end

---Add a new SCM backend.
---@param backend plugins.scm.backend
function scm.register_backend(backend)
  table.insert(BACKENDS, backend)
end

---Remove an existing SCM backend.
---@param name string
function scm.unregister_backend(name)
  for i, backend in ipairs(BACKENDS) do
    if backend.name == name then
      table.remove(BACKENDS, i)
      break
    end
  end
end

---@param project_dir? string
function scm.open_diff(project_dir)
  project_dir = project_dir or util.get_current_project()
  local backend = PROJECTS[project_dir]
  if backend then
    backend:get_diff(project_dir, function(diff)
      if diff and diff ~= "" then
        local title = "[CHANGES].diff"
          ---@type plugins.scm.readdoc
          local diffdoc = ReadDoc(title, title)
          diffdoc:set_text(diff)
          core.root_view:open_doc(diffdoc)
      else
        stderr.warn("SCM: no changes detected.")
      end
    end)
  else
    stderr.warn("SCM: current project directory is not versioned.")
  end
end

function scm.open_path_diff(path)
  local project_dir = util.get_project_dir(path)
  local backend = PROJECTS[project_dir]
  if backend then
    local path_rel = fsutils.relative_path(project_dir, path)
    backend:get_file_diff(path, project_dir, function(diff)
      if diff and diff ~= "" then
        local title = string.format("%s.diff", path_rel)
        ---@type plugins.scm.readdoc
        local diffdoc = ReadDoc(title, title)
        diffdoc:set_text(diff)
        core.root_view:open_doc(diffdoc)
      else
        local info = system.get_file_info(path)
        if info and info.type == "file" then
          stderr.warn("SCM: seems like the file is untracked.")
        else
          stderr.warn("SCM: seems like the path only contains untracked files.")
        end
      end
    end)
  end
end

---@param project_dir? string
function scm.open_project_status(project_dir)
  project_dir = project_dir or util.get_current_project()
  local backend = PROJECTS[project_dir]
  if backend then
    backend:get_status(project_dir, function(status)
      if status and status ~= "" then
        local title = "Project Status"
          ---@type plugins.scm.readdoc
          local doc = ReadDoc(title, title)
          doc:set_text(status)
          core.root_view:open_doc(doc)
      else
        stderr.warn("SCM: no status to report.")
      end
    end)
  else
    stderr.warn("SCM: current project directory is not versioned.")
  end
end

---@param project_dir string
function scm.pull(project_dir)
  local backend = PROJECTS[project_dir]
  if backend then
    backend:pull(project_dir, function(success, errmsg)
      if success then
        stderr.info("SCM: pulled latest changes for '%s'", project_dir)
      else
        stderr.error("SCM: failed to pull '%s', %s", project_dir, errmsg)
      end
    end)
  end
end

---@param path string
function scm.revert_file(path)
  local project_dir = util.get_project_dir(path)
  local backend = PROJECTS[project_dir]
  if project_dir and backend then
    local path_rel = fsutils.relative_path(project_dir, path)
    MessageBox.warning(
      "SCM Restore File",
      {
        "Do you really want to revert local changes?\n\n",
        "File: " .. path_rel
      },
      function(_, button_id)
        if button_id == 1 then
          backend:revert_file(path, project_dir, function(success, errmsg)
            if success then
              stderr.info("SCM: file '%s' changes reverted", path_rel)
              update_doc_status(path)
              util.reload_doc(path)
            else
              stderr.error("SCM: failed reverting '%s', %s", path_rel, errmsg)
            end
          end)
        end
      end,
      MessageBox.BUTTONS_YES_NO
    )
  end
end

---@param path string
function scm.add_path(path)
  local project_dir = util.get_project_dir(path)
  local backend = PROJECTS[project_dir]
  if project_dir and backend then
    local path_rel = fsutils.relative_path(project_dir, path)
    backend:add_path(path, project_dir, function(success, errmsg)
      if success then
        stderr.info("SCM: file '%s' added", path_rel)
        update_doc_status(path)
      else
        stderr.error("SCM: failed adding '%s', %s", path_rel, errmsg)
      end
    end)
  end
end

---@param path string
function scm.remove_path(path)
  local project_dir = util.get_project_dir(path)
  local backend = PROJECTS[project_dir]
  if project_dir and backend then
    local path_rel = fsutils.relative_path(project_dir, path)
    backend:remove_path(path, project_dir, function(success, errmsg)
      if success then
        stderr.info("SCM: file '%s' removed", path_rel)
        update_doc_status(path)
      else
        stderr.error("SCM: failed removing '%s', %s", path_rel, errmsg)
      end
    end)
  end
end

---@field from string
---@field to string
---@field callback fun(oldname:string, newname:string):any
function scm.move_path(from, to, callback)
  local project_dir = util.get_project_dir(from)
  local backend = PROJECTS[project_dir]
  local moved = false
  if
    backend and fsutils.path_belongs_to(from, project_dir)
    and
    fsutils.path_belongs_to(to, project_dir)
  then
    local from_rel = fsutils.relative_path(project_dir, from)
    local to_rel = fsutils.relative_path(project_dir, to)
    backend:set_blocking_mode(true)
    backend:move_path(from, to, project_dir, function(success, errmsg)
      if success then
        stderr.info("SCM: file '%s' moved to '%s'", from_rel, to_rel)
        update_doc_status(to, true)
      else
        stderr.error(
          "SCM: failed moving '%s' to '%s' with: %s",
          from_rel, to_rel, errmsg
        )
      end
    end)
    backend:set_blocking_mode(false)
  end
  if system.get_file_info(to) then
    return true
  end
  return callback(from, to)
end

---@param path string
function scm.stage_file(path)
  local project_dir = util.get_project_dir(path)
  local backend = PROJECTS[project_dir]
  if project_dir and backend and backend:has_staging() then
    local path_rel = fsutils.relative_path(project_dir, path)
    backend:stage_file(path, project_dir, function(success, errmsg)
      if success then
        stderr.info("SCM: file '%s' staged", path_rel)
        update_doc_status(path)
      else
        stderr.error("SCM: failed staging '%s', %s", path_rel, errmsg)
      end
    end)
  end
end

---@param path string
function scm.unstage_file(path)
  local project_dir = util.get_project_dir(path)
  local backend = PROJECTS[project_dir]
  if project_dir and backend and backend:has_staging() then
    local path_rel = fsutils.relative_path(project_dir, path)
    backend:unstage_file(path, project_dir, function(success, errmsg)
      if success then
        stderr.info("SCM: file '%s' unstaged", path_rel)
        update_doc_status(path)
      else
        stderr.error("SCM: failed unstaging '%s', %s", path_rel, errmsg)
      end
    end)
  end
end

---Go to next change in a file.
function scm.next_change(doc)
  doc = doc or util.get_current_doc()
	if not doc or not doc.scm_diff then return end
	local line, col = doc:get_selection()

	while doc.scm_diff[line] do
		line = line + 1
	end

	while line < #doc.lines do
		if doc.scm_diff[line] then
			doc:set_selection(line, col, line, col)
			return
		end
		line = line + 1
	end
end

---Go to previous change in a file.
function scm.previous_change(doc)
	doc = doc or util.get_current_doc()
	if not doc or not doc.scm_diff then return end
	local line, col = doc:get_selection()

	while doc.scm_diff[line] do
		line = line - 1
	end

	while line > 0 do
		if doc.scm_diff[line] then
			doc:set_selection(line, col, line, col)
			return
		end
		line = line - 1
	end
end

---Update the SCM status of all open projects.
function scm.update()
  for project_dir, project_backend in pairs(PROJECTS) do
    project_backend:get_branch(project_dir, function(branch, cached)
      if not cached then BRANCHES[project_dir] = branch end

      project_backend:get_stats(project_dir, function(stats, cached)
        if not cached then STATS[project_dir] = stats end

        project_backend:get_changes(project_dir, function(filechanges, cached)
          if cached then return end
          local changed_files = {}
          for i, change in ipairs(filechanges) do
            local color = style.modified
            if change.status == "added" then
              color = style.good
            elseif change.status == "edited" then
              color = style.warn
            elseif change.status == "renamed" then
              color = style.warn
            elseif change.status == "deleted" then
              color = style.error
            elseif change.status == "untracked" then
              color = style.dim
            end
            change.color = color
            local path = ""
            if change.new_path then
              change.text = fsutils.basename(change.path)
                .. " -> "
                .. fsutils.basename(change.new_path)
              changed_files[change.new_path] = change
              path = fsutils.dirname(change.new_path)
            else
              changed_files[change.path] = change
              path = fsutils.dirname(change.path)
            end
            while path do
              if #path < #project_dir then break end
              changed_files[path] = { color = style.modified }
              path = fsutils.dirname(path)
            end

            -- update metadata
            FileMetadataStore.set_status_from_version_control(change.path, change.status)

            if i % 10 == 0 then
              coroutine.yield()
            end
          end
          CHANGES[project_dir] = changed_files
        end)
      end)
    end)
  end
end

--------------------------------------------------------------------------------
-- Keep the project branch, changes and stats updated
--------------------------------------------------------------------------------
threading.add_thread(function()
  while true do
    scm.update()
    coroutine.yield(1)
  end
end)

--------------------------------------------------------------------------------
-- Override Doc to register diff changes
--------------------------------------------------------------------------------
local doc_save = Doc.save
function Doc:save(...) doc_save(self, ...) update_doc_diff(self) end

local doc_new = Doc.new
function Doc:new(...) doc_new(self, ...) update_doc_diff(self) end

local doc_load = Doc.load
function Doc:load(...) doc_load(self, ...) update_doc_diff(self) end

local doc_raw_insert = Doc.raw_insert
function Doc:raw_insert(line, col, text, undo_stack, time)
  doc_raw_insert(self, line, col, text, undo_stack, time)
  local diffs = self.scm_diff or {}
  if diffs[line] ~= "addition" then
    diffs[line] = "modification"
  end
  local count = line
  for _ in (text .. "\n"):gmatch("(.-)\n") do
    if count ~= line then
      diffs[count] = "addition"
    end
    count = count + 1
  end
  self.scm_diff = diffs
end

local doc_raw_remove = Doc.raw_remove
function Doc:raw_remove(line1, col1, line2, col2, undo_stack, time)
  doc_raw_remove(self, line1, col1, line2, col2, undo_stack, time)
  local diffs = self.scm_diff or {}
  if line1 ~= line2 then
    local minline = math.min(line1, line2)
    local maxline = math.max(line1, line2)
    for line = minline+1, maxline do
      diffs[line] = "deletion"
    end
  else
    diffs[line1] = "modification"
  end
  self.scm_diff = diffs
end

--------------------------------------------------------------------------------
-- Override DocView to draw changes on gutter
--------------------------------------------------------------------------------
local DIFF_WIDTH = 3
local docview_draw_line_gutter = DocView.draw_line_gutter
local docview_get_gutter_width = DocView.get_gutter_width
function DocView:draw_line_gutter(line, x, y, width)
  if not self.doc or not self.doc.scm_diff or not settings_source_code_management.highlighter then
    return docview_draw_line_gutter(self, line, x, y, width)
  end

  local lh = self:get_editor_line_height()
  local gw, gpad = docview_get_gutter_width(self)
  local diff_type = self.doc.scm_diff[line]

  local align = settings_source_code_management.highlighter_alignment

  if align == "right" then
    docview_draw_line_gutter(self, line, x, y, gpad and gw - gpad or gw)
  else
    local tox = style.padding.x * DIFF_WIDTH / 12
    docview_draw_line_gutter(self, line, x + tox, y, gpad and gw - gpad or gw)
  end

  if diff_type == nil then return end

  local color = style.good
  if diff_type == "deletion" then
    color = style.error
  elseif diff_type == "modification" then
    color = style.warn
  end

  local colw = self:get_font():get_width(#self.doc.lines)

  -- add margin in between highlight and text
  if align == "right" then
    if colw + style.padding.x * 2 >= gw then
      x = x + style.padding.x * 1.5 + colw
    else
      x = x + gw - style.padding.x * 2 + (style.padding.x * DIFF_WIDTH / 12)
    end
  else
    local spacing = (style.padding.x * DIFF_WIDTH / 12)
    if colw + style.padding.x * 2 >= gw then
      x = x + gw + spacing - colw - gpad
    else
      x = x + math.max(gw, colw) - (colw) - math.min(colw, gw) - spacing
    end
  end

  local yoffset = self:get_line_text_y_offset()
  if diff_type ~= "deletion" then
    renderer.draw_rect(x, y + yoffset, DIFF_WIDTH, self:get_editor_line_height(), color)
    return
  end
  renderer.draw_rect(x - DIFF_WIDTH * 2, y + yoffset, DIFF_WIDTH * 4, 2, color)
  return lh
end

function DocView:get_gutter_width()
  if not self.doc or not self.doc.scm_diff or not settings_source_code_management.highlighter then
    return docview_get_gutter_width(self)
  end
  return docview_get_gutter_width(self)
    + style.padding.x * DIFF_WIDTH / 12
end

--------------------------------------------------------------------------------
-- Override rename to execute it on the SCM
--------------------------------------------------------------------------------
local os_rename = os.rename
function os.rename(oldname, newname)
  return scm.move_path(oldname, newname, os_rename)
end



--------------------------------------------------------------------------------
-- StatusBar Item to show current branch and stats
--------------------------------------------------------------------------------
local scm_status_item = core.status_view:add_item({
  name = "status:scm",
  alignment = StatusView.Item.LEFT,
  predicate = DocView,
  --  function () 
  --   -- show only when document is opened
  --   if get_active_docview() then
  --     return true
  --   else 
  --     return false
  --   end

  --   -- return core.active_view:is(DocView) and not core.active_view:is(CommandView)
  -- end,
  get_item = function()
    local project = util.get_current_project()

    if
      not PROJECTS[project]
      or
      not BRANCHES[project] or not STATS[project]
    then
      return {}
    end

    local bcolor = (STATS[project].inserts ~= 0 or STATS[project].deletes ~= 0)
      and style.accent or style.dim
    local icolor = STATS[project].inserts ~= 0 and style.accent or style.dim
    local dcolor = STATS[project].deletes ~= 0 and style.accent or style.dim

    return {
      bcolor, BRANCHES[project],
      style.dim, "  ",
      icolor, "+", STATS[project].inserts,
      style.dim, " / ",
      dcolor, "-", STATS[project].deletes,
    }
  end,
  position = -1,
  tooltip = "current branch",
  separator = core.status_view.separator2
})

scm_status_item.on_click = function(button)
  if button == "right" then
    command.perform "scm:global-diff"
  else
    core.command_view:set_text("Scm: ")
    command.perform "core:find-command"
  end
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------
command.add(
  function()
    local valid = false
    local project_dir = nil
    local av = core.active_view
    if av and av.doc and av.doc.abs_filename then
      project_dir = util.get_project_dir(av.doc.abs_filename)
      if project_dir and PROJECTS[project_dir] then valid = true end
    end
    if not valid and PROJECTS[core.project_dir] then
      valid, project_dir = true, core.project_dir
    end
    return valid, project_dir
  end, {

  ["scm:global-diff"] = function(project_dir)
    scm.open_diff(project_dir)
  end,

  ["scm:project-status"] = function(project_dir)
    scm.open_project_status(project_dir)
  end
})

command.add(
  function()
    local doc = util.get_current_doc()
    return doc
      and scm.get_path_backend(doc.abs_filename)
      and scm.get_path_status(doc.abs_filename) == "untracked"
      , doc
  end, {

  ["scm:file-add"] = function(doc)
    scm.add_path(doc.abs_filename)
	end
})

command.add(
  function()
    local doc = util.get_current_doc()
    return doc
      and scm.get_path_status(doc.abs_filename) == "unchanged"
      , doc
  end, {

  ["scm:file-remove"] = function(doc)
    scm.remove_path(doc.abs_filename)
  end
})

command.add(
  function()
    local doc = util.get_current_doc()
    if doc then
      local path = doc.abs_filename
      local status = scm.get_path_status(path)
      if status == "edited" and not scm.is_staged(path) then
        local backend = scm.get_path_backend(path)
        if backend and backend:has_staging() then
          return true, doc
        end
      end
    end
    return false
  end, {

  ["scm:staging-add"] = function(doc)
    scm.stage_file(doc.abs_filename)
  end
})

command.add(
  function()
    local doc = util.get_current_doc()
    if doc then
      local backend = scm.get_path_backend(doc.abs_filename)
      if backend and backend:has_staging() then
        if scm.is_staged(doc.abs_filename) then
          return true, doc
        end
      end
    end
    return false
  end, {

  ["scm:staging-remove"] = function(doc)
    scm.unstage_file(doc.abs_filename)
  end
})

command.add(
  function()
    local doc = util.get_current_doc()
    if doc then
      local path = doc.abs_filename
      local status = scm.get_path_status(path)
      local backend = scm.get_path_backend(path)
      if backend and backend:has_staging() then
        if status == "edited" and not scm.is_staged(path) then
          return true
        end
      elseif backend then
        return scm.get_path_backend(doc.abs_filename, true, true), doc
      end
    end
    return false
  end, {

  ["scm:file-revert"] = function(doc)
    scm.revert_file(doc.abs_filename)
  end,
})

command.add(
  function()
    local doc = util.get_current_doc()
    return doc
      and scm.get_path_status(doc.abs_filename) == "edited"
      and not scm.is_staged(doc.abs_filename)
      , doc
  end, {

  ["scm:file-diff"] = function(doc)
    scm.open_path_diff(doc.abs_filename)
  end
})

command.add(
  function()
    local doc = util.get_current_doc()
    if doc then
      local project_dir = util.get_file_project_dir(doc.abs_filename)
      if
        CHANGES[project_dir] and CHANGES[project_dir][doc.abs_filename]
        and
        doc.scm_diff
      then
        return true, doc
      end
    end
    return false
  end, {

	["scm:goto-previous-change"] = function(doc)
		scm.previous_change(doc)
	end,

	["scm:goto-next-change"] = function(doc)
		scm.next_change(doc)
	end,
})

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------
keymap.add {
  ["ctrl+alt+["]    = "scm:goto-previous-change",
  ["ctrl+alt+]"]  = "scm:goto-next-change"
}

--------------------------------------------------------------------------------
-- Load TreeView support if the plugin is enabled
--------------------------------------------------------------------------------

local TreeView = require "core.views.treeview"

-- hook treeview function
function TreeView:get_item_special_state_from_source_code_management (item) 
  -- use absolute filename to get scm status
  local changes = scm.get_path_changes(item.abs_filename)

  if changes then
    -- stderr.debug("get_item_special_state_from_source_code_management %s => %s", item.abs_filename, changes.status)
    return changes.status
  end

  return nil
end


return scm
