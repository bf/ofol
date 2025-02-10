-- -- load context menu for doc
-- require "core.ide.contextmenu_in_docview"

-- load lintplus explicitly
-- local lintplus = require "core.ide.lintplus"
-- lintplus.load("rust")
-- lintplus.setup.lint_on_doc_load()
-- lintplus.setup.lint_on_doc_save()

-- load scm plugin
local scm = require "core.ide.scm"
-- load scm context menu for treeview
local treeview_context_menu_from_scm = require "core.ide.scm.treeview"

-- load build plugin
local build = require "core.ide.build"

-- load language server
local lsp_snippets = require "core.ide.lsp_snippets"
local lsp = require "core.ide.lsp"
local lsp_rust = require "core.ide.lsp_rust"

-- -- load autocomplete
local lspkind = require "core.ide.lspkind"
local autoinsert = require "core.ide.autoinsert"
local autocomplete = require "core.ide.autocomplete"

