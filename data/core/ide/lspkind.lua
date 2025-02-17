-- mod-version:3
local style = require 'themes.style'
local util = require 'core.ide.lsp.util'
local Server = require 'core.ide.lsp.server'

local kindPresets = {
	default = {
		Text = '',
		Method = '',
		Function = '',
		Constructor = '',
		Field = 'ﰠ',
		Variable = '',
		Class = 'ﴯ',
		Interface = '',
		Module = '',
		Property = 'ﰠ',
		Unit = '塞',
		Value = '',
		Enum = '',
		Keyword = '',
		Snippet = '',
		Color = '',
		File = '',
		Reference = '',
		Folder = '',
		EnumMember = '',
		Constant = '',
		Struct = 'פּ',
		Event = '',
		Operator = '',
		TypeParameter = '',
		Unknown = ''
	}
}
local defaultOpts = {
	format = 'symbolText',
	fontName = 'Nerd Font',
	size = 14 * SCALE
}
local formatters = {}

function formatters.text(_, name)
	return name
end
function formatters.symbol(symbol, _)
	return symbol
end
function formatters.symbolText(symbol, name)
	return symbol .. ' ' .. name
end
function formatters.textSymbol(symbol, name)
	return name .. ' ' .. symbol
end

local function font(name, size)
	local proc = process.start {'sh', '-c', 'fc-list | grep "' .. name ..'"'}
	if proc then
		proc:wait(process.WAIT_INFINITE)
		local out = proc:read_stdout() or ''
		local file = util.split(out, ':')[1]

		return renderer.font.load(file, size)
	end
end

local function getKindName(id)
	return Server.completion_item_kind[id]
end

local function getKind(id, symbols)
	local kindName = getKindName(id)
	if not kindName then
		return symbols.Unknown, 'Unknown'
	end
	local kindIcon = symbols[kindName]

	return kindIcon, kindName
end

local M = {}

--- Setup Lspkind icons
--- @param opts table
function M.setup(opts)
	opts = table.merge(defaultOpts, opts)
	local symbols = table.merge(kindPresets.default, opts.symbols)

	-- set style.kind_font in style.lua
	-- if opts.font_raw then
	-- 	style.kind_font = opts.font_raw
	-- else
	-- 	style.kind_font = font(opts.fontName, opts.size)
	-- end

	local formatKind
	if type(opts.format) == 'function' then
		formatKind = opts.format
	else
		local formatFunc = formatters[opts.format]
		if not formatFunc then formatFunc = formatters.text end

		formatKind = formatFunc
	end

	function Server.get_completion_item_kind(id)
		local symbol, name = getKind(id, symbols)
		return formatKind(symbol, name)
	end
end

return M
