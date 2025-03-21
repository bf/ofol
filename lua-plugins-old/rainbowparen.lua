-- mod-version:3
local core = require "core"
local style = require "themes.style"
local config = require "core.config"
local command = require "core.command"
local tokenizer = require "core.doc.tokenizer"
local Highlighter = require "core.doc.highlighter"
local color_from_css_string = require "themes.color_from_css_string"

config.plugins.rainbowparen = table.merge({
  enabled = true,
  parens = 5
}, config.plugins.rainbowparen)

style.syntax.paren_unbalanced = style.syntax.paren_unbalanced or { color_from_css_string "#DC0408" }
style.syntax.paren1  =  style.syntax.paren1 or { color_from_css_string "#FC6F71"}
style.syntax.paren2  =  style.syntax.paren2 or { color_from_css_string "#fcb053"}
style.syntax.paren3  =  style.syntax.paren3 or { color_from_css_string "#fcd476"}
style.syntax.paren4  =  style.syntax.paren4 or { color_from_css_string "#52dab2"}
style.syntax.paren5  =  style.syntax.paren5 or { color_from_css_string "#5a98cf"}

local tokenize = tokenizer.tokenize
local extract_subsyntaxes = tokenizer.extract_subsyntaxes
local closers = {
  ["("] = ")",
  ["["] = "]",
  ["{"] = "}"
}

local function parenstyle(parenstack)
  return "paren" .. ((#parenstack % config.plugins.rainbowparen.parens) + 1)
end

function tokenizer.extract_subsyntaxes(base_syntax, state)
  if not config.plugins.rainbowparen.enabled then
    return extract_subsyntaxes(base_syntax, state)
  end
  return extract_subsyntaxes(base_syntax, state.istate)
end

function tokenizer.tokenize(syntax, text, state, resume)
  if not config.plugins.rainbowparen.enabled then
    return tokenize(syntax, text, state, resume)
  end
  state = state or {}
  local res, istate, resume = tokenize(syntax, text, state.istate, resume)
  local parenstack = state.parenstack or ""
  local newres = {}
  -- split parens out
  -- the stock tokenizer can't do this because it merges identical adjacent tokens
  for i, type, text in tokenizer.each_token(res) do
    if type == "normal" or type == "symbol" then
      for normtext1, paren, normtext2 in text:gmatch("([^%(%[{}%]%)]*)([%(%[{}%]%)]?)([^%(%[{}%]%)]*)") do
        if #normtext1 > 0 then
          table.insert(newres, type)
          table.insert(newres, normtext1)
        end
        if #paren > 0 then
          if paren == parenstack:sub(-1) then -- expected closer
            parenstack = parenstack:sub(1, -2)
            table.insert(newres, parenstyle(parenstack))
          elseif closers[paren] then -- opener
            table.insert(newres, parenstyle(parenstack))
            parenstack = parenstack .. closers[paren]
          else -- unexpected closer
            table.insert(newres, "paren_unbalanced")
          end
          table.insert(newres, paren)
        end
        if #normtext2 > 0 then
          table.insert(newres, type)
          table.insert(newres, normtext2)
        end
      end
    else
      table.insert(newres, type)
      table.insert(newres, text)
    end
  end
  return newres, { parenstack = parenstack, istate = istate }, resume
end

local function toggle_rainbowparen(enabled)
  config.plugins.rainbowparen.enabled = enabled
  for _, doc in ipairs(core.docs) do
    doc.highlighter = Highlighter(doc)
    doc:reset_syntax()
  end
end

-- The config specification used by the settings gui
config.plugins.rainbowparen.config_spec = {
  name = "Rainbow Parentheses",
  {
    label = "Enable",
    description = "Activates rainbow parenthesis coloring by default.",
    path = "enabled",
    type = "toggle",
    default = true,
    on_apply = function(enabled)
      toggle_rainbowparen(enabled)
    end
  }
}

command.add(nil, {
  ["rainbow-parentheses:toggle"] = function()
    toggle_rainbowparen(not config.plugins.rainbowparen.enabled)
  end
})
