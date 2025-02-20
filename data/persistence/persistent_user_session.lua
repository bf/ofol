local json_config_file = require "lib.json_config_file"

local PATH_TO_SESSION_JSON_FILE = USERDIR .. PATHSEP .. "session.json"

local PersistentUserSession = {}

-- load user session from json file
function PersistentUserSession.load_user_session()
  return json_config_file.load_object_from_json_file(PATH_TO_SESSION_JSON_FILE)
end

-- store user session into json file
function PersistentUserSession.save_user_session(data)
  json_config_file.save_object_to_json_file(data, PATH_TO_SESSION_JSON_FILE)
end

return PersistentUserSession