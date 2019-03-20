-- luacheck: globals vim

local ops = require("acid.ops")

-- TODO split into folder
local commands = {}

commands.go_to = function(obj)
  return ops.info{symbol = obj.symbol, ns = obj.ns}
end

commands.list_usage = function(callback, symbol, ns, pwd, fname)

  local handle = function(data)
    return ops['find-symbol']{
        path = pwd,
        file = fname,
        ns = data.ns,
        name = data.name,
        line = math.floor(data.line or 1),
        column = math.floor(data.column or 1),
        ['serialization-format'] = 'bencode'
      }:with_handler(callback)
  end

  return ops.info{symbol = symbol, ns = ns}:with_handler(handle)
end

commands.req = function(obj)

  local code = "(require '[" ..
    obj.ns ..
    (obj.alias ~= nil and (" :as " .. obj.alias) or "") ..
    (#obj.refer > 0 and (" :refer [" .. table.concat(obj.refer, " ") .. "]") or "") ..
    " :reload :all])"

  return ops.eval{code = code}
end

commands.ns_load_all = function()
  return ops['ns-load-all']{}
end

commands.preload = function(obj)
  local cmds = {}
  local rtp = vim.api.nvim_get_option('rtp')
  for _, path in ipairs(obj.files) do
    local fpath = vim.api.nvim_call_function("findfile", {path, rtp})
    local contents = vim.api.nvim_call_function("readfile", {fpath})
    table.insert(cmds, ops['load-file']{file = table.concat(contents, "\n")})
  end
  return cmds
end

commands.import = function(obj)
  local code = "(import '(" ..  obj.java_ns .. ' ' .. table.concat(obj.symbols, " ") .. "))"
 return ops.eval{code = code}
end

return commands
