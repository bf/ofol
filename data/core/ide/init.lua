-- load scm plugin
local scm = require "core.ide.scm"

-- load language server
local lsp = require "core.ide.lsp"
local lsp_rust = require "core.ide.lsp_rust"

-- load autocomplete
local lspkind = require "core.ide.lspkind"
local autocomplete = require "core.ide.autocomplete"

-- load build plugin
local build = require "core.ide.build"
