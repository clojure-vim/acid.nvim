-- luacheck: globals unpack vim

--- low-level connection handler.
-- @module acid.core
-- @todo merge with acid and acid.connections
local connections = require("acid.connections")
local utils = require("acid.utils")
local log = require("acid.log")

local core = {
  indirection = setmetatable({}, utils.LRU(10))
}

--- Forward messages to the nrepl and registers the handler.
-- @tparam[opt] {string,string} conn Ip and Port tuple. Will try to get one if nil.
-- @tparam table obj Payload to be sent to the nrepl.
-- @tparam function handler Handler function to deal with the response.
core.send = function(conn, obj, handler)
  if handler == nil then
    vim.api.nvim_err_writeln("Please provide a handler for that operation.")
    return
  end

  local pwd = vim.api.nvim_call_function("getcwd", {})

  conn = conn or connections.attempt_get(pwd)

  if conn == nil then
    log.msg("No active connection to a nrepl session. Aborting")
  end

  if obj.id == nil then
    obj.id = utils.ulid()
  end

  local session = core.register_callback(conn, handler, obj.id)

  vim.api.nvim_call_function("AcidSendNrepl", {obj,
      session,
      conn
    })

end

core.register_callback = function(conn, handler, session)
  -- Random number from 0 .. 9999999999
  session = session or utils.random(10)
  core.indirection[session] = {
    fn = handler,
    conn = conn
  }
  return session
end

return core
