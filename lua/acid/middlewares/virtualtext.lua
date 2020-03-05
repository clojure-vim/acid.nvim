-- luacheck: globals vim
local virtualtext = {}

virtualtext.name = "virtualtext"

virtualtext.cache_index = {}
virtualtext.cache = {}

virtualtext.ns = vim.api.nvim_create_namespace("acid")

virtualtext.toggle = function()
  local cb = vim.api.nvim_get_current_buf()
  local ln = vim.api.nvim_call_function("line", {"."}) - 1
  local key = tostring(cb) .. "/" .. tostring(ln)


  local possible_vts = virtualtext.cache[key]
  local current_ix = virtualtext.cache_index[key]

  if #possible_vts > 1 then
    current_ix = current_ix - 1
    if current_ix == 0 then
      current_ix = #possible_vts
    end
  end

  vim.api.nvim_buf_set_virtual_text(cb, virtualtext.ns, ln, possible_vts[current_ix], {})
  virtualtext.cache_index[key] = current_ix

end

virtualtext.middleware = function(config)
  return function(middleware)
    return function(data)
      local cb = vim.api.nvim_get_current_buf()
      local ln = config.to[1] - 1
      local key = tostring(cb) .. "/" .. tostring(ln)

      if data.status then
        return
      end

      if virtualtext.cache[key] == nil then
        virtualtext.cache[key] = {}
      end

      local vt = {}

      if data.ex ~= nil then
        table.insert(vt, {data.ex, "Exception"})
      elseif data.err ~= nil then
        table.insert(vt, {data.err, "Error"})
      elseif data.out ~= nil then
          table.insert(vt, {data.out:gsub("\n", "\\n"), "String"})
      elseif data.value ~= nil and data.value ~= "nil" then
        table.insert(vt, {data.value, "Function"})
      elseif data.value == "nil" then
        table.insert(vt, {"nil", "Delimiter"})
      end

      if #vt > 0 then
        table.insert(vt, 1, {";; => ", "Comment"})
        table.insert(virtualtext.cache[key], vt)

        virtualtext.cache_index[key] = #virtualtext.cache[key]

        -- TODO split_lines
        vim.api.nvim_buf_set_virtual_text(cb, virtualtext.ns, ln, vt, {})

      end
      return middleware(data)
    end
  end
end

virtualtext.clear = function(ln)
  local cb = vim.api.nvim_get_current_buf()
  local to
  local from

  if ln ~= nil then
    local key = tostring(cb) .. "/" .. tostring(ln)
    ln = tonumber(ln) - 1
    virtualtext.cache[key] = {}
    from = ln
    to = ln + 1
  else
    virtualtext.cache = {}
    from = 0
    to = -1
  end

  vim.api.nvim_buf_clear_namespace(cb, virtualtext.ns, from, to)
end

return virtualtext
