quiet=1
jobs=10
max_line_length=1000

globals={
  -- from api.c
  "system", "renderer", "renwindow", "regex", "process", "dirmonitor", "utf8extra", 
  
  -- std library modified by monkey patching
  "math", "table", "string",

  -- global constants
  "SCALE", "DATADIR", "USERDIR", "PATHSEP",

  -- global functions
  "try_catch",

  -- global includs from entrypoint.lua
  "stderr", "json", "json_config_file", "fsutils"


}

-- ignore error codes
ignore={
  "611", -- line contains only whitespace
  "612", -- line contains trailing whitespace
  "614", -- trailing whitespace in a comment
}

-- errors start with 0
-- only show errors
only={"0.."}

codes=true
ranges=true