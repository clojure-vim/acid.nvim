local utils = require("acid.utils")

local setup = function(...)
  local handlers = {}
  for _, v in ipairs(utils.pack(...)) do
    handlers[v] = require("acid.middlewares." .. v)
  end

  return handlers
end

return setup(
  "doautocmd"
)
