local core = require "core"

local languages = {}

-- load all languages
local languages_dir = DATADIR .. "/plugins/languages/"
for _, filename in ipairs(system.list_dir(languages_dir) or {}) do
  core.debug("[language] [loading]", filename)
  if filename:match("^language_") and filename:match("%.lua$") then
    
    filename = filename:gsub("%.lua$", "") 
    core.debug("[language] [require]", filename)
    local lang = require("." .. filename)

    languages[filename] = lang
  end
end

return languages