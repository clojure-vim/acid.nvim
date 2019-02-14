-- luacheck: globals vim
local commands = require("acid.commands")
local config = require("acid.config")
local acid = require("acid")
local ops = require("acid.ops")

-- TODO split features to folder
local features = {}

-- TODO Make available through relevant namespace
local extract = function(bufnr, mode)
  local b_line, b_col, e_line, e_col, _

  if mode == 'visual' then
    _, b_line, b_col = unpack(vim.api.nvim_call_function("getpos", {"v"}))
    _, e_line, e_col = unpack(vim.api.nvim_call_function("getpos", {"."}))

    b_col = b_col - 1
    e_col = e_col - 1
  else
    b_line, b_col = unpack(vim.api.nvim_buf_get_mark(bufnr, '<'))
    e_line, e_col = unpack(vim.api.nvim_buf_get_mark(bufnr, '>'))
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

  return lines, b_line, e_line
end

features.eval_expr = function(mode)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local code = table.concat(extract(bufnr, mode), "\n")
  acid.run(commands.eval(config.features.eval_expr.with{code = code}))
end

features.do_require = function(ns, alias)
  if ns == nil then
    ns = vim.api.nvim_call_function("AcidGetNs", {})
  end
  acid.run(commands.req(config.features.do_require.with{ns = ns, alias = alias}))
end

features.do_import = function(java_ns, symbols)
  acid.run(commands.import(config.features.do_import.with{java_ns = java_ns, symbols = symbols}))
end

features.go_to = function(symbol, ns)
  acid.run(commands.go_to(config.features.go_to.with{ns = ns, symbol = symbol}))
end

-- TODO move relevant parts to command
features.preload = function()
  local contents = vim.api.nvim_call_function("readfile", {"/opt/code/clojure-vim/acid.nvim/clj/acid/inject.clj"})
  local lf = ops['load-file']{
    file = table.concat(contents, "\n")
  }
  acid.run(lf)
end

-- TODO Move relevant parts to command
features.add_require = function(req)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local lines, b, e = extract(bufnr)
  local content = table.concat(lines, "")

  acid.run(ops.eval{
    code = "(acid.inject/format-code (acid.inject/upd-ns '" ..
    content ..
    " :require (partial acid.inject/add-req '" ..
    req ..
    ")))"
  }:with_handler(function(data)
    if data.ex ~= nil or data.err ~= nil then
      local msg = data.ex or data.err
      vim.api.nvim_err_writeln("Error while processing: " .. msg)
      return
    end

    if data.value ~= nil or data.status ~= nil then
      return
    end

    local lns = {}
    for v in data['out']:gmatch("([^\n]+)") do
      table.insert(lns, v)
    end

    vim.api.nvim_buf_set_lines(bufnr, b - 1, e, false, lns)
  end))

end

-- TODO remove duplications
features.sort_requires = function()
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local lines, b, e = extract(bufnr)
  local content = table.concat(lines, "")

  acid.run(ops.eval{
    code = "(acid.inject/format-code (acid.inject/upd-ns '" ..
    content ..
    " :require acid.inject/sort-reqs))"
  }:with_handler(function(data)
    if data.ex ~= nil or data.err ~= nil then
      local msg = data.ex or data.err
      vim.api.nvim_err_writeln("Error while processing: " .. msg)
      return
    end

    if data.value ~= nil or data.status ~= nil then
      return
    end

    local lns = {}
    for v in data['out']:gmatch("([^\n]+)") do
      table.insert(lns, v)
    end

    vim.api.nvim_buf_set_lines(bufnr, b - 1, e, false, lns)
  end))

end

return features
