local b05 = 'rgba(0,0,0,0.5)'   local red = '#994D4D'
local b80 = '#333333'       local orange  = '#B3661A'
local b60 = '#808080'       local green   = '#52994D'
local b40 = '#ADADAD'       local teal    = '#4D9999'
local b20 = '#CECECE'       local blue    = '#1A66B3'
local b00 = '#E6E6E6'       local magenta = '#994D99'
--------------------------=--------------------------
local style               =     require  'themes.style'
local color_from_css_string = require "themes.color_from_css_string"

--------------------------=--------------------------
style.line_highlight      =     { color_from_css_string(b20) }
style.background          =     { color_from_css_string(b00) }
style.background2         =     { color_from_css_string(b20) }
style.background3         =     { color_from_css_string(b20) }
style.text                =     { color_from_css_string(b60) }
style.caret               =     { color_from_css_string(b80) }
style.accent              =     { color_from_css_string(b80) }
style.dim                 =     { color_from_css_string(b60) }
style.divider             =     { color_from_css_string(b40) }
style.selection           =     { color_from_css_string(b40) }
style.line_number         =     { color_from_css_string(b60) }
style.line_number2        =     { color_from_css_string(b80) }
style.scrollbar           =     { color_from_css_string(b40) }
style.scrollbar2          =     { color_from_css_string(b60) }
style.nagbar              =     { color_from_css_string(red) }
style.nagbar_text         =     { color_from_css_string(b00) }
style.nagbar_dim          =     { color_from_css_string(b05) }
--------------------------=--------------------------
style.syntax              =                        {}
style.syntax['normal']    =     { color_from_css_string(b80) }
style.syntax['symbol']    =     { color_from_css_string(b80) }
style.syntax['comment']   =     { color_from_css_string(b60) }
style.syntax['keyword']   =    { color_from_css_string(blue) }
style.syntax['keyword2']  =     { color_from_css_string(red) }
style.syntax['number']    =    { color_from_css_string(teal) }
style.syntax['literal']   =    { color_from_css_string(blue) }
style.syntax['string']    =   { color_from_css_string(green) }
style.syntax['operator']  = { color_from_css_string(magenta) }
style.syntax['function']  =    { color_from_css_string(blue) }
--------------------------=--------------------------
style.syntax.paren1       = { color_from_css_string(magenta) }
style.syntax.paren2       =  { color_from_css_string(orange) }
style.syntax.paren3       =    { color_from_css_string(teal) }
style.syntax.paren4       =    { color_from_css_string(blue) }
style.syntax.paren5       =     { color_from_css_string(red) }
--------------------------=--------------------------
style.lint                =                        {}
style.lint.info           =    { color_from_css_string(blue) }
style.lint.hint           =   { color_from_css_string(green) }
style.lint.warning        =     { color_from_css_string(red) }
style.lint.error          =  { color_from_css_string(orange) }
