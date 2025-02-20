
-- local SingleLineDoc = require "core.doc"

-- ---@class core.commandview.input : core.doc
-- ---@field super core.doc
-- local SingleLineSingleLineDoc = SingleLineDoc:extend()

-- function SingleLineSingleLineDoc:insert(line, col, text)
--   SingleLineSingleLineDoc.super.insert(self, line, col, text:gsub("\n", ""))
-- end

local core = require "core"
local syntax = require "lib.syntax"
local config = require "core.config"

local translate  = require "lib.widget.single_line_document_translate"

-- functions for translating a Doc position to another position these functions
-- can be passed to Doc:move_to|select_to|delete_to()




local SingleLineDoc = Object:extend()


local function split_lines(text)
  local res = {}
  for line in (text .. "\n"):gmatch("(.-)\n") do
    table.insert(res, line)
  end
  return res
end


function SingleLineDoc:new()
  self:reset()
end

function SingleLineDoc:reset()
  self.lines = { "\n" }
  self.selections = { 1, 1, 1, 1 }
  self.last_selection = 1
  self.undo_stack = { idx = 1 }
  self.redo_stack = { idx = 1 }
  self.clean_change_id = 1
  self.overwrite = false

end


function SingleLineDoc:try_close() 
  return true
end


-- get name from document for display
function SingleLineDoc:get_name()
  return self.filename or "unsaved"
end

-- -- undo/redo: returns true if document is dirty (unsaved)
-- function SingleLineDoc:is_dirty()
--   if self.new_file then
--     if self.filename then return true end
--     return #self.lines > 1 or #self.lines[1] > 1
--   else
--     return self.clean_change_id ~= self:get_change_id()
--   end
-- end

-- undo/redo: marks document as clean 
function SingleLineDoc:clean()
  self.clean_change_id = self:get_change_id()
end

-- get tab/spaces indentation info
function SingleLineDoc:get_indent_info()
  if not self.indent_info then return config.tab_type, config.indent_size, false end
  return self.indent_info.type or config.tab_type,
      self.indent_info.size or config.indent_size,
      self.indent_info.confirmed
end

-- undo/redo: get last change id from the undo stack
function SingleLineDoc:get_change_id()
  return self.undo_stack.idx
end

-- text selection: helper to ensure that start/end coordinates of selected text are in deterministic order
local function sort_positions(line1, col1, line2, col2)
  if line1 > line2 or line1 == line2 and col1 > col2 then
    return line2, col2, line1, col1, true
  end
  return line1, col1, line2, col2, false
end

-- Cursor section. Cursor indices are *only* valid during a get_selections() call.
-- Cursors will always be iterated in order from top to bottom. Through normal operation
-- curors can never swap positions; only merge or split, or change their position in cursor
-- order.
function SingleLineDoc:get_selection(sort)
  local line1, col1, line2, col2, swap = self:get_selection_idx(self.last_selection, sort)
  if not line1 then
    line1, col1, line2, col2, swap = self:get_selection_idx(1, sort)
  end
  return line1, col1, line2, col2, swap
end

---Get the selection specified by `idx`
---@param idx integer @the index of the selection to retrieve
---@param sort? boolean @whether to sort the selection returned
---@return integer,integer,integer,integer,boolean? @line1, col1, line2, col2, was the selection sorted
function SingleLineDoc:get_selection_idx(idx, sort)
  local line1, col1, line2, col2 = self.selections[idx * 4 - 3], self.selections[idx * 4 - 2],
      self.selections[idx * 4 - 1],
      self.selections[idx * 4]
  if line1 and sort then
    return sort_positions(line1, col1, line2, col2)
  else
    return line1, col1, line2, col2
  end
end

