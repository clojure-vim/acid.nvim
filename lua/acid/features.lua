-- luacheck: globals vim
local middlewares = require('acid.middlewares')
local commands = require("acid.commands")
local config = require("acid.config")
local acid = require("acid")

local features = {}

features.extract = function(mode)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local b_line, b_col, e_line, e_col, _

  if mode == 'visual' then
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

features.eval_expr = function(mode)
  local stuff = table.concat(features.extract(mode), "\n")
  acid.run(commands.eval(config.features.eval_expr.with{code = stuff}))
end

features.do_require = function(ns, alias)
  if ns == nil then
    ns = vim.api.nvim_call_function("AcidGetNs", {})
  end
  acid.run(commands.req(config.features.do_require.with{ns = ns, alias = alias}))
end

features.go_to = function(symbol, ns)
  acid.run(commands.go_to(config.features.go_to.with{ns = ns, symbol = symbol}))
end

return features
