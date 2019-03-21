-- luacheck: globals vim
local exec = {}


exec.middleware = function(config)
  return function(middleware)
    return function(data)

      if data.value == nil then
        return
      end
      local content = loadstring(data.value)

      config.fn(content())

      return middleware(data)
    end
  end
end


return exec
