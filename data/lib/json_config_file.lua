local json = require("lib.json")

local json_config_file = {}

function json_config_file.load_object_from_json_file(json_file_path)
  stderr.debug("loading data from json file %s", json_file_path)

  -- read local file 
  local open = io.open
  local file = open(json_file_path, "rb")
  if not file then 
    if file ~= nil then
      file:close()
    end
    stderr.warn("could not read file %s", json_file_path)
    return {} 
  end

  -- read file as string
  local jsonString = file:read "*a"
  file:close()

  stderr.debug("reading file: %s", json_file_path)

  -- convert json to object
  local ok, result = pcall(json.decode, jsonString)

  if ok then
    stderr.debug("json.decode result: %s", result)
    if not result then
      stderr.warn("json.decode returned empty value (this might be a bug) when reading file %s", json_file_path)
      return {}
    else
      -- proper result, return successfully
      return result
    end
  else
    stderr.error("json.decode failed: %s for file %s", result, json_file_path)
    return {}
  end
end

function json_config_file.save_object_to_json_file(data, json_file_path)
  stderr.debug("saving %s to file %s", data, json_file_path)

  local fp = io.open(json_file_path, "w")
  if not fp then
    stderr.error("could not open json file for writing: %s", json_file_path)
    return
  end

  -- convert to json
  local ok, json_string = pcall(json.encode, data)
  if not ok then
    stderr.error("could not convert %s to json: %s", data, json_string)
    error(json_string)
  end

  stderr.debug("json string for saving: %s", json_string)

  -- write to file
  fp:write(json_string)
  fp:close()

  stderr.debug("successfully saved json to %s", json_file_path)
end

return json_config_file