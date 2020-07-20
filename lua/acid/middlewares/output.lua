-- luacheck: globals vim
local do_print = {}
local output = require("acid.output")
local sessions = require("acid.sessions")
local utils = require("acid.utils")
local log = require("acid.log")

output.middleware = function(config)
  return function(middleware)
    return function(data)
      local session = data.session
      local conn_id = sessions.reverse_lookup(session)

      if data.out ~= nil then
        output.draw(conn_id, data.out)
      end
      if data.value ~= nil then
        output.draw(conn_id, "=> " .. data.value)
      end
      if data.ex ~= nil then
        output.draw(conn_id, "!! " .. data.ex)
      end
      if data.err ~= nil then
        local out = {}
        output.draw(conn_id, data.err)
      end

      if config.accessor ~= nil then
        local msg = config.accessor(data)
        if msg ~= nil and msg ~= "" then
          output.draw(conn_id, "<> " .. msg)
        end
      end

      return middleware(data)
    end
  end
end

return output
