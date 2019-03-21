-- luacheck: globals vim
local insert = {}


insert.middleware = function(config)
  return function(middleware)
    return function(data)
      if data.status ~= nil then
        return
      end

      local text = config.current_line .. config.accessor(data)

      vim.api.nvim_buf_set_lines(config.cb, config.coords[2] - 1, config.coords[2], true, {text})

      return middleware(data)
    end
  end
end


return insert
