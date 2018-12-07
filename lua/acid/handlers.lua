-- luacheck: globals vim
local nvim = vim.api
local handlers = {}

local ends_with = function(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

local impl = function(impl)
    return function(data)
      impl(data)
      return data
    end
end

handlers.go_to = impl(function(data)
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

  if ends_with(nvim.nvim_call_function("expand", {"%"}), fpath) then
    nvim.nvim_call_function("cursor", {ln, col})
  else
    nvim.nvim_command("edit +" .. ln .. " " .. fpath)
  end

  nvim.nvim_set_option("scrolloff", cur_scroll)
end)

return handlers
