
-- load lintplus explicitly
local lintplus = require "core.ide.lintplus"
-- lintplus.load("rust")
-- lintplus.setup.lint_on_doc_load()
-- lintplus.setup.lint_on_doc_save()


-- load scm plugin
local scm = require "core.ide.scm"

-- load build plugin
local build = require "core.ide.build"

-- load language server
local lsp = require "core.ide.lsp"
local lsp_rust = require "core.ide.lsp_rust"

-- -- load autocomplete
-- local lspkind = require "core.ide.lspkind"
-- local autocomplete = require "core.ide.autocomplete"
