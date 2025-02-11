local stderr = require "lib.stderr"

local strict = {}
strict.defined = {}


-- used to define a global variable
function global(t)
  for k, v in pairs(t) do
    strict.defined[k] = true
    rawset(_G, k, v)
  end
end


function strict.__newindex(t, k, v)
  stderr.error("cannot SET undefined variable: " .. k)
end


function strict.__index(t, k)
  if not strict.defined[k] then
    stderr.error("cannot GET undefined variable: " .. k)
  end
end


setmetatable(_G, strict)
