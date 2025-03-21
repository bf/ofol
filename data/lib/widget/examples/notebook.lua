--
-- NoteBook example.
--

local core = require "core"
local keymap = require "core.keymap"
local command = require "core.command"
local style = require "themes.style"
local NoteBook = require "lib.widget.notebook"
local Button = require "lib.widget.button"
local TextBox = require "lib.widget.textbox"
local NumberBox = require "lib.widget.numberbox"
local Toggle = require "lib.widget.toggle"
local ProgressBar = require "lib.widget.progressbar"
local CheckBox = require "lib.widget.checkbox"
local ListBox = require "lib.widget.listbox"

---@type widget.notebook
local notebook = NoteBook()
notebook.size.x = 250
notebook.size.y = 300
notebook.border.width = 0

local log = notebook:add_pane("log", "Messages")
local build = notebook:add_pane("build", "Build")
local errors = notebook:add_pane("errors", "Errors")
local diagnostics = notebook:add_pane("diagnostics", "Diagnostics")

notebook:set_pane_icon("log", "i")
notebook:set_pane_icon("build", "P")
notebook:set_pane_icon("errors", "!")

---@type widget.textbox
local textbox = TextBox(log, "", "placeholder...")
textbox:set_position(10, 20)

---@type widget.numberbox
local numberbox = NumberBox(log, 10)
numberbox:set_position(10, textbox:get_bottom() + 20)

---@type widget.toggle
local toggle = Toggle(log, "The Toggle:", true)
toggle:set_position(10, numberbox:get_bottom() + 20)

---@type widget.progressbar
local progress = ProgressBar(log, 33)
progress:set_position(textbox:get_right() + 50, 20)

---@type widget.checkbox
local checkbox = CheckBox(build, "Child checkbox")
checkbox:set_position(10, 20)

---@type widget.button
local button = Button(errors, "A test button")
button:set_position(10, 20)
button.on_click = function()
  system.show_fatal_error("Message", "Hello World")
end

---@type widget.checkbox
local checkbox2 = CheckBox(errors, "Child checkbox2")
checkbox2:set_position(10, button:get_bottom() + 30)

---@type widget.listbox
diagnostics.scrollable = false

local listbox = ListBox(diagnostics)
listbox.border.width = 0
listbox:enable_expand(true)

listbox:add_column("Severity")
listbox:add_column("Message")

listbox:add_row({
  style.icon_font, style.syntax.string, "!", style.font, style.text, " Error",
  ListBox.COLEND,
  "A message to display to the user."
})
listbox:add_row({
  style.icon_font, style.syntax.string, "!", style.font, style.text, " Error",
  ListBox.COLEND,
  "Another message to display to the user\nwith new line characters\nfor the win."
})

threading.add_thread(function()
  for num=1, 1000 do
    listbox:add_row({
      style.icon_font, style.syntax.string, "!", style.font, style.text, " Error",
      ListBox.COLEND,
      tostring(num),
      " Another message to display to the user\nwith new line characters\nfor the win."
    }, num)
    if num % 100 == 0 then
      coroutine.yield()
    end
  end
  listbox:add_row({
    style.icon_font, style.syntax.string, "!", style.font, style.text, " Error",
    ListBox.COLEND,
    "Final message to display."
  })
end)

listbox.on_row_click = function(self, idx, data)
  if data then
    system.show_fatal_error("Row Data", data)
  end
  self:remove_row(idx)
end

-- defer draw needs to be set to false when adding widget as a lite-xl node
notebook.border.width = 0
notebook.draggable = false
notebook.defer_draw = false

local inside_node = false

-- You can add the widget as a lite-xl node
command.add(nil,{
  ["notebook-widget:toggle"] = function()
    if inside_node then
      notebook:toggle_visible()
    else
      local node = core.root_view:get_primary_node()
      node:split("down", notebook, {y=true}, true)
      notebook:show()
      inside_node = true
    end
  end
})

keymap.add {
  ["alt+shift+m"] = "notebook-widget:toggle",
}
