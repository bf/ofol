local core = require "core"
local style = require "themes.style"
local UserSettingsStore = require "stores.user_settings_store"

local Widget = require "lib.widget"
local ListBox = require "lib.widget.listbox"



---Get a list of system and user installed colors.
---@return table<integer, table>
local function get_installed_colors()
  local files, ordered = {}, {}

  for _, root_dir in ipairs {DATADIR, USERDIR} do
    local dir = root_dir .. "/themes/colors"
    for _, filename in ipairs(system.list_dir(dir) or {}) do
      local file_info = system.get_file_info(dir .. "/" .. filename)
      if
        file_info 
        and file_info.type == "file"
        and filename:match("%.lua$")
      then
        -- read colors
        local contents = io.open(dir .. "/" .. filename):read("*a")
        local colors = {}
        for r, g, b in contents:gmatch("#(%x%x)(%x%x)(%x%x)") do
          r = tonumber(r, 16)
          g = tonumber(g, 16)
          b = tonumber(b, 16)
          table.insert(colors, { r, g, b, 0xff })
        end
        -- sort colors from darker to lighter
        table.sort(colors, function(a, b)
          return a[1] + a[2] + a[3] < b[1] + b[2] + b[3]
        end)
        -- remove duplicate colors
        local b = {}
        for i = #colors, 1, -1 do
          local a = colors[i]
          if a[1] == b[1] and a[2] == b[2] and a[3] == b[3] then
            table.remove(colors, i)
          else
            b = colors[i]
          end
        end
        -- insert color to ordered table if not duplicate
        filename = filename:gsub("%.lua$", "")
        if not files[filename] then
          table.insert(ordered, {name = filename, colors = colors})
        end
        files[filename] = true
      end
    end
  end

  table.sort(ordered, function(a, b) return a.name < b.name end)

  return ordered
end

---Function in charge of rendering the colors column of the color pane.
---@param self widget.listbox
---@oaram row integer
---@param x integer
---@param y integer
---@param font renderer.font
---@param color renderer.color
---@param only_calc boolean
---@return number width
---@return number height
local function on_color_draw(self, row, x, y, font, color, only_calc)
  local w = self:get_width() - (x - self.position.x) - style.padding.x
  local h = font:get_height()

  if not only_calc then
    local row_data = self:get_row_data(row)
    local width = w/#row_data.colors

    for i = 1, #row_data.colors do
      renderer.draw_rect(x + ((i - 1) * width), y, width, h, row_data.colors[i])
    end
  end

  return w, h
end

---Generate the list of all available colors with preview
local function load_color_settings(self_colors, current_theme, function_set_theme)
  self_colors.scrollable = false

  local installed_colors = get_installed_colors()

  ---@type widget.listbox
  local listbox = ListBox(self_colors)

  listbox.border.width = 0
  listbox:enable_expand(true)

  listbox:add_column("Theme")
  listbox:add_column("Colors")

  for idx, details in ipairs(installed_colors) do
    local name = details.name
    if current_theme and current_theme == name then
      listbox:set_selected(idx)
    end
    listbox:add_row({
      style.text, name, ListBox.COLEND, on_color_draw
    }, {name = name, colors = details.colors})
  end

  function listbox:on_row_click(idx, data)
    reload_module("themes.colors." .. data.name)
    -- settings.config.theme = data.name
    function_set_theme(data.name)
    UserSettingsStore.save_user_settings(settings.config)
  end

  return self_colors
end



return load_color_settings;
