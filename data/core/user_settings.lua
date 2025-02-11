local json_config_file = require "lib.json_config_file"
local stderr = require "lib.stderr"

local user_settings = {}

-- path for user settings
local PATH_USER_SETTINGS_JSON = USERDIR .. PATHSEP .. "user_settings.json"

---Load config options from the USERDIR user_settings.lua and store them on
---settings.config for later usage.
function user_settings.load_user_settings()
  stderr.debug("loading user settings from %s", PATH_USER_SETTINGS_JSON)
  return json_config_file.load_object_from_json_file(PATH_USER_SETTINGS_JSON)
end

---Save current config options into the USERDIR user_settings.lua
function user_settings.save_user_settings(data)
  stderr.debug("saving user settings to %s", PATH_USER_SETTINGS_JSON)
  json_config_file.save_object_to_json_file(data, PATH_USER_SETTINGS_JSON)
end

return user_settings