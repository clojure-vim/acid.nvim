-- luacheck: globals vim
local insert = {}

insert.name = "insert"

insert.middleware = function(config)
  return function(middleware)
    return function(data, calls)
      if data.status ~= nil then
        return
      end

      local text = config.current_line .. config.accessor(data)

      vim.api.nvim_buf_set_lines(config.cb, config.coords[2] - 1, config.coords[2], true, {text})

      return middleware(data, table.insert(calls, insert.name))
    end
  end
end


return insert
