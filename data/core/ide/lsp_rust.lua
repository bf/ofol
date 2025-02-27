local lspconfig = require "core.ide.lsp.config"

lspconfig.rust_analyzer.setup(
  table.merge({
  command = { "rust-analyzer" }
}, {}))
