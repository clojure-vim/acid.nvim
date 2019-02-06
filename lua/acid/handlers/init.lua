local utils = require("acid.utils")

local setup = function(...)
  local handlers = {}
  for _, v in ipairs(utils.pack(...)) do
    handlers[v] = require("acid.handlers." .. v)
  end

  return handlers
end

return setup(
  "go_to",
  "doc"
)
