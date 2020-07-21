-- luacheck: globals vim

local connections = require("acid.connections")
local output = {}

local location = function(opts)
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")
  return {
    relative = "editor",
    width = opts.width or 60,
    height = height,
    row = 0,
    col = width - (opts.width or 60)
  }
end

output.conn_to_buf = {}

output.buffer = function(conn)
  local buf = output.conn_to_buf[conn]
  if buf == nil then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    output.conn_to_buf[conn] = buf
  end

  return buf
end

output.window = function(conn, opts)
  local buf = output.buffer(conn)
  local winnr = vim.fn.bufwinnr(buf)
  local winid

  if winnr == -1 then
    winid = vim.api.nvim_open_win(buf, true, location(opts or {}))
    vim.api.nvim_win_set_option(winid, "breakindent", true)
    vim.api.nvim_win_set_option(winid, "number", false)
    vim.api.nvim_win_set_option(winid, "relativenumber", false)
    vim.api.nvim_win_set_option(winid, "fillchars", "eob: ")
  else
    winid = vim.fn.win_getid()
  end
  vim.api.nvim_set_current_win(winid)
end

output.close_window = function(conn)
  local buf = output.buffer(conn)
  local winnr = vim.fn.bufwinnr(buf)

  if winnr ~= -1 then
    local winid = vim.fn.win_getid()
    vim.api.nvim_win_close(winid, true)
  end
end

output.draw = function(conn, lines)
  local buf = output.conn_to_buf[conn]

  if type(lines) == "string" then
    old = lines
    lines = {}
    old:gsub("[^\n]+", function(dt) table.insert(lines, dt) end)
  end
  if buf == nil then
    return
  end

  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end


output.open = function()
  local conn = connections.peek()

  output.window(conn)
end

output.close = function()
  local conn = connections.peek()
  output.close_window(conn)
end

output.clear = function(conn)
  conn = conn or connections.peek()

  local buf = output.conn_to_buf[conn]
  if buf == nil then
    return
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

return output
