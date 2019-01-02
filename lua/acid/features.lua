local nvim = vim.api
local commands = require("acid.commands").ops
local handlers = require("acid.handlers")

local features = {}

features.go_to = function(symbol, ns)
  return commands.info{symbol = symbol, ns = ns}:with_handler(handlers.go_to)
end

features.list_usage = function(callback, symbol, ns)
  local handle = function(data)
    local pwd = nvim.nvim_call_function('getcwd', {})
    local fname = nvim.nvim_call_function('expand' ,{"%:p"})

    return commands['find-symbol']{
        path = pwd,
        file = fname,
        ns = data.ns,
        name = data.name,
        line = math.floor(data.line or 1),
        column = math.floor(data.column or 1),
        ['serialization-format'] = 'bencode'
      }:with_handler(callback)
  end

  return commands.info{symbol = symbol, ns = ns}:with_handler(handle)
end


return features
