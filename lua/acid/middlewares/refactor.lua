-- luacheck: globals vim
local refactor = {}

refactor.name = "refactor"

refactor.config = {
  accessor = function(dt)
    return dt.out
  end
}


refactor.middleware = function(config)
  return function(middleware)
    return function(data, calls)
      if data.ex ~= nil or data.err ~= nil then
        local msg = data.ex or data.err
        vim.api.nvim_err_writeln("Error while processing: " .. msg)
        return
      elseif data.value ~= nil or data.status ~= nil then
        -- TODO log
        return
      end

      local lns = {}
      local dt = config.accessor(data)
      if dt == nil then
        -- TODO log
        return
      end
      for v in dt:gmatch("([^\n]+)") do
        table.insert(lns, v)
      end

      vim.api.nvim_buf_set_lines(config.bufnr, config.from[1] - 1, config.to[1], false, lns)

      return middleware(data, table.insert(calls, refactor.name))
    end
  end
end


return refactor
