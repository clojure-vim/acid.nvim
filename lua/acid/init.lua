-- luacheck: globals table
local core = require("acid.core")
local features = require("acid.features")

local acid = {}

acid.run = function(cmd, conn)
  return core.send(conn, cmd:build())
end

acid.callback = function(session, ret)
  return core.indirection[session](ret)
end

return acid
