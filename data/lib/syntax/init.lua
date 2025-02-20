local syntax = {}
syntax.items = {}

syntax.plain_text_syntax = { name = "Plain Text", patterns = {}, symbols = {} }


function syntax.add(t)
  if type(t.space_handling) ~= "boolean" then t.space_handling = true end

  if t.patterns then
    -- the rule %s+ gives us a performance gain for the tokenizer in lines with
    -- long amounts of consecutive spaces, can be disabled by plugins where it
    -- causes conflicts by declaring the table property: space_handling = false
    if t.space_handling then
      table.insert(t.patterns, { pattern = "%s+", type = "normal" })
    end

    -- this rule gives us additional performance gain by matching every word
    -- that was not matched by the syntax patterns as a single token, preventing
    -- the tokenizer from iterating over each character individually which is a
    -- lot slower since iteration occurs in lua instead of C and adding to that
    -- it will also try to match every pattern to a single char (same as spaces)
    table.insert(t.patterns, { pattern = "%w+%f[%s]", type = "normal" })
  end

  table.insert(syntax.items, t)
end


local function match_pattern(text, pattern, ...)
  if type(pattern) == "string" then
    return text:find(pattern, ...)
  end
  for _, p in ipairs(pattern) do
    local s, e = match_pattern(text, p, ...)
    if s then return s, e end
  end
  return false
end


local function find(string, field)
  local best_match = 0
  local best_syntax
  for i = #syntax.items, 1, -1 do
    local t = syntax.items[i]
    local s, e = match_pattern(string, t[field] or {})
    if s and e - s > best_match then
      best_match = e - s
      best_syntax = t
    end
  end
  return best_syntax
end

function syntax.get(filename, header)
  return (filename and find(filename, "files"))
      or (header and find(header, "headers"))
      or syntax.plain_text_syntax
end

function syntax.load_languages() 
  local languages = {}

  -- load all languages
  local languages_dir = DATADIR .. "/lib/syntax/languages/"
  for _, filename in ipairs(system.list_dir(languages_dir) or {}) do
    -- stderr.debug("[loading]", filename)
    if filename:match("^language_") and filename:match("%.lua$") then
      
      filename = filename:gsub("%.lua$", "") 
      -- stderr.debug("[require]", filename)
      local lang = require("lib.syntax.languages." .. filename)

      languages[filename] = lang
    end
  end

  return languages
end

return syntax
