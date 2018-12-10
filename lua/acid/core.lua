-- luacheck: globals unpack vim
local nvim = vim.api
local connections = require("acid.connections")
local core = {
  indirection = {}
}

core.send = function(conn, obj, handler)
  local session = math.random(10000, 99999)

  conn = conn or connections:get(nvim.nvim_call_function("getcwd", {}))

  core.indirection[session] = handler

  nvim.nvim_call_function("AcidSendNrepl", {
      obj,
      "require('acid').callback(" .. session .. ", _A)",
      conn,
      "lua"
    })
end

return core
