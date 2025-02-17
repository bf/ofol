local style = require "themes.style"
local color_from_css_string = require "themes.color_from_css_string"

style.background = { color_from_css_string "#fbfbfb" }
style.background2 = { color_from_css_string "#f2f2f2" }
style.background3 = { color_from_css_string "#f2f2f2" }
style.text = { color_from_css_string "#404040" }
style.caret = { color_from_css_string "#fc1785" }
style.accent = { color_from_css_string "#fc1785" }
style.dim = { color_from_css_string "#b0b0b0" }
style.divider = { color_from_css_string "#e8e8e8" }
style.selection = { color_from_css_string "#b7dce8" }
style.line_number = { color_from_css_string "#d0d0d0" }
style.line_number2 = { color_from_css_string "#808080" }
style.line_highlight = { color_from_css_string "#f2f2f2" }
style.scrollbar = { color_from_css_string "#e0e0e0" }
style.scrollbar2 = { color_from_css_string "#c0c0c0" }

style.syntax["normal"] = { color_from_css_string "#181818" }
style.syntax["symbol"] = { color_from_css_string "#181818" }
style.syntax["comment"] = { color_from_css_string "#22a21f" }
style.syntax["keyword"] = { color_from_css_string "#fb6620" }
style.syntax["keyword2"] = { color_from_css_string "#fc1785" }
style.syntax["number"] = { color_from_css_string "#1586d2" }
style.syntax["literal"] = { color_from_css_string "#1586d2" }
style.syntax["string"] = { color_from_css_string "#1586d2" }
style.syntax["operator"] = { color_from_css_string "#fb6620" }
style.syntax["function"] = { color_from_css_string "#fc1785" }
