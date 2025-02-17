local style = require "themes.style"
local color_from_css_string = require "themes.color_from_css_string"

style.background = { color_from_css_string "#2e2e32" }  -- Docview
style.background2 = { color_from_css_string "#252529" } -- Treeview
style.background3 = { color_from_css_string "#252529" } -- Command view
style.text = { color_from_css_string "#97979c" }
style.caret = { color_from_css_string "#93DDFA" }
style.accent = { color_from_css_string "#e1e1e6" }
-- style.dim - text color for nonactive tabs, tabs divider, prefix in log and
-- search result, hotkeys for context menu and command view
style.dim = { color_from_css_string "#525257" }
style.divider = { color_from_css_string "#202024" } -- Line between nodes
style.selection = { color_from_css_string "#48484f" }
style.line_number = { color_from_css_string "#525259" }
style.line_number2 = { color_from_css_string "#83838f" } -- With cursor
style.line_highlight = { color_from_css_string "#343438" }
style.scrollbar = { color_from_css_string "#414146" }
style.scrollbar2 = { color_from_css_string "#4b4b52" } -- Hovered
style.scrollbar_track = { color_from_css_string "#252529" }
style.nagbar = { color_from_css_string "#FF0000" }
style.nagbar_text = { color_from_css_string "#FFFFFF" }
style.nagbar_dim = { color_from_css_string "rgba(0, 0, 0, 0.45)" }
style.drag_overlay = { color_from_css_string "rgba(255,255,255,0.1)" }
style.drag_overlay_tab = { color_from_css_string "#93DDFA" }
style.good = { color_from_css_string "#72b886" }
style.warn = { color_from_css_string "#FFA94D" }
style.error = { color_from_css_string "#FF3333" }
style.modified = { color_from_css_string "#1c7c9c" }

style.syntax["normal"] = { color_from_css_string "#e1e1e6" }
style.syntax["symbol"] = { color_from_css_string "#e1e1e6" }
style.syntax["comment"] = { color_from_css_string "#676b6f" }
style.syntax["keyword"] = { color_from_css_string "#E58AC9" }  -- local function end if case
style.syntax["keyword2"] = { color_from_css_string "#F77483" } -- self int float
style.syntax["number"] = { color_from_css_string "#FFA94D" }
style.syntax["literal"] = { color_from_css_string "#FFA94D" }  -- true false nil
style.syntax["string"] = { color_from_css_string "#f7c95c" }
style.syntax["operator"] = { color_from_css_string "#93DDFA" } -- = + - / < >
style.syntax["function"] = { color_from_css_string "#93DDFA" }

style.log["DEBUG"]  = { icon = "i", color = style.dim }
style.log["INFO"]  = { icon = "i", color = style.text }
style.log["WARN"]  = { icon = "!", color = style.warn }
style.log["ERROR"] = { icon = "!", color = style.error }

return style
