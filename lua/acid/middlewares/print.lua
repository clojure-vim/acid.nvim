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
      if data.ex ~= nil then
        vim.api.nvim_out_write(data.ex .. "\n")
      end
      if data.err ~= nil then
        vim.api.nvim_out_write(data.err .. "\n")
      end

      return middleware(data)
    end
  end
end

return do_print
