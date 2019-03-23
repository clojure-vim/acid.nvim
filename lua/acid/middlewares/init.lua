local utils = require("acid.utils")

local nop = function(data) return data end

local err = require("acid.middlewares.err").middleware{}(nop)


local function builder(tbl, outer, key)
  local middleware = require("acid.middlewares." .. key)
  return function(config)
    local cfg = utils.merge(middleware.config or {}, config)
    local handler = middleware.middleware(cfg)(outer)
    return setmetatable(tbl, {
        __index = function(this, data)
          return builder(this, handler, data)
        end,
        __call = function(_, data)
          return handler(data)
        end
      })
  end
end

return setmetatable({}, {__index = function(_, key) return builder({}, err, key) end})
