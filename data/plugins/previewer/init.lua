-- -- mod-version:3
-- local core = require "core"
-- local common = require "core.common"
-- local config = require "core.config"
-- local command = require "core.command"
-- local Doc = require "core.doc"
-- local CommandView = require "core.commandview"
-- local EmptyView = require "core.emptyview"

-- local PreviewView = require "plugins.previewer.PreviewView"
-- local PreviewDoc = require "plugins.previewer.PreviewDoc"

-- local Previewer = {}
-- Previewer.active = false

-- config.plugins.previewer = table.merge({
--   simplified = true,
--   max_size = 1000000, -- ~1MB
--   only_opened = false,
--   ignore_ext = {
--     "png",
--     "jpg",
--     "exe",
--     "bin",
--     "db",
--     "so",
--     "o",
--     "a",
--     "pdf",
--     "doc",
--     "docx",
--     "xsl",
--     "xlsx",
--   },
--   ignore_bin = {
--     elf = { 0x7f, 0x45, 0x4c, 0x46, 0x02, 0x01, 0x01, 0x00 },
--   },
-- }, config.plugins.previewer)


-- local active_node = nil
-- local active_view = nil
-- local tmp_view = nil
-- local preview_fn = nil
-- local docs = {}

-- local function contains(array, value, case_sensitive)
--   if not value then return nil end

--   local l_value = string.lower(value)
--   if case_sensitive then
--     l_value = value
--   end
--   for i, v in ipairs(array) do
--     if v == l_value then
--       return i
--     end
--   end
--   return nil
-- end

-- function Previewer.file_previewer(suggestion)
--   if suggestion then
--     local path = suggestion.text
--     if docs[path] then
--       return docs[path]
--     elseif not config.plugins.previewer.only_opened then
--       local filename = core.normalize_to_project_dir(path)
--       local ext = filename:match('%.([^.]+)$')
--       if not contains(config.plugins.previewer.ignore_ext, ext) then
--         local abs_filename = core.project_absolute_path(filename)
--         local info = system.get_file_info(abs_filename)
--         if info and info.type == "file" and info.size < config.plugins.previewer.max_size then
--           local file = io.open(abs_filename, "rb")
--           if file then
--             local read = {}
--             for _, header in pairs(config.plugins.previewer.ignore_bin) do
--               if #header <= info.size then
--                 while #read < #header do
--                   table.insert(read, string.byte(file:read(1)))
--                 end
--                 local same = true
--                 for i = 1, #header do
--                   if read[i] ~= header[i] then
--                     same = false
--                     break
--                   end
--                 end
--                 if same then
--                   file:close()
--                   return nil
--                 end
--               end
--               file:close()
--             end
--           end
--           local doc = nil
--           if config.plugins.previewer.simplified then
--             doc = PreviewDoc(filename, abs_filename, false)
--           else
--             doc = Doc(filename, abs_filename, false)
--           end
--           docs[path] = doc
--           return doc
--         end
--       end
--     end
--   end
--   return nil
-- end

-- local function default_preview_fn(suggestion)
--   if suggestion and type(suggestion) == "table" then
--     return suggestion.doc
--   end
--   return nil
-- end

-- function Previewer.close_preview()
--   if Previewer.active then
--     if active_node and tmp_view then
--       active_node:close_view(core.root_view.root_node, tmp_view)
--       if active_view and not active_view:is(EmptyView) then
--         active_node:set_active_view(active_view)
--       else
--         active_node:set_active_view(EmptyView())
--       end
--       tmp_view = nil
--       active_node = nil
--       active_view = nil
--       preview_fn = nil
--     end
--     Previewer.active = false
--   end
-- end

-- -- local cv_enter__orig = CommandView.enter
-- function CommandView:enter_with_preview(label, ...)
--   local options = select(1, ...)
--   active_node = core.root_view:get_active_node()
--   active_view = core.active_view
--   preview_fn = options.preview
--   if preview_fn == nil then
--     preview_fn = default_preview_fn
--   else
--     options.extract = nil
--   end
--   docs = {}
--   for _, doc in ipairs(core.docs) do
--     if doc.filename then
--       docs[doc.filename] = doc
--     end
--   end
--   Previewer.active = true
--   self:enter(label, options)
-- end

-- local cv_exit__orig = CommandView.exit
-- function CommandView:exit(submitted, inexplicit)
--   Previewer.close_preview()
--   cv_exit__orig(self, submitted, inexplicit)
-- end

-- local cv_update__orig = CommandView.update
-- function CommandView:update()
--   cv_update__orig(self)
--   if Previewer.active and active_node ~= nil and preview_fn then
--     local sugg = self.suggestions[self.suggestion_idx]
--     local doc = preview_fn(sugg)
--     if doc ~= nil then
--       if tmp_view == nil then
--         tmp_view = PreviewView(doc)
--         active_node:add_view(tmp_view)
--         core.set_active_view(self)
--       elseif tmp_view.doc ~= doc then
--         tmp_view.doc = doc
--       end
--     end
--   end
-- end

-- command.add(
--   nil,
--   {
--     ["core:find-file"] = function()
--       if not core.project_files_number() then
--         return command.perform "core:open-file"
--       end
--       local files = {}
--       for dir, item in core.get_project_files() do
--         if item.type == "file" then
--           local path = (dir == core.project_dir and "" or dir .. PATHSEP)
--           table.insert(files, common.home_encode(path .. item.filename))
--         end
--       end
--       core.command_view:enter_with_preview("Open File From Project", {
--         submit = function(text, item)
--           text = item and item.text or text
--           core.root_view:open_doc(core.open_doc(common.home_expand(text)))
--         end,
--         suggest = function(text)
--           return common.fuzzy_match_with_recents(files, core.visited_files, text)
--         end,
--         preview = Previewer.file_previewer,
--       })
--     end,
--     ["core:open-file"] = function()
--       local view = core.active_view
--       local text
--       if view.doc and view.doc.abs_filename then
--         local dirname, filename = view.doc.abs_filename:match("(.*)[/\\](.+)$")
--         if dirname then
--           dirname = core.normalize_to_project_dir(dirname)
--           text = dirname == core.project_dir and "" or common.home_encode(dirname) .. PATHSEP
--         end
--       end
--       core.command_view:enter_with_preview("Open File", {
--         text = text,
--         submit = function(text)
--           local filename = system.absolute_path(common.home_expand(text))
--           core.root_view:open_doc(core.open_doc(filename))
--         end,
--         suggest = function(text)
--           return common.home_encode_list(common.path_suggest(common.home_expand(text)))
--         end,
--         validate = function(text)
--           local filename = common.home_expand(text)
--           local path_stat, err = system.get_file_info(filename)
--           if err then
--             if err:find("No such file", 1, true) then
--               -- check if the containing directory exists
--               local dirname = common.dirname(filename)
--               local dir_stat = dirname and system.get_file_info(dirname)
--               if not dirname or (dir_stat and dir_stat.type == 'dir') then
--                 return true
--               end
--             end
--             stderr.error("Cannot open file %s: %s", text, err)
--           elseif path_stat.type == 'dir' then
--             stderr.error("Cannot open %s, is a folder", text)
--           else
--             return true
--           end
--         end,
--         preview = Previewer.file_previewer,
--       })
--     end,

--   }
-- )

-- return Previewer
