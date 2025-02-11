-- simple key-value cache
local Object = require "core.object"

local Cache = Object:extend()

-- cache object
function Cache:new(name) 
  self.name = name
  self.cached_items = {}
end

-- get from cache
function Cache:get(key)
  stderr.debug("cache %s get %s", self.name, key)
  return self.cached_items[key]
end

-- returns true if cache contains item
function Cache:set(key, value)
  stderr.debug("cache %s set %s to %s", self.name, key, value)
  self.cached_items[key] = value
end

-- clear cache for specific key
function Cache:clear(key)
  stderr.debug("cache %s clear %s", self.name, key)
  self.cached_items[key] = nil
end

-- clear whole cache
function Cache:clear_all() 
  stderr.debug("clear_all")
  self.cached_items = {}
end

-- wrap function call in cache
function Cache:wrap_function(fn_get)
  stderr.debug("cache %s wrap function %s", self.name, fn_get)

  -- rename self so it can be used inside function
  local reference_to_cached_items = self.cached_items

  -- return wrapped function
  local function wrapped_function_with_caching (key)
    if reference_to_cached_items[key] ~= nil then
      return reference_to_cached_items[key]
    else
      -- call function to get result
      local result = fn_get(key)

      -- if we have result, then cache it
      if result ~= nil then
        reference_to_cached_items[key] = result
      end

      -- return result to calling function
      return result
    end
  end

  return wrapped_function_with_caching
end

return Cache