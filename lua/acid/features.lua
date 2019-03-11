-- luacheck: globals vim
local commands = require("acid.commands")
local config = require("acid.config")
local acid = require("acid")

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
  elseif mode == 'line' then
    b_line, b_col = unpack(vim.api.nvim_buf_get_mark(bufnr, '['))
    e_line, e_col = unpack(vim.api.nvim_buf_get_mark(bufnr, ']'))
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

features.eval_expr = function(mode, ns)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local code = table.concat(extract(bufnr, mode), "\n")
  ns = ns or vim.api.nvim_call_function("AcidGetNs", {})
  acid.run(commands.eval(config.features.eval_expr{code = code, ns = ns}))
end

features.do_require = function(ns, alias, ...)
  if ns == nil then
    ns = vim.api.nvim_call_function("AcidGetNs", {})
  end
  acid.run(commands.req(config.features.do_require{ns = ns, alias = alias, refer = {...}}))
end

features.do_import = function(java_ns, symbols)
  acid.run(commands.import(config.features.do_import{java_ns = java_ns, symbols = symbols}))
end

features.go_to = function(symbol, ns)
  acid.run(commands.go_to(config.features.go_to{ns = ns, symbol = symbol}))
end

features.preload = function()
  for _, cmd in ipairs(commands.preload(config.features.preload())) do
    acid.run(cmd)
  end
end

features.load_all_nss = function()
  acid.run(commands.ns_load_all(config.features.ns_load_all()))
end

features.add_require = function(req)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local lines, b, e = extract(bufnr)
  local content = table.concat(lines, "")

  local code = "(acid.inject/format-code (acid.inject/upd-ns '" ..
    content ..  " :require (partial acid.inject/add-req '" ..  req .. ")))"

    acid.run(commands.eval(config
        .features
        .add_require{from = b, to = e, bufnr = bufnr, code = code}))
end

features.remove_requires = function(req)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local lines, b, e = extract(bufnr)
  local content = table.concat(lines, "")

  local code = "(acid.inject/format-code (acid.inject/upd-ns '" ..
    content ..  " :require (partial acid.inject/rem-req '" ..  req .. ")))"

    acid.run(commands.eval(config
        .features
        .remove_require{from = b, to = e, bufnr = bufnr, code = code}))
end

features.sort_requires = function()
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local lines, b, e = extract(bufnr)
  local content = table.concat(lines, "")

  local code = "(acid.inject/format-code (acid.inject/upd-ns '" ..
    content .. " :require acid.inject/sort-reqs))"

    acid.run(commands.eval(config
        .features
        .sort_requires{from = b, to = e, bufnr = bufnr, code = code}))

end

features.do_hl = function(ns)
  ns = ns or vim.api.nvim_call_function("AcidGetNs", {})
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local code = "(when (find-ns 'acid.highlight) (acid.hightlight/ns-syntax-command '" ..  ns .. "))"

    acid.run(commands.eval(config.features.do_hl{code = code, fn = function(dt)
      vim.api.nvim_buf_set_var(bufnr, "clojure_syntax_without_core_keywords", true)
      vim.api.nvim_buf_set_var(bufnr, "clojure_syntax_keywords", dt)
    end}))
end

return features
