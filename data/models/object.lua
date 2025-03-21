-- base object class with some useful functionality
-- this class is provided as GLOBAL VARIABLE via entrypoint.lua
-- models will be derived from this
-- example methods are :extend() and checking for class :is_class_of() etc.

local Object = {}
Object.__index = Object

---Can be overrided by child objects to implement a constructor.
function Object:new() end

function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)
  return cls
end

---Check if the object is strictly of the given type.
---@param T any
---@return boolean
function Object:is(T)
  return getmetatable(self) == T
end

---Check if the parameter is strictly of the object type.
---@param T any
---@return boolean
function Object:is_class_of(T)
  return getmetatable(T) == self
end

---Check if the object inherits from the given type.
---@param T any
---@return boolean
function Object:extends(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end

---Check if the parameter inherits from the object.
---@param T any
---@return boolean
function Object:is_extended_by(T)
  local mt = getmetatable(T)
  while mt do
    if mt == self then
      return true
    end
    local _mt = getmetatable(T)
    if mt == _mt then break end
    mt = _mt
  end
  return false
end

---Metamethod to get a string representation of an object.
---@return string
function Object:__tostring()
  return "Object"
end

---Metamethod to allow using the object call as a constructor.
function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end


return Object
