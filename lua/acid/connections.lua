-- luacheck: globals vim

--- low-level connection handler
-- @module acid.connections
local nvim = vim.api
local utils = require("acid.utils")

local connections = {
  store = {},
  current = {},
}

--- Stores connection for reuse later
-- @tparam {string,string} addr Address tuple with ip and port.
connections.add = function(addr)
  table.insert(connections.store, addr)
  return #connections.store
end

connections.remove = function(addr)
  local ix
  for i, v in ipairs(connections.store) do
    if v[2] == addr[2] and v[1] == addr[1] then
      ix = i
      break
    end
  end
  table.remove(connections.store, ix)

  for pwd, v in pairs(connections.current) do
    if v[2] == addr[2] and v[1] == addr[1] then
      connections.current[pwd] = nil
    end
  end
end

--- Elects selected connection as primary (thus default) for a certain address
-- @tparam string pwd path (usually project root).
-- Assumed to be neovim's `pwd`.
-- @tparam int ix index of the stored connection
connections.select = function(pwd, ix)
  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  connections.current[pwd] = ix
end

--- Dissociates the connection for the given path
-- @tparam string pwd path (usually project root).
connections.unselect = function(pwd)
  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  -- TODO Potentially wrong
  connections.current[pwd] = nil
end

--- Return active connection for the given path
-- @tparam string pwd path (usually project root).
-- @treturn {string,string} Connection tuple with ip and port or nil.
connections.get = function(pwd)
  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  local ix = connections.current[pwd]

  if ix == nil then
    return nil
  end

  return connections.store[tonumber(ix)]
end

--- Add and select the given connection for given path.
-- @tparam string pwd path (usually project root).
-- @tparam {string,string} Connection tuple with ip and port or nil.
connections.set = function(pwd, addr)
  connections.select(pwd, connections.add(addr))
end

return connections
