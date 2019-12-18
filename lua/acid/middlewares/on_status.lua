-- luacheck: globals vim
local on_status = {}
local utils = require("acid.utils")

on_status.middleware = function(config)
  return function(middleware)
    return function(data)
      if data.status ~= nil then
        if utils.find(data.status, config.condition) then
          config.action(data)
        end
      end
      return middleware(data)
    end
  end
end

return on_status

