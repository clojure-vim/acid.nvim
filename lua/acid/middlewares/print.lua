-- luacheck: globals vim
return function(opts)
  return function(data)
    if data.ex ~= nil then
      vim.api.nvim_err_writeln(data.ex)
    end
    if data.err ~= nil then
      vim.api.nvim_err_writeln(data.err)
    end
    if data.out ~= nil then
      vim.api.nvim_out_write(data.out .. "\n")
    end
    if data.value ~= nil then
      vim.api.nvim_out_write(data.value .. "\n")
    end

    return opts.handler(data)
  end
end
