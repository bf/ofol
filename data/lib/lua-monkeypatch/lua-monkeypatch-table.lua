
-- table.pack = table.pack or pack or function(...) return {...} end
-- table.unpack = table.unpack or unpack

-- return number of items in table
table.count = function(myTable)
  local count = 0
  for _ in pairs(myTable) do
      count = count + 1
  end
  return count
end

---Returns a new table containing the contents of b merged into a.
---@param a table|nil
---@param b table?
---@return table
table.merge = function (a, b)
  a = type(a) == "table" and a or {}
  local t = {}
  for k, v in pairs(a) do
    t[k] = v
  end
  if b and type(b) == "table" then
    for k, v in pairs(b) do
      t[k] = v
    end
  end
  return t
end



---Returns the first index where a subtable in tbl has prop set.
---If none is found, nil is returned.
---@param tbl table
---@param prop any
---@return number|nil
table.find_index = function (tbl, prop)
  for i, o in ipairs(tbl) do
    if o[prop] then return i end
  end
end

-- returns true if table contains certain value
table.contains = function (tbl, value)
  for _, v in pairs(tbl) do
      if v == value then
          return true
      end
  end
  return false
end

-- filter table by 
-- Function to filter the table, keeping only even numbers
table.filter = function (t, condition)
  if type(t) ~= "table" then
    stderr.error("t needs to be table, received %s", type(t))
  end

  if type(condition) ~= "function" then
    stderr.error("condition needs to be function, received", type(condition))
  end

  if table.count(t) == 0 then
    stderr.error("cannot filter empty table")
  end

  -- stderr.debug("filtering table", t)

  -- loop over table
  local filtered = {}
  for key, item in pairs(t) do
    -- stderr.debug("loop", key, item)
    
    -- check condition
    if condition(item) then
      -- add to result
      table.insert(filtered, item)
    end
  end

  -- if table.count(filtered) == 0 then
  --   stderr.error("filtered result is empty")
  -- end

  return filtered
end


---Splices a numerically indexed table.
---This function mutates the original table.
---@param t any[]
---@param at number Index at which to start splicing.
---@param remove number Number of elements to remove.
---@param insert? any[] A table containing elements to insert after splicing.
table.splice = function (t, at, remove, insert)
  assert(remove >= 0, "bad argument #3 to 'splice' (non-negative value expected)")
  insert = insert or {}
  local len = #insert
  if remove ~= len then table.move(t, at + remove, #t + remove, at + len) end
  table.move(insert, 1, len, at, t)
end


-- compare score for fuzzy matching
local function compare_score(a, b)
  return a.score > b.score
end

-- fuzzy match table of items
local function fuzzy_match_items(items, needle, files)
  local res = {}
  for _, item in ipairs(items) do
    local score = system.fuzzy_match(tostring(item), needle, files)
    if score then
      table.insert(res, { text = item, score = score })
    end
  end
  table.sort(res, compare_score)
  for i, item in ipairs(res) do
    res[i] = item.text
  end
  return res
end


---Performs fuzzy matching.
---
---If the haystack is a string, a score ranging from 0 to 1 is returned. </br>
---If the haystack is a table, a table containing the haystack sorted in ascending
---order of similarity is returned.
---@param haystack string
---@param needle string
---@param files boolean If true, the matching process will be performed in reverse to better match paths.
---@return number
---@overload fun(haystack: string[], needle: string, files: boolean): string[]
table.fuzzy_match = function (haystack, needle, files)
  if type(haystack) == "table" then
    return fuzzy_match_items(haystack, needle, files)
  end
  return system.fuzzy_match(haystack, needle, files)
end


---Performs fuzzy matching and returns recently used strings if needed.
---
---If the needle is empty, then a list of recently used strings
---are added to the result, followed by strings from the haystack.
---@param haystack string[]
---@param recents string[]
---@param needle string
---@return string[]
table.fuzzy_match_with_recents = function (haystack, recents, needle)
  if needle == "" then
    local recents_ext = {}
    for i = 2, #recents do
      table.insert(recents_ext, recents[i])
    end
    table.insert(recents_ext, recents[1])
    local others = table.fuzzy_match(haystack, "", true)
    for i = 1, #others do
      table.insert(recents_ext, others[i])
    end
    return recents_ext
  else
    return fuzzy_match_items(haystack, needle, true)  
  end
end

-- add tostring function which uses json
-- fixme: this might not be working
function table:__tostring(self)
   local ok, json_string = pcall(json.encode, self)
  if not ok then
    stderr.error("could not convert %s to json: %s", self, json_string)
    error(json_string)
  end

  return json_string
end
