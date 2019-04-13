-- luacheck: globals vim
local do_print = {}
local log = require("acid.log")

do_print.name = "do_print"

do_print.middleware = function(config)
  return function(middleware)
    return function(data, calls)
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

      return middleware(data, table.insert(calls, do_print.name))
    end
  end
end

return do_print
