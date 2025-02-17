local style = require "themes.style"
local color_from_css_string = require "themes.color_from_css_string"

style.background = { color_from_css_string "#343233" }
style.background2 = { color_from_css_string "#2c2a2b" }
style.background3 = { color_from_css_string "#2c2a2b" }
style.text = { color_from_css_string "#c4b398" }
style.caret = { color_from_css_string "#61efce" }
style.accent = { color_from_css_string "#ffd152" }
style.dim = { color_from_css_string "#615d5f" }
style.divider = { color_from_css_string "#242223" }
style.selection = { color_from_css_string "#454244" }
style.line_number = { color_from_css_string "#454244" }
style.line_number2 = { color_from_css_string "#615d5f" }
style.line_highlight = { color_from_css_string "#383637" }
style.scrollbar = { color_from_css_string "#454344" }
style.scrollbar2 = { color_from_css_string "#524F50" }

style.syntax["normal"] = { color_from_css_string "#efdab9" }
style.syntax["symbol"] = { color_from_css_string "#efdab9" }
style.syntax["comment"] = { color_from_css_string "#615d5f" }
style.syntax["keyword"] = { color_from_css_string "#d36e2d" }
style.syntax["keyword2"] = { color_from_css_string "#ef6179" }
style.syntax["number"] = { color_from_css_string "#ffd152" }
style.syntax["literal"] = { color_from_css_string "#ffd152" }
style.syntax["string"] = { color_from_css_string "#ffd152" }
style.syntax["operator"] = { color_from_css_string "#efdab9" }
style.syntax["function"] = { color_from_css_string "#61efce" }
