local command = require "core.command"
local common = require "core.common"

command.add(nil, {
  ["files:create-directory"] = function()
    core.command_view:enter("New directory name", {
      submit = function(text)
        local success, err, path = fsutils.mkdirp(text)
        if not success then
          stderr.error("cannot create directory %q: %s", path, err)
        end
      end
    })
  end,
})
