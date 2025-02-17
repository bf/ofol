-- mod-version:3

local lspconfig = require "core.ide.lsp.config"
local common = require "core.common"
local config = require "core.config"

lspconfig.rust_analyzer.setup(
  table.merge({
  command = { "rust-analyzer" }
}, config.plugins.lsp_rust or {}))

 -- lspconfig.rust_analyzer.setup()