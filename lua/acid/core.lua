-- luacheck: globals unpack vim
local connections = require("acid.connections")
local core = {
  indirection = {}
}

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

  vim.api.nvim_call_function("AcidSendNrepl", { obj,
      "require('acid').callback(" .. session .. ", _A)",
      conn,
      "lua"
    })
end

return core
