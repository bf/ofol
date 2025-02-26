local style = require "themes.style"
local Label = require "lib.widget.label"
local Button = require "lib.widget.button"
local ListBox = require "lib.widget.listbox"

local SettingsTabComponent = require("components.settings_tab_component")


local contributors_list = {
  { "bf", "ofol", "https://github.com/bf" },
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

local function setup_about (about)
  local title = Label(about, "OFOL (opinionated fork of lite-xl)")
  title.font = "big_font"
  
  Label(about, "version " .. VERSION)
  Label(about, "A lightweight text editor written in Lua, adapted from lite.")
  Label(about, "Visit Website https://github.com/bf/ofol")

  Label(about, " ")
  Label(about, "Contributors:")
  for _, c in ipairs(contributors_list) do
    Label(about, c[1] .. " " .. c[2] .. " " .. c[3])
  end


  return about
end

return SettingsTabComponent("about", "About", "i", setup_about);
