-- luacheck: globals vim
local clipboard = {}

clipboard.name = "clipboard"

clipboard.config = {
  accessor = function(data)
    return data.value
  end,
  register = 'c',
  options = '"'
}

clipboard.set = function(config)
  return function(middleware)
    return function(data)
      vim.api.nvim_call_function("setreg", {config.register, config.accessor(data), config.options})
      return middleware(data)
    end
  end
end

clipboard.middleware = clipboard.set

return clipboard
