-- luacheck: globals vim
local commands = require("acid.commands")
local ops = require("acid.ops")
local forms = require("acid.forms")
local middlewares = require("acid.middlewares")
local acid = require("acid")

-- TODO split features to folder
local features = {}

-- TODO Make available through relevant namespace

features.eval_cmdline = function(code, ns)
  local curpos = vim.api.nvim_call_function("getcurpos", {})
  local cb = vim.api.nvim_get_current_buf()
  local text = vim.api.nvim_call_function("getline", {"."})
  acid.run(ops.eval{code = code, ns = ns}:with_handler(middlewares
      .insert{
        accessor = function(data) return data.value end,
        cb = cb,
        coords = curpos,
        current_line = text
      }
  ))
end

features.eval_expr = function(mode, ns)
  local payload = {}
  if mode == nil then
    payload.code = table.concat(forms.form_under_cursor())
  else
    local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
    payload.code = table.concat(forms.extract(bufnr, mode), "\n")
  end
  ns = ns or vim.api.nvim_call_function("AcidGetNs", {})
  if ns ~= nil or ns ~= "" then
    payload.ns = ns
  end

  acid.run(ops.eval(payload):with_handler(middlewares
      .clipboard{}
      .virtualtext{}
  ))
end

features.do_require = function(ns, alias, ...)
  if ns == nil then
    ns = vim.api.nvim_call_function("AcidGetNs", {})
  end
  acid.run(commands.req{ns = ns, alias = alias, refer = {...}}:with_handler(middlewares
    .doautocmd{autocmd = "AcidRequired"}
  ))
end

features.do_import = function(java_ns, symbols)
  acid.run(commands.req{java_ns = java_ns, symbols = symbols}:with_handler(middlewares
    .doautocmd{autocmd = "AcidImported"}
  ))
end

features.go_to = function(symbol, ns)
  acid.run(commands.go_to{ns = ns, symbol = symbol}:with_handler(middlewares
    .go_to{}
  ))
end

features.preload = function()
  local preload_commands = commands.preload{files = {"clj/acid/inject.clj"}}
  for _, cmd in ipairs(preload_commands) do
    acid.run(cmd:with_handler(middlewares.doautocmd{autocmd = "AcidPreloadedCljFns"}))
  end
end

features.load_all_nss = function()
  acid.run(commands.ns_load_all{}:with_handler(middlewares.doautocmd{autocmd = "AcidLoadedAllNSs"}))
end

features.add_require = function(req)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local lines, coords = forms.extract(bufnr)
  local content = table.concat(lines, "")

  local code = "(format-code (upd-ns '" .. content .. " :require (partial add-req '" ..  req .. ")))"

    acid.run(ops.eval{code = code, ns = "acid.inject"}:with_handler(middlewares
      .refactor{from = coords.from, to = coords.to, bufnr = bufnr}
    ))
end

features.remove_requires = function(req)
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local lines, coords = forms.extract(bufnr)
  local content = table.concat(lines, "")

  local code = "(format-code (upd-ns '" ..  content .. " :require (partial rem-req '" ..  req .. ")))"

    acid.run(ops.eval{code = code, ns = "acid.inject"}:with_handler(middlewares
      .refactor{from = coords.from, to = coords.to, bufnr = bufnr}
    ))
end

features.sort_requires = function()
  local bufnr = vim.api.nvim_call_function("bufnr", {"%"})
  local lines, coords = forms.extract(bufnr)
  local content = table.concat(lines, "")

  local code = "(format-code (upd-ns '" ..  content .. " :require sort-reqs))"

    acid.run(ops.eval{code = code, ns = "acid.inject"}:with_handler(middlewares
      .refactor{from = coords.from, to = coords.to, bufnr = bufnr}
    ))

end

return features
