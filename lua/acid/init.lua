-- luacheck: globals unpack vim
local nvim = vim.api

local indirection = {}
local acid = {}

acid.send = function(obj, handler)
  local session = math.random(10000, 99999)

  indirection[session] = handler

  nvim.nvim_call_function("AcidSendNrepl", {
      obj,
      "LuaFn",
      "require('acid').callback(" .. session .. ", _A)"
    })
end

acid.callback = function(session, ret)
  return indirection[session](ret)
end

return acid
