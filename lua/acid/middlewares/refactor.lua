-- luacheck: globals vim
local refactor = {}


refactor.middleware = function(config)
  return function(middleware)
    return function(data)
      if data.ex ~= nil or data.err ~= nil then
        local msg = data.ex or data.err
        vim.api.nvim_err_writeln("Error while processing: " .. msg)
        return
      elseif data.value ~= nil or data.status ~= nil then
        return
      end

      local lns = {}
      for v in data['out']:gmatch("([^\n]+)") do
        table.insert(lns, v)
      end

      vim.api.nvim_buf_set_lines(config.bufnr, config.from - 1, config.to, false, lns)

      return middleware(data)
    end
  end
end


return refactor
