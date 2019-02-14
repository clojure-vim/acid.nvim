-- luacheck: globals vim
local virtualtext = {}

virtualtext.cache = {}

virtualtext.ns = vim.api.nvim_create_namespace("acid")

virtualtext.set_cache  = function(cb, ln, dt_hl)
  -- TODO allow multiple possible virtual texts
  -- TODO allow cycling throught virtual texts

  local id = tostring(cb) .. ":" .. tostring(ln)
  local cache_proxy = virtualtext.cache[id]
  if cache_proxy == nil then
     cache_proxy = {curr = 0, tbl = {}}
  end

  table.insert(cache_proxy.tbl, dt_hl)
  cache_proxy.curr = cache_proxy.curr + 1

  return cache_proxy.tbl[cache_proxy.curr]
end

virtualtext.set = function(config)
  return function(middleware)
    return function(data)
      if data.status then
        return
      end

      local cb = vim.api.nvim_get_current_buf()
      local ln = vim.api.nvim_call_function("line", {"."}) - 1
      local hl
      local dt

      if data.ex ~= nil then
        dt = data.ex
        hl = "Exception"
      elseif data.err ~= nil then
        dt = data.err
        hl = "Error"
      elseif data.out ~= nil then
        dt = data.out
        hl = "String"
      elseif data.value ~= nil then
        dt = data.value
        hl = "Function"
      end
      -- TODO split_lines
      local hl_value = virtualtext.set_cache(cb, ln, {{";; => " .. dt, hl}})

      vim.api.nvim_buf_set_virtual_text(cb, virtualtext.ns, ln, hl_value, {})
      return middleware(data)
    end
  end
end

virtualtext.clear = function(ln)
  local cb = vim.api.nvim_get_current_buf()

  ln = ln and (tonumber(ln) - 1)

  local from = ln or 0
  local to = 1 + (ln or -2)

  vim.api.nvim_buf_clear_namespace(cb, virtualtext.ns, from, to)
end

virtualtext.middleware = virtualtext.set

return virtualtext
