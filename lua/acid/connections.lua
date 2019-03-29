-- luacheck: globals vim

--- low-level connection handler
-- @module acid.connections
local nvim = vim.api
local utils = require("acid.utils")

local connections = {
  store = {},
  current = {},
}

local pwd_to_key = function(pwd)
  if not utils.ends_with(pwd, "/") then
    return pwd .. "/"
  end
  return pwd
end

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
  pwd = pwd_to_key(pwd)

  connections.current[pwd] = ix
end

--- Dissociates the connection for the given path
-- @tparam string pwd path (usually project root).
connections.unselect = function(pwd)
  pwd = pwd_to_key(pwd)

  -- TODO Potentially wrong
  connections.current[pwd] = nil
end

--- Return active connection for the given path
-- @tparam string pwd path (usually project root).
-- @treturn {string,string} Connection tuple with ip and port or nil.
connections.get = function(pwd)
  pwd = pwd_to_key(pwd)

  local ix = connections.current[pwd]

  if ix == nil then
    return nil
  end

  return connections.store[tonumber(ix)]
end

connections.search = function(pwd)
  pwd = pwd_to_key(pwd)
  local fpath = vim.api.nvim_call_function("findfile", {pwd .. ".nrepl-port"})
  if fpath ~= "" then
    local portno = table.concat(vim.api.nvim_call_function("readfile", {fpath}), "")
    local conn = {"127.0.0.1", utils.trim(portno)}
    return connections.add(conn)
  end
  return nil
end

connections.attempt_get = function(pwd)
  local conn = connections.get(pwd)
  if conn == nil then
    local ix = connections.search(pwd)
    if ix ~= nil then
      connections.select(pwd, ix)
      conn = connections.store[ix]
    else
      return nil
    end
  end
  return conn
end

--- Add and select the given connection for given path.
-- @tparam string pwd path (usually project root).
-- @tparam {string,string} Connection tuple with ip and port or nil.
connections.set = function(pwd, addr)
  connections.select(pwd, connections.add(addr))
end

return connections
