
-- from core/utf8string.lua
--------------------------------------------------------------------------------
-- inject utf8 functions to strings
--------------------------------------------------------------------------------

local utf8 = require "utf8extra"

string.ubyte = utf8.byte
string.uchar = utf8.char
string.ufind = utf8.find
string.ugmatch = utf8.gmatch
string.ugsub = utf8.gsub
string.ulen = utf8.len
string.ulower = utf8.lower
string.umatch = utf8.match
string.ureverse = utf8.reverse
string.usub = utf8.sub
string.uupper = utf8.upper

string.uescape = utf8.escape
string.ucharpos = utf8.charpos
string.unext = utf8.next
string.uinsert = utf8.insert
string.uremove = utf8.remove
string.uwidth = utf8.widthp
string.uwidthindex = utf8.widthindex
string.utitle = utf8.title
string.ufold = utf8.fold
string.uncasecmp = utf8.ncasecmp

string.uoffset = utf8.offset
string.ucodepoint = utf8.codepoint
string.ucodes = utf8.codes


---Checks if the byte at offset is a UTF-8 continuation byte.
---
---UTF-8 encodes code points in 1 to 4 bytes.
---For a multi-byte sequence, each byte following the start byte is a continuation byte.
---@param s string
---@param offset? integer The offset of the string to start searching. Defaults to 1.
---@return boolean
string.is_utf8_cont = function(s, offset)
  local byte = s:byte(offset or 1)
  return byte >= 0x80 and byte < 0xc0
end


---Returns an iterator that yields a UTF-8 character on each iteration.
---@param text string
---@return fun(): string
string.utf8_chars = function(text)
  return text:gmatch("[\0-\x7f\xc2-\xf4][\x80-\xbf]*")
end
