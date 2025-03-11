-- global include of stderr logging
stderr = require("lib.stderr")

-- global modification of module loading behavior when require() is called
require("lib.lua-monkeypatch.lua-monkeypatch-require-modules")

-- global try/catch functionality 
require("lib.lua-monkeypatch.lua-monkeypatch-try-catch")

-- global strict variable checking, e.g. error when undefined variable is set/get
require("lib.lua-monkeypatch.lua-monkeypatch-strict-variable-checking")

-- global monkeypatches for lua standard types and modules
require("lib.lua-monkeypatch.lua-monkeypatch-bit32")
require("lib.lua-monkeypatch.lua-monkeypatch-string")
require("lib.lua-monkeypatch.lua-monkeypatch-math")
require("lib.lua-monkeypatch.lua-monkeypatch-regex")
require("lib.lua-monkeypatch.lua-monkeypatch-process")
require("lib.lua-monkeypatch.lua-monkeypatch-table")

-- global monkeypatch for SDL3 C API
require("lib.lua-monkeypatch.lua-monkeypatch-renderer")

-- graphics/rendering rect clipping code
clipping = require("lib.clipping")

-- global include of fsutils
fsutils = require("lib.fsutils")

-- global include for json
json = require("lib.json")

-- global include for json config file
json_config_file = require("lib.json_config_file")

-- threading code
threading = require("lib.threading")

-- global include for base object model 
Object = require("models.object")

-- global include of validator
Validator = require("lib.validator")

-- global include for user configuration
PersistentUserConfiguration = require("persistence.persistent_user_configuration")
ConfigurationOptionStore = require("stores.configuration_option_store")

-- load available configuration options
require("configuration")
