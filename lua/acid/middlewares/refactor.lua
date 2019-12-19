-- luacheck: globals vim
local refactor = {}

refactor.config = {
  accessor = function(dt)
    return dt.out
  end
}


refactor.middleware = function(config)
  return function(middleware)
    return function(data)
      if data.ex ~= nil or data.err ~= nil then
        local msg = data.ex or data.err
        vim.api.nvim_err_writeln("Error while processing: " .. msg)
        return
      elseif config.accessor(data) ~= nil then
        local lns = {}
        local dt = config.accessor(data)
        local old = vim.api.nvim_buf_get_lines(config.bufnr, config.from[1] - 1, config.to[1], false)

        local before = old[1]:sub(1, config.from[2] - 1)
        local after = old[#old]:sub(config.to[2])

        for v in dt:gmatch("([^\n]+)") do
          table.insert(lns, v)
        end

        lns[1] = before .. lns[1]
        lns[#lns] = lns[#lns] .. after

        vim.api.nvim_buf_set_lines(config.bufnr, config.from[1] - 1, config.to[1], false, lns)

        return middleware(data)
      elseif data.value ~= nil or data.status ~= nil then
        -- TODO log
        return
      end
    end
  end
end


return refactor
