local style = require "themes.style"
local Label = require "lib.widget.label"
local Button = require "lib.widget.button"
local ListBox = require "lib.widget.listbox"

local SettingsTabComponent = require("components.settings_tab_component")


local function setup_about (about)
  ---@type widget.label
  local title = Label(about, "Lite XL")
  title.font = "big_font"
  ---@type widget.label
  local version = Label(about, "version " .. VERSION)
  ---@type widget.label
  local description = Label(
    about,
    "A lightweight text editor written in Lua, adapted from lite."
  )

  -- local function open_link(link)
  --   local platform_filelauncher
  --   if PLATFORM == "Windows" then
  --     platform_filelauncher = "start"
  --   elseif PLATFORM == "Mac OS X" then
  --     platform_filelauncher = "open"
  --   else
  --     platform_filelauncher = "xdg-open"
  --   end
  --   system.exec(platform_filelauncher .. " " .. link)
  -- end

  ---@type widget.button
  local button = Button(about, "Visit Website")
  button:set_tooltip("Open https://lite-xl.com/")
  function button:on_click() 
    -- open_link("https://lite-xl.com/") 
  end

  ---@type widget.listbox
  local contributors = ListBox(about)
  contributors.scrollable = true
  contributors:add_column("Contributors")
  contributors:add_column("")
  contributors:add_column("Website")
  function contributors:on_row_click(_, data) 
    -- open_link(data) 
  end

  local contributors_list = {
    { "Rxi", "Lite Founder", "https://github.com/rxi" },
    { "Francesco Abbate", "Lite XL Founder", "https://github.com/franko" },
    { "Adam Harrison", "Core", "https://github.com/adamharrison" },
    { "Andrea Zanellato", "CI, Website", "https://github.com/redtide" },
    { "Björn Buckwalter", "MacOS Support", "https://github.com/bjornbm" },
    { "boppyt", "Contributor", "https://github.com/boppyt" },
    { "Cukmekerb", "Contributor", "https://github.com/vincens2005" },
    { "Daniel Rocha", "Contributor", "https://github.com/dannRocha" },
    { "daubaris", "Contributor", "https://github.com/daubaris" },
    { "Dheisom Gomes", "Contributor", "https://github.com/dheisom" },
    { "Evgeny Petrovskiy", "Contributor", "https://github.com/eugenpt" },
    { "Ferdinand Prantl", "Contributor", "https://github.com/prantlf" },
    { "Jan", "Build System", "https://github.com/Jan200101" },
    { "Janis-Leuenberger", "MacOS Support", "https://github.com/Janis-Leuenberger" },
    { "Jefferson", "Contributor", "https://github.com/jgmdev" },
    { "Jipok", "Contributor", "https://github.com/Jipok" },
    { "Joshua Minor", "Contributor", "https://github.com/jminor" },
    { "George Linkovsky", "Contributor", "https://github.com/Timofffee" },
    { "Guldoman", "Core", "https://github.com/Guldoman" },
    { "liquidev", "Contributor", "https://github.com/liquidev" },
    { "Mat Mariani", "MacOS Support", "https://github.com/mathewmariani" },
    { "Nightwing", "Contributor", "https://github.com/Nightwing13" },
    { "Nils Kvist", "Contributor", "https://github.com/budRich" },
    { "Not-a-web-Developer", "Contributor", "https://github.com/Not-a-web-Developer" },
    { "Robert Štojs", "CI", "https://github.com/netrobert" },
    { "sammyette", "Plugins", "https://github.com/TorchedSammy" },
    { "Takase", "Core", "https://github.com/takase1121" },
    { "xwii", "Contributor", "https://github.com/xcb-xwii" }
  }

  for _, c in ipairs(contributors_list) do
    contributors:add_row({
      c[1], ListBox.COLEND, c[2], ListBox.COLEND, c[3]
    }, c[3])
  end

  ---@param self widget
  function about:update_positions()
    -- local center = self:get_width() / 2

    -- title:set_label("Lite XL")
    -- title:set_position(
    --   center - (title:get_width() / 2),
    --   style.padding.y
    -- )

    -- version:set_position(
    --   center - (version:get_width() / 2),
    --   title:get_bottom() + (style.padding.y / 2)
    -- )

    -- description:set_position(
    --   center - (description:get_width() / 2),
    --   version:get_bottom() + (style.padding.y / 2)
    -- )

    -- button:set_position(
    --   center - (button:get_width() / 2),
    --   description:get_bottom() + style.padding.y
    -- )

    -- contributors:set_position(
    --   style.padding.x,
    --   button:get_bottom() + style.padding.y
    -- )

    -- contributors:set_size(
    --   self:get_width() - (style.padding.x * 2),
    --   self:get_height() - (button:get_bottom() + (style.padding.y * 2))
    -- )

    -- contributors:set_visible_rows()
  end

  return about
end

return SettingsTabComponent("about", "About", "i", setup_about);
