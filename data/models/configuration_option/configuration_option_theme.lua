local ListBox = require("lib.widget.listbox")
local ConfigurationOption = require("models.configuration_option")
local style = require("themes.style")

local CONSTANT_THEMES_PATH = "/themes/colors"

---Get a list of system and user installed colors.
---@return table<integer, table>
local function _load_installed_themes_from_filesystem()
  local files, ordered = {}, {}

  for _, root_dir in ipairs {DATADIR, USERDIR} do
    local dir = root_dir .. CONSTANT_THEMES_PATH
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

-- load installed themes
local _installed_themes = _load_installed_themes_from_filesystem()

-- returns true if theme with this name exists
local function _has_theme_with_name(theme_name)
  for idx, details in ipairs(_installed_themes) do
    local name = details.name
    -- check if theme with this name exists
    if theme_name == name then
      -- if yes, we are successfull
      return true
    end
  end

  -- no theme found with this name
  return false
end


-- Theme
local ConfigurationOptionTheme = ConfigurationOption:extend()

-- overwrite constructor so we can use specific on_change function
function ConfigurationOptionTheme:new(key, description_text_short, description_text_long, default_value, options)
  -- initialize with base class
  self.super.new(self, key, description_text_short, description_text_long, default_value, {
    -- handle theme change
    on_change =  function(new_value) 
      -- reload theme module to show new colors
      stderr.debug("theme change to", new_value)
      reload_module("themes.colors." .. new_value)
    end
  })
end

-- return true if $val is valid
function ConfigurationOptionTheme:is_valid(val)
  return Validator.is_string(val) and _has_theme_with_name(val)
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
local function _listbox_on_color_draw(self, row, x, y, font, color, only_calc)
  local w = self:get_width() - (x - self.position.x) - 2*style.padding.x
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


-- create UI element
function ConfigurationOptionTheme:add_value_modification_widget_to_container(container)
  -- add listbox/table with one row for each theme
  local widget = ListBox(container)

  widget.border.width = 0
  widget:enable_expand(true)

  -- table has two columns
  widget:add_column("Theme")
  widget:add_column("Colors")

  -- one row for each theme
  for idx, details in ipairs(_installed_themes) do
    -- visually highlight the current theme
    if self._current_value == details.name then
      widget:set_selected(idx)
    end

    -- render row for theme
    widget:add_row({
      -- 1st colum: name of theme
      style.text, details.name, ListBox.COLEND, 
      -- 2nd column: render theme colors 
      _listbox_on_color_draw
    }, {name = details.name, colors = details.colors})
  end

  -- handle click on row to select new theme
  function widget.on_row_click(this, idx, data)
    -- set new theme
    -- configurationOptionForTheme:set(data.name)
    self:set_value_from_ui(data.name)
  end
  
  return widget
end


return ConfigurationOptionTheme