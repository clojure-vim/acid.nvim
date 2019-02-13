local utils = require("acid.utils")

local setup = function(...)
  local handlers = {
    nop_handler = function(data) return data end,
  }

  handlers.nop = {handler = handlers.nop_handler}

  for _, v in ipairs(utils.pack(...)) do
    handlers[v] = require("acid.middlewares." .. v)
  end

  return handlers
end

return setup(
  "doautocmd",
  "go_to",
  "doc",
  "print",
  "virtualtext"
)
