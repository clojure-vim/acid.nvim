-- luacheck: globals vim
local interrupt = {}
local ops = require("acid.ops")

interrupt.cache = {}

interrupt.register = function(msg)
  if msg.id == nil then
    msg.id = vim.api.nvim_call_function("AcidNewUUID", {})
  end

  interrupt.cache[msg.id] = msg

  return msg
end

interrupt.interrupt = function(id)
  if interrupt.cache[id] ~= nil then
    return ops['interrupt']{session = interrupt.cache[id].session, ['interrupt-id'] = id}
  end
end

interrupt.middleware = function(_)
  return function(middleware)
    return function(data)

      if data.status ~= nil then
        interrupt.cache[data.id] = nil
      end

      return middleware(data)
    end
  end
end



return interrupt
