local common = require "core.common"
local style = {}

style.DEFAULT_FONT_SIZE = math.abs(common.round(16 * SCALE))
-- style.DEFAULT_ICON_SIZE = math.abs(common.round(17 * SCALE))
style.DEFAULT_ICON_SIZE = style.DEFAULT_FONT_SIZE

style.divider_size = common.round(1 * SCALE)
style.scrollbar_size = common.round(4 * SCALE)
style.expanded_scrollbar_size = common.round(12 * SCALE)
style.minimum_thumb_size = common.round(20 * SCALE)
style.contracted_scrollbar_margin = common.round(8 * SCALE)
style.expanded_scrollbar_margin = common.round(12 * SCALE)
style.caret_width = common.round(2 * SCALE)

style.padding = {
  x = common.round(14 * SCALE),
  y = common.round(7 * SCALE),
}

style.margin = {
  tab = {
    top = common.round(style.divider_size * SCALE)
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


-- On High DPI monitor or non RGB monitor you may consider using antialiasing grayscale instead.
-- The antialiasing grayscale with full hinting is interesting for crisp font rendering.
style.font = renderer.font.load(DATADIR .. "/fonts/FiraSans-Regular.ttf", style.DEFAULT_FONT_SIZE, {antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING})
style.bold_font = style.font:copy(style.DEFAULT_FONT_SIZE, {bold=true, antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING})
style.big_font = style.bold_font:copy(46 * SCALE)
-- style.code_font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMono-Regular.ttf", style.DEFAULT_FONT_SIZE)

style.icon_font = renderer.font.load(DATADIR .. "/fonts/icons.ttf", style.DEFAULT_ICON_SIZE, {antialiasing=FONT_SETTING_ANTIALIASING, hinting=FONT_SETTING_HINTING})
style.icon_big_font = style.icon_font:copy(23 * SCALE)

-- style.font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMonoNerdFontPropo-Regular.ttf", style.DEFAULT_FONT_SIZE)
-- style.bold_font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMonoNerdFontPropo-Bold.ttf", style.DEFAULT_FONT_SIZE)
-- style.big_font = style.font:copy(46 * SCALE)
style.code_font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMonoNerdFontPropo-Regular.ttf", style.DEFAULT_FONT_SIZE)
  
-- special font needed for "lspkind" and "autocomplete"
-- see https://www.nerdfonts.com/
-- style.kind_font = renderer.font.load(DATADIR .. "/fonts/symbols.ttf", style.DEFAULT_ICON_SIZE, {antialiasing="grayscale", hinting="full"})
style.kind_font = style.code_font

style.syntax = {}

-- This can be used to override fonts per syntax group.
-- The syntax highlighter will take existing values from this table and
-- override style.code_font on a per-token basis, so you can choose to eg.
-- render comments in an italic font if you want to.
style.syntax_fonts = {}
-- style.syntax_fonts["comment"] = renderer.font.load(path_to_font, size_of_font, rendering_options)

style.log = {}

return style
