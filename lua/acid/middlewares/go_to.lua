-- luacheck: globals vim
local nvim = vim.api
local log = require("acid.log")
local utils = require("acid.utils")
local go_to = {}

go_to.config = {
  open = "edit"
}

go_to.middleware = function(config)
  return function(middleware)
    return function(data)

      if utils.find(data.status, "no-info") then
        log.msg("No information found")
        return
      end

      local args = {data.file}
      if data.resource ~= nil then
        table.insert(args, data.resource)
      end

      local fpath = nvim.nvim_call_function("AcidFindFileInPath", args)

      if fpath == nil then
        log.msg("File not found (" .. data.file .. ").")
        return
      end

      local col = math.floor(data.column or 1)
      local ln = math.floor(data.line or 1)

      local cur_scroll = nvim.nvim_get_option("scrolloff")
      nvim.nvim_set_option("scrolloff", 999)

      if utils.ends_with(nvim.nvim_call_function("expand", {"%"}), fpath) then
        nvim.nvim_call_function("cursor", {ln, col})
      else
        nvim.nvim_command(config.open .. " +" .. ln .. " " .. fpath)
      end

      nvim.nvim_set_option("scrolloff", cur_scroll)

      return middleware(data)
    end
  end
end

return go_to
