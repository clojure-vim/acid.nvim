-- luacheck: globals vim
return function(opts)
  return function(data)
    vim.api.nvim_command("doautocmd User " .. opts.autocmd)
    return opts.handler(data)
  end
end
