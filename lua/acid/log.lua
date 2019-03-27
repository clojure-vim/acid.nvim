-- luacheck: globals vim
local log = {}

log.msg = function(...)
  vim.api.nvim_out_write("[Acid] " .. table.concat({...}, " ") .. "\n")
end

return log
