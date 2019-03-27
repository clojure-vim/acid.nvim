-- luacheck: globals vim
local log = {}

log.msg = function(msg)
  vim.api.nvim_out_write("[Acid] " .. msg .. "\n")
end

return log
