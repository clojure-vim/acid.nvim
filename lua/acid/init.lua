-- luacheck: globals table
local core = require("acid.core")

local acid = {}

acid.run = function(cmd, conn)
  return core.send(conn, cmd:build())
end

acid.callback = function(session, ret)
  local proxy = core.indirection[session]
  local new_ret = proxy.fn(ret)

  if new_ret.type == "command" then
    core.send(proxy.conn, new_ret)
  end
end

return acid
