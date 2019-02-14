local utils = require("acid.utils")
local config = require("acid.config").middlewares

local nop_handler = function(data) return data end

local function builder(tbl, key)
  if key == "ex" then
    return setmetatable(utils.merge(tbl, {ex = true}), {__index = builder})
  elseif key == "noconfig" then
    return setmetatable(utils.merge(tbl, {noconfig = true}), {__index = builder})
  else
    return setmetatable(utils.merge(tbl, {key = key}), {__call = function(this, data)
      local middleware = require("acid.middlewares." .. this.key).middleware
      local handler

      if this.ex ~= nil then
        if this.noconfig ~= nil then
          handler = function(cfg) return middleware(cfg)(nop_handler) end
        else
          handler = middleware(config[key])(nop_handler)
        end
      else
        if this.noconfig ~= nil then
          handler = middleware
        else
          handler = middleware(config[key])
        end
      end

      return handler(data)
    end})
  end

end

return setmetatable({}, {__index = function(_, key)
  return builder({}, key)
end})
