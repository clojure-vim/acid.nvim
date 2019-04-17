-- luacheck: globals vim
local clipboard = {}

clipboard.name = "clipboard"

clipboard.config = {
  select = function(data)
    return data
  end
}

clipboard.set = function(config)
  return function(middleware)
    return function(data)
      return middleware(config.select(data))
    end
  end
end

clipboard.middleware = clipboard.set

return clipboard
