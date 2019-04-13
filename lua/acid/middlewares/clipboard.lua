-- luacheck: globals vim
local clipboard = {}

clipboard.name = "clipboard"

clipboard.config = {
  accessor = function(data)
    if data.ex ~= nil then
      return data.ex
    elseif data.err ~= nil then
      return data.err
    elseif data.out ~= nil then
      return data.out:gsub("\n", "\\n")
    end
    return data.value
  end,
  register = 'c',
  options = '"'
}

clipboard.set = function(config)
  return function(middleware)
    return function(data, calls)
      vim.api.nvim_call_function("setreg", {config.register, config.accessor(data), config.options})
      return middleware(data, table.insert(calls, clipboard.name))
    end
  end
end

clipboard.middleware = clipboard.set

return clipboard
