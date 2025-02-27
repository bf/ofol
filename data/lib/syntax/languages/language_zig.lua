local syntax = require "lib.syntax"

syntax.add {
  name = "Zig",
  files = { "%.zig$" },
  comment = "//",
  patterns = {
    { pattern = "//.-\n",                       type = "comment"  },
    { pattern = "\\\\.-\n",                     type = "string" },
    { pattern = { '"', '"', '\\' },             type = "string" },
    { pattern = { "'", "'", '\\' },             type = "string" },
    { pattern = "[iu][%d_]+",                   type = "keyword2" },
    { pattern = "0b[01_]+",                     type = "number" },
    { pattern = "0o[0-7_]+",                    type = "number" },
    { pattern = "0x[%x_]+",                     type = "number" },
    { pattern = "0x[%x_]+%.[%x_]*[pP][-+]?%d+", type = "number" },
    { pattern = "0x[%x_]+%.[%x_]*",             type = "number" },
    { pattern = "0x%.[%x_]+[pP][-+]?%d+",       type = "number" },
    { pattern = "0x%.[%x_]+",                   type = "number" },
    { pattern = "0x[%x_]+[pP][-+]?%d+",         type = "number" },
    { pattern = "0x[%x_]+",                     type = "number" },
    { pattern = "%d[%d_]*%.[%d_]*[eE][-+]?%d+", type = "number" },
    { pattern = "%d[%d_]*%.[%d_]*",             type = "number" },
    { pattern = "%d[%d_]*",                     type = "number" },
    { pattern = "[%+%-=/%*%^%%<>!~|&%.%?]",     type = "operator" },
    { pattern = "[%a_][%w_]*()%s*%(",           type = {"function", "normal"} },
    { pattern = "[A-Z][%w_]*",                  type = "keyword2" },
    { pattern = "[%a_][%w_]*",                  type = "symbol" },
    { pattern = "@()[%a_][%w_]*",               type = {"operator", "function"} },
  },
  symbols = {
    ["fn"]          = "keyword",
    ["asm"]         = "keyword",
    ["volatile"]    = "keyword",
    ["continue"]    = "keyword",
    ["break"]       = "keyword",
    ["switch"]      = "keyword",
    ["for"]         = "keyword",
    ["while"]       = "keyword",
    ["var"]             = "keyword",
    ["anytype"]         = "keyword",
    ["anyframe"] = "keyword",
    ["const"]           = "keyword",
    ["test"]            = "keyword",
    ["packed"]          = "keyword",
    ["extern"]          = "keyword",
    ["export"]          = "keyword",
    ["pub"]             = "keyword",
    ["defer"]           = "keyword",
    ["errdefer"]        = "keyword",
    ["align"]           = "keyword",
    ["usingnamespace"]  = "keyword",
    ["noasync"]     = "keyword",
    ["async"]       = "keyword",
    ["await"]       = "keyword",
    ["cancel"]      = "keyword",
    ["suspend"]     = "keyword",
    ["resume"]      = "keyword",
    ["threadlocal"] = "keyword",
    ["linksection"] = "keyword",
    ["callconv"]    = "keyword",
    ["try"]         = "keyword",
    ["catch"]       = "keyword",
    ["orelse"]      = "keyword",
    ["unreachable"] = "keyword",
    ["error"]       = "keyword",
    ["if"]          = "keyword",
    ["else"]        = "keyword",
    ["return"]      = "keyword",
    ["comptime"]    = "keyword",
    ["stdcallcc"]   = "keyword",
    ["ccc"]         = "keyword",
    ["nakedcc"]     = "keyword",
    ["and"]         = "keyword",
    ["or"]          = "keyword",
    ["struct"] = "keyword",
    ["enum"] = "keyword",
    ["union"] = "keyword",
    ["opaque"] = "keyword",
    ["inline"] = "keyword",
    ["allowzero"] = "keyword",
    ["noalias"] = "keyword",
    ["nosuspend"] = "keyword",

    -- types
    ["f16"] = "keyword2",
    ["f32"] = "keyword2",
    ["f64"] = "keyword2",
    ["f128"] = "keyword2",
    ["void"]            = "keyword2",
    ["c_void"]          = "keyword2",
    ["isize"]           = "keyword2",
    ["usize"]           = "keyword2",
    ["c_short"]         = "keyword2",
    ["c_ushort"]        = "keyword2",
    ["c_int"]           = "keyword2",
    ["c_uint"]          = "keyword2",
    ["c_long"]          = "keyword2",
    ["c_ulong"]         = "keyword2",
    ["c_longlong"]      = "keyword2",
    ["c_ulonglong"]     = "keyword2",
    ["c_longdouble"]    = "keyword2",
    ["bool"]            = "keyword2",

    ["noreturn"]        = "keyword2",
    ["type"]            = "keyword2",
    ["anyerror"]        = "keyword2",
    ["comptime_int"]    = "keyword2",
    ["comptime_float"]  = "keyword2",

    ["true"]            = "literal",
    ["false"]           = "literal",
    ["null"]            = "literal",
    ["undefined"]       = "literal",
  },
}
