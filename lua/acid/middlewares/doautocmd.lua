-- luacheck: globals vim
local doautocmd = {}

doautocmd.name = "doautocmd"

doautocmd.middleware = function(config)
  return function(middleware)
    return function(data, calls)
      if data.status ~= nil then
        return
      end

      vim.api.nvim_call_function("AcidLog", {"acid.middlewares.doautocmd", "Firing autocmd " .. config.autocmd})
      vim.api.nvim_command("doautocmd User " .. config.autocmd)
      return middleware(data, table.insert(calls, doautocmd.name))
    end
  end
end

return doautocmd
