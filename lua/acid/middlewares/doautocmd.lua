-- luacheck: globals vim
local doautocmd = {}

doautocmd.middleware = function(config)
  return function(middleware)
    return function(data)
      vim.api.nvim_command("doautocmd User " .. config.autocmd)
      return middleware(data)
    end
  end
end

return doautocmd
