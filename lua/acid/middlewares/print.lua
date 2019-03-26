-- luacheck: globals vim
local do_print = {}
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

      return middleware(data)
    end
  end
end

return do_print
