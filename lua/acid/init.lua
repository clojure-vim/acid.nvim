-- luacheck: globals vim
local core = require("acid.core")
local connections = require("acid.connections")
local utils = require("acid.utils")

local acid = {}

acid.connected = function(pwd)
  pwd = pwd or vim.api.nvim_call_function("getcwd", {})

  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  return connections.current[pwd] ~= nil
end

acid.run = function(cmd, conn)
  return core.send(conn, cmd:build())
end

acid.callback = function(session, ret)
  local proxy = core.indirection[session]
  local new_ret = proxy.fn(ret)

  if type(new_ret) == "table" and new_ret.type == "command" then
    core.send(proxy.conn, new_ret:build())
  else
    return new_ret
  end
end

return acid