-- text selection: retrieve selected text
function SingleLineDoc:get_selection_text(limit)
  limit = limit or math.huge
  local result = {}
  for idx, line1, col1, line2, col2 in self:get_selections() do
    if idx > limit then break end
    if line1 ~= line2 or col1 ~= col2 then
      local text = self:get_text(line1, col1, line2, col2)
      if text ~= "" then result[#result + 1] = text end
    end
  end
  return table.concat(result, "\n")
end

-- text selection: return true if doc has selection
function SingleLineDoc:has_selection()
  local line1, col1, line2, col2 = self:get_selection(false)
  return line1 ~= line2 or col1 ~= col2
end

-- text selection: return true if doc has any selection (??)
function SingleLineDoc:has_any_selection()
  for idx, line1, col1, line2, col2 in self:get_selections() do
    if line1 ~= line2 or col1 ~= col2 then return true end
  end
  return false
end

-- text selection: sanitize selection, e.g. combine small ones into larger one
function SingleLineDoc:sanitize_selection()
  for idx, line1, col1, line2, col2 in self:get_selections() do
    self:set_selections(idx, line1, col1, line2, col2)
  end
end

-- text selection: set ??
function SingleLineDoc:set_selections(idx, line1, col1, line2, col2, swap, rm)
  assert(not line2 == not col2, "expected 3 or 5 arguments")
  if swap then line1, col1, line2, col2 = line2, col2, line1, col1 end
  line1, col1 = self:sanitize_position(line1, col1)
  line2, col2 = self:sanitize_position(line2 or line1, col2 or col1)
  table.splice(self.selections, (idx - 1) * 4 + 1, rm == nil and 4 or rm, { line1, col1, line2, col2 })
end

-- text selection: add ??
function SingleLineDoc:add_selection(line1, col1, line2, col2, swap)
  local l1, c1 = sort_positions(line1, col1, line2 or line1, col2 or col1)
  local target = #self.selections / 4 + 1
  for idx, tl1, tc1 in self:get_selections(true) do
    if l1 < tl1 or l1 == tl1 and c1 < tc1 then
      target = idx
      break
    end
  end
  self:set_selections(target, line1, col1, line2, col2, swap, 0)
  self.last_selection = target
end


-- text selection: remove ??
function SingleLineDoc:remove_selection(idx)
  if self.last_selection >= idx then
    self.last_selection = self.last_selection - 1
  end
  table.splice(self.selections, (idx - 1) * 4 + 1, 4)
end

-- text selection: set ??
function SingleLineDoc:set_selection(line1, col1, line2, col2, swap)
  self.selections = {}
  self:set_selections(1, line1, col1, line2, col2, swap)
  self.last_selection = 1
end

-- text selection: merge cursors
function SingleLineDoc:merge_cursors(idx)
  local table_index = idx and (idx - 1) * 4 + 1
  for i = (table_index or (#self.selections - 3)), (table_index or 5), -4 do
    for j = 1, i - 4, 4 do
      if self.selections[i] == self.selections[j] and
          self.selections[i + 1] == self.selections[j + 1] then
        table.splice(self.selections, i, 4)
        if self.last_selection >= (i + 3) / 4 then
          self.last_selection = self.last_selection - 1
        end
        break
      end
    end
  end
end

-- text selection: helper function
local function selection_iterator(invariant, idx)
  local target = invariant[3] and (idx * 4 - 7) or (idx * 4 + 1)
  if target > #invariant[1] or target <= 0 or (type(invariant[3]) == "number" and invariant[3] ~= idx - 1) then return end
  if invariant[2] then
    return idx + (invariant[3] and -1 or 1), sort_positions(table.unpack(invariant[1], target, target + 4))
  else
    return idx + (invariant[3] and -1 or 1), table.unpack(invariant[1], target, target + 4)
  end
end

-- text selection: get all selections
-- If idx_reverse is true, it'll reverse iterate. If nil, or false, regular iterate.
-- If a number, runs for exactly that iteration.
function SingleLineDoc:get_selections(sort_intra, idx_reverse)
  return selection_iterator, { self.selections, sort_intra, idx_reverse },
      idx_reverse == true and ((#self.selections / 4) + 1) or ((idx_reverse or -1) + 1)
end

-- End of cursor seciton.

function SingleLineDoc:sanitize_position(line, col)
  local nlines = #self.lines
  if line > nlines then
    return nlines, #self.lines[nlines]
  elseif line < 1 then
    return 1, 1
  end
  return line, math.clamp(col, 1, #self.lines[line])
end

local function position_offset_func(self, line, col, fn, ...)
  line, col = self:sanitize_position(line, col)
  return fn(self, line, col, ...)
end


local function position_offset_byte(self, line, col, offset)
  line, col = self:sanitize_position(line, col)
  col = col + offset
  while line > 1 and col < 1 do
    line = line - 1
    col = col + #self.lines[line]
  end
  while line < #self.lines and col > #self.lines[line] do
    col = col - #self.lines[line]
    line = line + 1
  end
  return self:sanitize_position(line, col)
end


local function position_offset_linecol(self, line, col, lineoffset, coloffset)
  return self:sanitize_position(line + lineoffset, col + coloffset)
end


function SingleLineDoc:position_offset(line, col, ...)
  if type(...) ~= "number" then
    return position_offset_func(self, line, col, ...)
  elseif select("#", ...) == 1 then
    return position_offset_byte(self, line, col, ...)
  elseif select("#", ...) == 2 then
    return position_offset_linecol(self, line, col, ...)
  else
    error("bad number of arguments")
  end
end

---Returns the content of the doc between two positions. </br>
---The positions will be sanitized and sorted. </br>
---The character at the "end" position is not included by default.
---@see core.doc.sanitize_position
---@param line1 integer
---@param col1 integer
---@param line2 integer
---@param col2 integer
---@param inclusive boolean? Whether or not to return the character at the last position
---@return string
function SingleLineDoc:get_text(line1, col1, line2, col2, inclusive)
  line1, col1 = self:sanitize_position(line1, col1)
  line2, col2 = self:sanitize_position(line2, col2)
  line1, col1, line2, col2 = sort_positions(line1, col1, line2, col2)
  local col2_offset = inclusive and 0 or 1
  if line1 == line2 then
    return self.lines[line1]:sub(col1, col2 - col2_offset)
  end
  local lines = { self.lines[line1]:sub(col1) }
  for i = line1 + 1, line2 - 1 do
    table.insert(lines, self.lines[i])
  end
  table.insert(lines, self.lines[line2]:sub(1, col2 - col2_offset))
  return table.concat(lines)
end

function SingleLineDoc:get_char(line, col)
  line, col = self:sanitize_position(line, col)
  return self.lines[line]:sub(col, col)
end

local function push_undo(undo_stack, time, type, ...)
  undo_stack[undo_stack.idx] = { type = type, time = time, ... }
  undo_stack[undo_stack.idx - config.max_undos] = nil
  undo_stack.idx = undo_stack.idx + 1
end


local function pop_undo(self, undo_stack, redo_stack, modified)
  -- pop command
  local cmd = undo_stack[undo_stack.idx - 1]
  if not cmd then return end
  undo_stack.idx = undo_stack.idx - 1

  -- handle command
  if cmd.type == "insert" then
    local line, col, text = table.unpack(cmd)
    self:raw_insert(line, col, text, redo_stack, cmd.time)
  elseif cmd.type == "remove" then
    local line1, col1, line2, col2 = table.unpack(cmd)
    self:raw_remove(line1, col1, line2, col2, redo_stack, cmd.time)
  elseif cmd.type == "selection" then
    self.selections = { table.unpack(cmd) }
    self:sanitize_selection()
  end

  modified = modified or (cmd.type ~= "selection")

  -- if next undo command is within the merge timeout then treat as a single
  -- command and continue to execute it
  local next = undo_stack[undo_stack.idx - 1]
  if next and math.abs(cmd.time - next.time) < config.undo_merge_timeout then
    return pop_undo(self, undo_stack, redo_stack, modified)
  end

  if modified then
    self:on_text_change("undo")
  end
end

-- For plugins to add custom actions of document change
function SingleLineDoc:on_text_change(type)
end

function SingleLineDoc:raw_insert(line, col, text, undo_stack, time)
  -- split text into lines and merge with line at insertion point
  local lines = split_lines(text)
  local len = #lines[#lines]
  local before = self.lines[line]:sub(1, col - 1)
  local after = self.lines[line]:sub(col)
  for i = 1, #lines - 1 do
    lines[i] = lines[i] .. "\n"
  end
  lines[1] = before .. lines[1]
  lines[#lines] = lines[#lines] .. after

  -- splice lines into line array
  table.splice(self.lines, line, 1, lines)

  -- keep cursors where they should be
  for idx, cline1, ccol1, cline2, ccol2 in self:get_selections(true, true) do
    if cline1 < line then break end
    local line_addition = (line < cline1 or col < ccol1) and #lines - 1 or 0
    local column_addition = line == cline1 and ccol1 > col and len or 0
    self:set_selections(idx, cline1 + line_addition, ccol1 + column_addition, cline2 + line_addition,
      ccol2 + column_addition)
  end

  -- push undo
  local line2, col2 = self:position_offset(line, col, #text)
  push_undo(undo_stack, time, "selection", table.unpack(self.selections))
  push_undo(undo_stack, time, "remove", line, col, line2, col2)

  -- update highlighter and assure selection is in bounds
  -- self.highlighter:insert_notify(line, #lines - 1)
  local blanks = { }
  for i = 1, #lines - 1 do
    blanks[i] = false
  end
  table.splice(self.lines, line, 0, blanks)

  self:sanitize_selection()
end

function SingleLineDoc:raw_remove(line1, col1, line2, col2, undo_stack, time)
  -- push undo
  local text = self:get_text(line1, col1, line2, col2)
  push_undo(undo_stack, time, "selection", table.unpack(self.selections))
  push_undo(undo_stack, time, "insert", line1, col1, text)

  -- get line content before/after removed text
  local before = self.lines[line1]:sub(1, col1 - 1)
  local after = self.lines[line2]:sub(col2)

  local line_removal = line2 - line1
  local col_removal = col2 - col1

  -- splice line into line array
  table.splice(self.lines, line1, line_removal + 1, { before .. after })

  local merge = false

  -- keep selections in correct positions: each pair (line, col)
  -- * remains unchanged if before the deleted text
  -- * is set to (line1, col1) if in the deleted text
  -- * is set to (line1, col - col_removal) if on line2 but out of the deleted text
  -- * is set to (line - line_removal, col) if after line2
  for idx, cline1, ccol1, cline2, ccol2 in self:get_selections(true, true) do
    if cline2 < line1 then break end
    local l1, c1, l2, c2 = cline1, ccol1, cline2, ccol2

    if cline1 > line1 or (cline1 == line1 and ccol1 > col1) then
      if cline1 > line2 then
        l1 = l1 - line_removal
      else
        l1 = line1
        c1 = (cline1 == line2 and ccol1 > col2) and c1 - col_removal or col1
      end
    end

    if cline2 > line1 or (cline2 == line1 and ccol2 > col1) then
      if cline2 > line2 then
        l2 = l2 - line_removal
      else
        l2 = line1
        c2 = (cline2 == line2 and ccol2 > col2) and c2 - col_removal or col1
      end
    end

    if l1 == line1 and c1 == col1 then merge = true end
    self:set_selections(idx, l1, c1, l2, c2)
  end

  if merge then
    self:merge_cursors()
  end

  -- update highlighter and assure selection is in bounds
  -- self.highlighter:remove_notify(line1, line_removal)
  table.splice(self.lines, line1, line_removal)
  
  self:sanitize_selection()
end

function SingleLineDoc:insert(line, col, text)
  -- dont allow newline
  text =  text:gsub("\n", "")

  self.redo_stack = { idx = 1 }
  -- Reset the clean id when we're pushing something new before it
  if self:get_change_id() < self.clean_change_id then
    self.clean_change_id = -1
  end
  line, col = self:sanitize_position(line, col)
  self:raw_insert(line, col, text, self.undo_stack, system.get_time())
  self:on_text_change("insert")
end

function SingleLineDoc:remove(line1, col1, line2, col2)
  self.redo_stack = { idx = 1 }
  line1, col1 = self:sanitize_position(line1, col1)
  line2, col2 = self:sanitize_position(line2, col2)
  line1, col1, line2, col2 = sort_positions(line1, col1, line2, col2)
  self:raw_remove(line1, col1, line2, col2, self.undo_stack, system.get_time())
  self:on_text_change("remove")
end

function SingleLineDoc:undo()
  pop_undo(self, self.undo_stack, self.redo_stack, false)
end

function SingleLineDoc:redo()
  pop_undo(self, self.redo_stack, self.undo_stack, false)
end

function SingleLineDoc:text_input(text, idx)
  for sidx, line1, col1, line2, col2 in self:get_selections(true, idx or true) do
    local had_selection = false
    if line1 ~= line2 or col1 ~= col2 then
      self:delete_to_cursor(sidx)
      had_selection = true
    end

    if self.overwrite
    and not had_selection
    and col1 < #self.lines[line1]
    and text:ulen() == 1 then
      self:remove(line1, col1, translate.next_char(self, line1, col1))
    end

    self:insert(line1, col1, text)
    self:move_to_cursor(sidx, #text)
  end
end

function SingleLineDoc:ime_text_editing(text, start, length, idx)
  for sidx, line1, col1, line2, col2 in self:get_selections(true, idx or true) do
    if line1 ~= line2 or col1 ~= col2 then
      self:delete_to_cursor(sidx)
    end
    self:insert(line1, col1, text)
    self:set_selections(sidx, line1, col1 + #text, line1, col1)
  end
end

function SingleLineDoc:replace_cursor(idx, line1, col1, line2, col2, fn)
  local old_text = self:get_text(line1, col1, line2, col2)
  local new_text, res = fn(old_text)
  if old_text ~= new_text then
    self:insert(line2, col2, new_text)
    self:remove(line1, col1, line2, col2)
    if line1 == line2 and col1 == col2 then
      line2, col2 = self:position_offset(line1, col1, #new_text)
      self:set_selections(idx, line1, col1, line2, col2)
    end
  end
  return res
end

function SingleLineDoc:replace(fn)
  local has_selection, results = false, {}
  for idx, line1, col1, line2, col2 in self:get_selections(true) do
    if line1 ~= line2 or col1 ~= col2 then
      results[idx] = self:replace_cursor(idx, line1, col1, line2, col2, fn)
      has_selection = true
    end
  end
  if not has_selection then
    self:set_selection(table.unpack(self.selections))
    results[1] = self:replace_cursor(1, 1, 1, #self.lines, #self.lines[#self.lines], fn)
  end
  return results
end

function SingleLineDoc:delete_to_cursor(idx, ...)
  for sidx, line1, col1, line2, col2 in self:get_selections(true, idx) do
    if line1 ~= line2 or col1 ~= col2 then
      self:remove(line1, col1, line2, col2)
    else
      local l2, c2 = self:position_offset(line1, col1, ...)
      self:remove(line1, col1, l2, c2)
      line1, col1 = sort_positions(line1, col1, l2, c2)
    end
    self:set_selections(sidx, line1, col1)
  end
  self:merge_cursors(idx)
end

function SingleLineDoc:delete_to(...) return self:delete_to_cursor(nil, ...) end

function SingleLineDoc:move_to_cursor(idx, ...)
  for sidx, line, col in self:get_selections(false, idx) do
    self:set_selections(sidx, self:position_offset(line, col, ...))
  end
  self:merge_cursors(idx)
end

function SingleLineDoc:move_to(...) return self:move_to_cursor(nil, ...) end

function SingleLineDoc:select_to_cursor(idx, ...)
  for sidx, line, col, line2, col2 in self:get_selections(false, idx) do
    line, col = self:position_offset(line, col, ...)
    self:set_selections(sidx, line, col, line2, col2)
  end
  self:merge_cursors(idx)
end

function SingleLineDoc:select_to(...) return self:select_to_cursor(nil, ...) end


return SingleLineDoc


