-- luacheck: globals vim
local err = {}

local cache = {}

err.middleware = function(config)
  return function(middleware)
    return function(data)
      local has_err = false
      if data.ex ~= nil then
        has_err = true
        table.insert(cache, data.ex)
      end
      if data.err ~= nil then
        has_err = true
        table.insert(cache, data.err)
      end

      if not has_err or not config.bail_out then
        return middleware(data)
      end
    end
  end
end

err.show = function(ix)
  ix = ix or 0
  local sz = #cache
  local pos = sz - ((sz - ix) % sz)
  vim.api.nvim_err_writeln(cache[pos])
end

err.clear = function()
  cache = {}
end

return err
