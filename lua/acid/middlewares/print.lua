-- luacheck: globals vim
local do_print = {}
local utils = require("acid.utils")
local log = require("acid.log")

do_print.middleware = function(config)
  return function(middleware)
    return function(data)
      if data.out ~= nil then
        log.msg(data.out)
      end
      if data.value ~= nil then
        log.msg(data.value)
      end
      if data.ex ~= nil then
        log.msg(data.ex)
      end
      if data.err ~= nil then
        log.msg(data.err)
      end

      if config.accessor ~= nil then
        local msg = config.accessor(data)
        if msg ~= nil and msg ~= "" then
          log.msg(msg)
        end
      end

      if utils.find(config.status, "namespace-not-found") then
        log.msg("Namespace not found")
      elseif utils.find(config.status, "error") then
        log.msg("Error")
      end

      return middleware(data)
    end
  end
end

return do_print
