-- luacheck: globals vim

local virtualtext = {}

virtualtext.ns = vim.api.nvim_create_namespace("acid")

virtualtext.set = function(opts)
  return function(data)
    if data.status then
      return
    end

    local cb = vim.api.nvim_get_current_buf()
    local ln = vim.api.nvim_call_function("line", {"."}) - 1
    local hl
    local dt = ";; => "


    if data.ex ~= nil then
      dt = dt .. data.ex
      hl = "Exception"
    elseif data.err ~= nil then
      dt = dt .. data.err
      hl = "Error"
    elseif data.out ~= nil then
      dt = dt .. data.out
      hl = "String"
    elseif data.value ~= nil then
      dt = dt .. data.value
      hl = "Function"
    end

    vim.api.nvim_buf_set_virtual_text(cb, virtualtext.ns, ln, {{dt, hl}}, {})
    return opts.handler(data)
  end
end

virtualtext.clear = function(ln)
  local cb = vim.api.nvim_get_current_buf()

  ln = tonumber(ln) - 1

  local from = ln or 0
  local to = 1 + (ln or -2)

  vim.api.nvim_buf_clear_namespace(cb, virtualtext.ns, from, to)
end

return virtualtext
