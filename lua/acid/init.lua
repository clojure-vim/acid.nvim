-- luacheck: globals vim

--- Frontend module with most relevant functions
-- @module acid

local core = require("acid.core")
local connections = require("acid.connections")
local utils = require("acid.utils")

local acid = {}

--- Checks whether a connection exists for supplied path or not.
-- @tparam[opt] string pwd Path bound to connection.
-- Will call `getcwd` on neovim if not supplied
-- @treturn boolean Whether a connection exists or not.
acid.connected = function(pwd)
  pwd = pwd or vim.api.nvim_call_function("getcwd", {})

  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  return connections.current[pwd] ~= nil
end

--- Façade to core.send
-- @param cmd A command (op + payload + handler) to be executed.
-- @param conn A connection where this command will be run.
acid.run = function(cmd, conn)
  return core.send(conn, cmd:build())
end


--- Callback proxy for handling command responses
-- @param session Session ID for matching response with request
-- @param ret The response from nrepl
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
