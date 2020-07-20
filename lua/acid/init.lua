-- luacheck: globals vim

--- Frontend module with most relevant functions
-- @module acid

local core = require("acid.core")
local connections = require("acid.connections")
local utils = require("acid.utils")
local sessions = require("acid.sessions")
local admin_session_path
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
  local filtered = cmd:update_payload(sessions.filter)
  return core.send(conn, filtered:build())
end


--- Callback proxy for handling command responses
-- @param ret The response from nrepl
acid.callback = function(ret)
  local proxy = core.indirection[ret.id]

  --if proxy == nil then
    ----TODO log
  --end

  local new_ret = proxy.fn(ret)

  if type(new_ret) == "table" and new_ret.type == "command" then
    core.send(proxy.conn, new_ret:build())
  else
    return new_ret
  end
end

--- Setup admin nrepl session
-- This nrepl session should be used by plugins to deal with clojure code
-- without injecting things in the user nrepl session
-- or for things that clojure could deal with better while not having a
-- nrepl session to use.
acid.admin_session_start = function()
  local nrepl = require("acid.nrepl")
  if admin_session_path == nil then
    admin_session_path = utils.ensure_path(
      vim.fn.fnamemodify(vim.fn.findfile("admin_deps.edn", vim.api.nvim_get_option('rtp')), ":p:h")
    )
  end

  if nrepl.cache[admin_session_path] ~= nil then
    return acid.admin_session()
  end

  nrepl.bbnrepl{
    pwd = admin_session_path,
  }
end

acid.admin_session = function()

  local conn = connections.get(admin_session_path)

  if conn ~= nil and conn[2] ~= nil then
    return conn
  end
  return
end

return acid
