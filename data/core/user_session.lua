local json_config_file = require "libraries.json_config_file"

local PATH_TO_SESSION_JSON_FILE = USERDIR .. PATHSEP .. "session.json"

local user_session = {}

function user_session.load_user_session()
  return json_config_file.load_object_from_json_file(PATH_TO_SESSION_JSON_FILE)
  -- local ok, t = pcall(dofile, USERDIR .. PATHSEP .. "session.lua")
  -- return ok and t or {}
end

function user_session.save_user_session()
  -- local fp = io.open(USERDIR .. PATHSEP .. "session.lua", "w")
  -- if fp then
  --   fp:write("return {recents=", common.serialize(core.recent_projects),
  --     ", window=", common.serialize(table.pack(system.get_window_size(core.window))),
  --     ", window_mode=", common.serialize(system.get_window_mode(core.window)),
  --     ", previous_find=", common.serialize(core.previous_find),
  --     ", previous_replace=", common.serialize(core.previous_replace),
  --     "}\n")
  --   fp:close()
  -- end

  local data = {
    ["recents"] = core.recent_projects,
    ["window"] = table.pack(system.get_window_size(core.window)),
    ["window_mode"] = system.get_window_mode(core.window),
    ["previous_find"] = core.previous_find,
    ["previous_replace"] = core.previous_replace
  }

  json_config_file.save_object_to_json_file(data, PATH_TO_SESSION_JSON_FILE)
end

return user_session