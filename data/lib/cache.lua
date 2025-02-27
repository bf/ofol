-- simple key-value cache

local Cache = Object:extend()

-- cache object
function Cache:new(name) 
  self._name = name
  self._cached_items = {}
end

-- get from cache
function Cache:get(key)
  stderr.debug("cache %s get %s", self._name, key)

  if self._cached_items[key] == nil then
    stderr.error("key %s not found in cache", key)
  else
    return self._cached_items[key]
  end
end

-- returns true if cache contains item
function Cache:set(key, value)
  stderr.debug("cache %s set %s => %s", self._name, key, value)
  self._cached_items[key] = value
end

-- clear cache
function Cache:clear(key)
  if key ~= nil then
    -- clear for specific key
    stderr.debug("cache %s clear %s", self._name, key)
    self._cached_items[key] = nil
  else
    -- clear whole cache
    stderr.debug("cache %s clear all", self._name, key)
    self._cached_items = {}
  end
end

return Cache