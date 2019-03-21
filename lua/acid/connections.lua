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
-- @tparam table this Connections object.
-- @tparam {string,string} addr Address tuple with ip and port.
connections.add = function(this, addr)
  table.insert(this.store, addr)
  return #this.store
end

connections.remove = function(this, addr)
  local ix
  for i, v in ipairs(this.store) do
    if v[2] == addr[2] and v[1] == addr[1] then
      ix = i
      break
    end
  end
  table.remove(connections.store, ix)

  for pwd, v in pairs(this.current) do
    if v[2] == addr[2] and v[1] == addr[1] then
      this.current[pwd] = nil
    end
  end
end

--- Elects selected connection as primary (thus default) for a certain address
-- @tparam table this Connections object.
-- @tparam string pwd path (usually project root).
-- Assumed to be neovim's `pwd`.
-- @tparam int ix index of the stored connection
connections.select = function(this, pwd, ix)
  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  this.current[pwd] = ix
end

--- Dissociates the connection for the given path
-- @tparam table this Connections object.
-- @tparam string pwd path (usually project root).
connections.unselect = function(this, pwd)
  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  -- TODO Potentially wrong
  this.current[pwd] = nil
end

--- Return active connection for the given path
-- @tparam table this Connections object.
-- @tparam string pwd path (usually project root).
-- @treturn {string,string} Connection tuple with ip and port.
connections.get = function(this, pwd)
  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  local ix = tonumber(this.current[pwd])

  if ix == nil then
    local port_file = pwd .. '.nrepl-port'
    if nvim.nvim_call_function('filereadable', {port_file}) then
      local port = nvim.nvim_call_function('readfile', {port_file})
      ix = this:add({'127.0.0.1', port[1]})
      this:select(pwd, ix)
    else
      if #this.store >= 1 then
        ix = #this.store
      else
        return
      end
    end
  end

  return this.store[ix]
end

return connections
