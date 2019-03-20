-- luacheck: globals unpack vim

--- low-level connection handler.
-- @module acid.core
-- @todo merge with acid and acid.connections
local connections = require("acid.connections")

local core = {
  indirection = {}
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

  local session = math.random(10000, 99999)

  conn = conn or connections:get(vim.api.nvim_call_function("getcwd", {}))

  core.indirection[session] = {
    fn = handler,
    conn = conn
  }

  vim.api.nvim_call_function("AcidSendNrepl", {obj,
      "require('acid').callback(" .. session .. ", _A)",
      conn,
      "lua"
    })
end

return core
