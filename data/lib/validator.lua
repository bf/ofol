-- basic validation function

local validator = {}

-- return true if val is number
function validator.is_number(val) 
  if not tonumber(val) then
    return false
  else
    return true
  end
end

-- return true if val is number between min and max
function validator.is_number_between(val, min, max) 
  if not validator.is_number(val) then
    return false
  end

  if val < min then
    return false
  end

  if val > max then
    return false
  end

  return true
end

-- return true if val is string-like
function validator.is_string(val) 
  -- either instance of string class
  -- or should have __toString() function
  return (type(val) == "string" or val.__tostring ~= nil)
end

-- return true if val is table
function validator.is_table(val)
  return type(val) == "table"
end

-- return true if val is boolean
function validator.is_boolean(val)
  return val == false or val == true
end

-- return true if val is a list of string-like
function validator.is_list_of_strings(val) 
  -- must be table
  if not validator.is_table(val) then
    return false
  end

  -- loop over all items 
  for _, inner_val in pairs(val) do
    -- ensure it is string
    if not validator.is_string(inner_val) then
      -- error if not string
      return false
    end
  end

  -- now we can be sure it is list of strings
  return true
end

-- return true if val is function
function validator.is_function(val)
  return type(val) == "function"
end

return validator