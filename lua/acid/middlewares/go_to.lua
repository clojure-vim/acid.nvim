-- luacheck: globals vim
local nvim = vim.api
local utils = require("acid.utils")
local go_to = {}

go_to.middleware = function(config)
  return function(middleware)
    return function(data)
      if data['no-info'] ~= nil then
        nvim.nvim_err_writeln("No information found for symbol.")
        return
      end

      local fpath = nvim.nvim_call_function("Acid_FindFileInPath", {data})

      if fpath == nil then
        nvim.nvim_err_writeln("File not found")
        return
      end

      local col = math.floor(data.column or 1)
      local ln = math.floor(data.line or 1)

      local cur_scroll = nvim.nvim_get_option("scrolloff")
      nvim.nvim_set_option("scrolloff", 999)

      if utils.ends_with(nvim.nvim_call_function("expand", {"%"}), fpath) then
        nvim.nvim_call_function("cursor", {ln, col})
      else
        nvim.nvim_command("edit +" .. ln .. " " .. fpath)
      end

      nvim.nvim_set_option("scrolloff", cur_scroll)

      return middleware(data)
    end
  end
end

return go_to
