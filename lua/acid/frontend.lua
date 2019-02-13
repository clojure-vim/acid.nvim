-- luacheck: globals vim
local middlewares = require('acid.middlewares')
local features = require("acid.features")
local acid = require("acid")

local frontend = {}

frontend.extract = function(tp)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local b_line, b_col, e_line, e_col, _

  if tp == 'visual' then
    _, b_line, b_col = unpack(vim.api.nvim_call_function("getpos", {"v"}))
    _, e_line, e_col = unpack(vim.api.nvim_call_function("getpos", {"."}))

    b_col = b_col - 1
    e_col = e_col - 1
  else
    b_line, b_col = unpack(vim.api.nvim_buf_get_mark(bufnr, '['))
    e_line, e_col = unpack(vim.api.nvim_buf_get_mark(bufnr, ']'))
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, b_line - 1, e_line, 0)

  if b_col ~= 0 then
    lines[1] = string.sub(lines[1], b_col + 1)
  end

  if e_col ~= 0 then
    if b_line ~= e_line then
      lines[#lines] = string.sub(lines[#lines], 1, e_col + 1)
    else
      lines[#lines] = string.sub(lines[#lines], 1, e_col - b_col + 1)
    end
  end

  return lines
end

frontend.eval_expr = function()
  local stuff = table.concat(frontend.extract(), "\n")

  acid.run(features.eval{
    code = stuff,
    handler = middlewares.virtualtext.set(middlewares.nop)
  })
end

return frontend
