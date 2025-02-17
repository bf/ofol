local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

local json = require "lib.json"


local fullscreen = false

local function suggest_directory(text)
  text = fsutils.home_expand(text)
  local basedir = fsutils.dirname(core.project_dir)
  return fsutils.home_encode_list((basedir and text == basedir .. PATHSEP or text == "") and
    core.recent_projects or fsutils.dir_path_suggest(text))
end

local function check_directory_path(path)
    local abs_path = system.absolute_path(path)
    local info = abs_path and system.get_file_info(abs_path)
    if not info or info.type ~= 'dir' then
      return nil
    end
    return abs_path
end

command.add(nil, {
  ["core:quit"] = function()
    core.quit()
  end,

  ["core:restart"] = function()
    core.restart()
  end,

  ["core:toggle-fullscreen"] = function()
    fullscreen = not fullscreen
    system.set_window_mode(core.window, fullscreen and "fullscreen" or "normal")
  end,


  ["core:reload-module"] = function()
    core.command_view:enter("Reload Module", {
      submit = function(text, item)
        local text = item and item.text or text
        core.reload_module(text)
        stderr.info("Reloaded module %q", text)
      end,
      suggest = function(text)
        local items = {}
        for name in pairs(package.loaded) do
          table.insert(items, name)
        end
        return table.fuzzy_match(items, text)
      end
    })
  end,

  ["core:find-command"] = function()
    local commands = command.get_all_valid()
    core.command_view:enter("Do Command", {
      submit = function(text, item)
        if item then
          command.perform(item.command)
        end
      end,
      suggest = function(text)
        local res = table.fuzzy_match(commands, text)
        for i, name in ipairs(res) do
          res[i] = {
            text = command.prettify_name(name),
            info = keymap.get_binding(name),
            command = name,
          }
        end
        return res
      end
    })
  end,

  ["core:find-file"] = function()
    if not core.project_files_number() then
      return command.perform "core:open-file"
    end
    local files = {}
    for dir, item in core.get_project_files() do
      if item.type == "file" then
        local path = (dir == core.project_dir and "" or dir .. PATHSEP)
        table.insert(files, fsutils.home_encode(path .. item.filename))
      end
    end
    core.command_view:enter("Open File From Project", {
      submit = function(text, item)
        text = item and item.text or text
        core.root_view:open_doc(core.open_doc(fsutils.home_expand(text)))
      end,
      suggest = function(text)
        return table.fuzzy_match_with_recents(files, core.visited_files, text)
      end
    })
  end,

  ["core:new-doc"] = function()
    core.root_view:open_doc(core.open_doc())
  end,

  ["core:new-named-doc"] = function()
    core.command_view:enter("File name", {
      submit = function(text)
        core.root_view:open_doc(core.open_doc(text))
      end
    })
  end,

  ["core:open-file"] = function()
    local view = core.active_view
    local text
    local current_file
    if view.doc and view.doc.abs_filename then
      current_file = view.doc.abs_filename
      local dirname, filename = view.doc.abs_filename:match("(.*)[/\\](.+)$")
      if dirname then
        dirname = core.normalize_to_project_dir(dirname)
        text = dirname == core.project_dir and "" or fsutils.home_encode(dirname) .. PATHSEP
      end
    end
    core.command_view:enter("Open File", {
      text = text,
      submit = function(text)
        stderr.debug("[open file] [submit]", #text, text)
        -- check for goto line command
        local filename, go_to_line_number = text:match("^([^:]*):([1-9][0-9]*)")
        
        -- check if line number was provided
        if go_to_line_number then
          -- take current file if no filename given
          if not filename or #filename == 0 then
            filename = current_file
          end

          -- convert to int
          go_to_line_number = tonumber(go_to_line_number)
        else
          -- take whole text as filename, get absolute path
          filename = system.absolute_path(fsutils.home_expand(text))
        end

        core.root_view:open_doc(core.open_doc(filename), go_to_line_number)
      end,
      suggest = function (text)
        -- suggest file
        stderr.debug("[open file] [suggest]", #text, text)
        -- check if user wants to go specific line
        if current_file ~= nil and text:match("^:([1-9][0-9]*)") then
          local path_relative = core.normalize_to_project_dir(current_file)
          local go_to_line_number = tonumber(string.sub(text, 2))
          stderr.debug("[open file] [suggest] go_to_line_number:",  go_to_line_number)

          local message = string.format(":%d (goto line %d in %s)", go_to_line_number, go_to_line_number, path_relative)
          stderr.debug("[open file] [suggest] return value:", message)
          return { message }
        else
          local result = fsutils.home_encode_list(fsutils.path_suggest(fsutils.home_expand(text)))
          stderr.debug("[open file] [suggest] result:", json.encode(result))
          return result
        end
      end,

      validate = function(text)
          local filename = fsutils.home_expand(text)
          local path_stat, err = system.get_file_info(filename)
          if err then
            if err:find("No such file", 1, true) then
              -- check if the containing directory exists
              local dirname = fsutils.dirname(filename)
              local dir_stat = dirname and system.get_file_info(dirname)
              if not dirname or (dir_stat and dir_stat.type == 'dir') then
                return true
              end
            end
            stderr.error("Cannot open file %s: %s", text, err)
          elseif path_stat.type == 'dir' then
            stderr.error("Cannot open %s, is a folder", text)
          else
            return true
          end
        end,
    })
  end,

  -- ["core:open-log"] = function()
  --   local node = core.root_view:get_active_node_default()
  --   node:add_view(LogView())
  -- end,

  ["core:change-project-folder"] = function()
    local dirname = fsutils.dirname(core.project_dir)
    local text
    if dirname then
      text = fsutils.home_encode(dirname) .. PATHSEP
    end
    core.command_view:enter("Change Project Folder", {
      text = text,
      submit = function(text)
        local path = fsutils.home_expand(text)
        local abs_path = check_directory_path(path)
        if not abs_path then
          stderr.error("Cannot open directory %q", path)
          return
        end

        -- do nothing if old project equals new project
        if abs_path == core.project_dir then return end

        -- close all open files
        if core.confirm_close_docs() then
          -- open new project
          core.open_folder_project(abs_path)
        end
      end,
      suggest = suggest_directory
    })
  end,

  ["core:open-project-folder"] = function()
    local dirname = fsutils.dirname(core.project_dir)
    local text
    if dirname then
      text = fsutils.home_encode(dirname) .. PATHSEP
    end
    core.command_view:enter("Open Project", {
      text = text,
      submit = function(text)
        local path = fsutils.home_expand(text)
        local abs_path = check_directory_path(path)
        if not abs_path then
          stderr.error("Cannot open directory %q", path)
          return
        end
        if abs_path == core.project_dir then
          stderr.error("Directory %q is currently opened", abs_path)
          return
        end
        system.exec(string.format("%q %q", EXEFILE, abs_path))
      end,
      suggest = suggest_directory
    })
  end,

  ["core:add-directory"] = function()
    core.command_view:enter("Add Directory", {
      submit = function(text)
        text = fsutils.home_expand(text)
        local path_stat, err = system.get_file_info(text)
        if not path_stat then
          stderr.error("cannot open %q: %s", text, err)
          return
        elseif path_stat.type ~= 'dir' then
          stderr.error("%q is not a directory", text)
          return
        end
        core.add_project_directory(system.absolute_path(text))
      end,
      suggest = suggest_directory
    })
  end,

  ["core:remove-directory"] = function()
    local dir_list = {}
    local n = #core.project_directories
    for i = n, 2, -1 do
      dir_list[n - i + 1] = core.project_directories[i].name
    end
    core.command_view:enter("Remove Directory", {
      submit = function(text, item)
        text = fsutils.home_expand(item and item.text or text)
        if not core.remove_project_directory(text) then
          stderr.error("No directory %q to be removed", text)
        end
      end,
      suggest = function(text)
        text = fsutils.home_expand(text)
        return fsutils.home_encode_list(fsutils.dir_list_suggest(text, dir_list))
      end
    })
  end,
})
