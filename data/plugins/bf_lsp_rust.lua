-- mod-version:3

local lspconfig = require "plugins.lsp.config"
local common = require "core.common"
local config = require "core.config"

-- returns true if file exists
local function file_exists(name)
   local f <close> = io.open(name, "r")
   return f ~= nil
end

-- directory where rust-analyzer binary is stored after download
local base_path = USERDIR .. PATHSEP .. "plugins" .. PATHSEP .. "lsp_rust"

-- name of binary
local rust_analyzer_binary_name 

-- use different binary depending on OS
if PLATFORM == "Windows" then
  -- use downloaded version for windows
  rust_analyzer_binary_name = "rust-analyzer.exe"
elseif PLATFORM == "Mac OS X" then
  -- use downloaded version for macos
  if ARCH == "aarch64-darwin" then
    rust_analyzer_binary_name = "rust-analyzer-aarch64-apple-darwin"
  else
    rust_analyzer_binary_name = "rust-analyzer-x86_64-apple-darwin"
  end
else
  -- when rust is installed, this is default path on linux
  if file_exists("/usr/bin/rust-analyzer") then
    base_path = "/usr/bin"
    rust_analyzer_binary_name = "rust-analyzer"
  else
    -- did not find rust installation, use downloaded version
    if ARCH == "aarch64-linux" then
      rust_analyzer_binary_name = "rust-analyzer-aarch64-unknown-linux-gnu"
    else
      rust_analyzer_binary_name = "rust-analyzer-x86_64-unknown-linux-gnu"
    end
  end
end

local full_path_to_rust_analyzer_binary = base_path .. PATHSEP .. rust_analyzer_binary_name

lspconfig.rust_analyzer.setup(common.merge({
  command = { full_path_to_rust_analyzer_binary }
}, config.plugins.lsp_rust or {}))
