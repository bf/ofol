-- mod-version:3

-- Anthony Axenov (c) 2022, The MIT License
-- https://github.com/anthonyaxenov/lite-xl-ignore-syntax/

local syntax = require "core.syntax"
local style = require "themes.style"

syntax.add {
  name = ".ignore file",
  files = { "%..*ignore$" },
  comment = "#",
  patterns = {
    { regex = "^ *#.*$",            type = "comment" },
    { regex = { "(?=^ *!.)", "$" }, type = "ignore"  },
    -- { regex = { "(?=.)", "$" },     type = "exclude" },
  },
  symbols = {}
}

