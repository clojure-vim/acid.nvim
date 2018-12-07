local commands = require("acid.commands")
local handlers = require("acid.handlers")
local core = require("acid.core")

local acid = {
  commands = commands,
  handlers = handlers
}

acid.run = function(data, conn) return core.send(conn, data()) end

acid.callback = function(session, ret)
  return core.indirection[session](ret)
end

return acid
