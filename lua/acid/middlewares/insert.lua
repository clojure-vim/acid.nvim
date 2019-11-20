-- luacheck: globals vim
local insert = {}


insert.middleware = function(config)
  return function(middleware)
    return function(data)
      if data.status ~= nil then
        return
      end

      local text = vim.split(config.current_line:sub(1, config.coords[3] - 1) .. config.accessor(data) .. config.current_line:sub(config.coords[3]), "\n", false)

      vim.api.nvim_buf_set_lines(config.cb, config.coords[2] - 1, config.coords[2] + #text -1, true, text)

      return middleware(data)
    end
  end
end


return insert
