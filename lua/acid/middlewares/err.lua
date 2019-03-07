-- luacheck: globals vim
local err = {}

err.middleware = function(config)
  return function(middleware)
    return function(data)
      local has_err = false
      if data.ex ~= nil then
        has_err = true
        vim.api.nvim_err_writeln(data.ex)
      end
      if data.err ~= nil then
        has_err = true
        vim.api.nvim_err_writeln(data.err)
      end

      if not has_err or not config.bail_out then
        return middleware(data)
      end
    end
  end
end

return err
