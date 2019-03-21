-- luacheck: globals vim
local do_print = {}

do_print.middleware = function(config)
  return function(middleware)
    return function(data)
      if data.out ~= nil then
        vim.api.nvim_out_write(data.out .. "\n")
      end
      if data.value ~= nil then
        vim.api.nvim_out_write(data.value .. "\n")
      end

      return middleware(data)
    end
  end
end

return do_print
