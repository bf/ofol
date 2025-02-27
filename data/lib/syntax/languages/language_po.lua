local syntax = require "lib.syntax"

syntax.add {
  name = "PO",
  files = { "%.po$", "%.pot$" },
  comment = "#",
  patterns = {
    { pattern = { "#", "\n"},        type = "comment"  },
    { pattern = { '"', '"', '\\' },  type = "string"   },
    { pattern = "[%[%]]",            type = "operator" },
    { pattern = "%d+",               type = "number"   },
    { pattern = "[%a_][%w_]*",       type = "symbol"   },
  },
  symbols = {
    ["msgctxt"]      = "keyword",
    ["msgid"]        = "keyword",
    ["msgid_plural"] = "keyword",
    ["msgstr"]       = "keyword",
  },
}
