-- mod-version:3

local lspconfig = require "plugins.lsp.config"
-- local common = require "core.common"
-- local config = require "core.config"

lspconfig.rust_analyzer.setup()
--   common.merge({
--   command = { full_path_to_rust_analyzer_binary }
-- }, config.plugins.lsp_rust or {}))