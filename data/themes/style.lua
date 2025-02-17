local color_from_css_string = require "themes.color_from_css_string"

local style = {}


style.DEFAULT_FONT_SIZE = math.round(16 * SCALE)

-- stderr.error("DEFAULT_FONT_SIZE %s %f %f", style.DEFAULT_FONT_SIZE, style.DEFAULT_FONT_SIZE, SCALE)

-- style.DEFAULT_ICON_SIZE = math.abs(math.round(17 * SCALE))
style.DEFAULT_ICON_SIZE = style.DEFAULT_FONT_SIZE

style.divider_size = math.round(1 * SCALE)
style.scrollbar_size = math.round(4 * SCALE)
style.expanded_scrollbar_size = math.round(12 * SCALE)
style.minimum_thumb_size = math.round(20 * SCALE)
style.contracted_scrollbar_margin = math.round(8 * SCALE)
style.expanded_scrollbar_margin = math.round(12 * SCALE)
style.caret_width = math.round(2 * SCALE)

style.padding = {
  x = math.round(14 * SCALE),
  y = math.round(7 * SCALE),
}

style.margin = {
  tab = {
    top = math.round(style.divider_size * SCALE)
  }
}

-- The function renderer.font.load can accept an option table as a second optional argument.
-- It shoud be like the following:
--
-- {antialiasing= "grayscale", hinting = "full"}
--
-- The possible values for each option are:
-- - for antialiasing: grayscale, subpixel
-- - for hinting: none, slight, full
--
-- The defaults values are antialiasing subpixel and hinting slight for optimal visualization
-- on ordinary LCD monitor with RGB patterns.
--
local FONT_SETTING_ANTIALIASING="subpixel"
local FONT_SETTING_HINTING="slight"

local FONT_DEFAULT = DATADIR .. "/static/fonts/FiraSans-Regular.ttf"
-- local FONT_DEFAULT = DATADIR .. "/fonts/JetBrainsMono-Regular.ttf"
local FONT_DEFAULT_BOLD = DATADIR .. "/static/fonts/FiraSans-Medium.ttf"
local FONT_ICONS = DATADIR .. "/static/fonts/icons.ttf"
local FONT_MONOSPACE = DATADIR .. "/static/fonts/JetBrainsMonoNerdFontPropo-Regular.ttf"

-- On High DPI monitor or non RGB monitor you may consider using antialiasing grayscale instead.
-- The antialiasing grayscale with full hinting is interesting for crisp font rendering.
style.font = renderer.font.load(FONT_DEFAULT, style.DEFAULT_FONT_SIZE, {antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING})
style.bold_font = renderer.font.load(FONT_DEFAULT_BOLD, style.DEFAULT_FONT_SIZE, {antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING}) 
style.big_font = renderer.font.load(FONT_DEFAULT_BOLD, 46 * SCALE, {antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING}) 
-- style.code_font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMono-Regular.ttf", style.DEFAULT_FONT_SIZE)

style.icon_font = renderer.font.load(FONT_ICONS, style.DEFAULT_ICON_SIZE, {antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING})
style.icon_big_font = renderer.font.load(FONT_ICONS, 23 * SCALE, {antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING})

-- style.font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMonoNerdFontPropo-Regular.ttf", style.DEFAULT_FONT_SIZE)
-- style.bold_font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMonoNerdFontPropo-Bold.ttf", style.DEFAULT_FONT_SIZE)
-- style.big_font = style.font:copy(46 * SCALE)
style.code_font = renderer.font.load(FONT_MONOSPACE, style.DEFAULT_FONT_SIZE, {antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING})

-- special font needed for "lspkind" and "autocomplete"
-- see https://www.nerdfonts.com/
-- style.kind_font = renderer.font.load(DATADIR .. "/fonts/symbols.ttf", style.DEFAULT_ICON_SIZE, {antialiasing="grayscale", hinting="full"})
style.kind_font = style.code_font

style.syntax = {}


-- we need these symbol types to have uniform colors
style.syntax["diff_add"] = { color_from_css_string("#72b886") }
style.syntax["diff_del"] = { color_from_css_string("#F36161") }
style.syntax["ignore"] = { color_from_css_string("#72B886") }
style.syntax["exclude"] = { color_from_css_string("#F36161") }


-- This can be used to override fonts per syntax group.
-- The syntax highlighter will take existing values from this table and
-- override style.code_font on a per-token basis, so you can choose to eg.
-- render comments in an italic font if you want to.
style.syntax_fonts = {}
-- style.syntax_fonts["comment"] = renderer.font.load(path_to_font, size_of_font, rendering_options)

style.log = {}

return style
