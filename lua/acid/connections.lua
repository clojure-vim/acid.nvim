-- luacheck: globals vim
local nvim = vim.api
local connections = {
  store = {},
  current = {},
}

connections.add = function(this, addr)
  table.insert(this.store, addr)
  return #this.store
end

connections.remove = function(this, addr)
  local ix
  for i, v in ipairs(this.store) do
    if v == addr then
      ix = i
      break
    end
  end
  table.remove(connections.store, ix)
end

connections.select = function(this, pwd, ix)
  this.current[pwd] = ix
end

connections.unselect = function(this, pwd)
  -- TODO Potentially wrong.
  this.current[pwd] = nil
end

connections.get = function(this, pwd)
  local ix = this.current[pwd]

  if ix == nil then
    local port_file = pwd .. '/.nrepl-port'
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
