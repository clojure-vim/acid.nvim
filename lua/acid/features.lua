-- luacheck: globals vim

--- User-facing features and runnable commands
-- @module acid.features
local commands = require("acid.commands")
local ops = require("acid.ops")
local utils = require("acid.utils")
local forms = require("acid.forms")
local middlewares = require("acid.middlewares")
local acid = require("acid")

-- TODO split features to folder
local features = {}

features.interrupt = function(session)
  acid.run(ops.interrupt{session = session}:with_handler(middlewares.on_status{
        condition = "interrupt",
        action = function(_)
          local log = require("acid.log")
            log.msg("Interrupted!")
        end
    }))
end

--- Evaluate the given code and insert the result at the cursor position
-- @tparam string code Clojure s-expression to be evaluated on the nrepl
-- @tparam[opt] string ns Namespace to be used when evaluating the code.
-- Defaults to current file's ns.
features.eval_cmdline = function(code, ns)
  local curpos = vim.api.nvim_call_function("getcurpos", {})
  local cb = vim.api.nvim_get_current_buf()
  local text = vim.api.nvim_call_function("getline", {"."})
  acid.run(ops.eval{code = code, ns = ns}:with_handler(middlewares
      .insert{
        accessor = function(data)
          if data.ex ~= nil then
            return data.ex
          elseif data.err ~= nil then
            return data.err
          elseif data.out ~= nil then
            return data.out:gsub("\n", "\\n")
          end
          return data.value
        end,
        cb = cb,
        coords = curpos,
        current_line = text
      }
  ))
end

--- Evaluate the given code and print the result.
-- @tparam string code Clojure s-expression to be evaluated on the nrepl
-- @tparam[opt] string ns Namespace to be used when evaluating the code.
-- Defaults to current file's ns.
features.eval_print = function(code, ns)
  acid.run(ops.eval{code = code, ns = ns}:with_handler(middlewares
      .print()
  ))
end

--- Evaluate the current form or the given motion.
-- The result will be shown on a virtualtext next to the current form
-- and also stored on the clipboard.
-- @tparam[opt] string mode motion mode
-- @tparam[opt] boolean replace whether it should replace the form with its result
-- @tparam[opt] string ns Namespace to be used when evaluating the code.
-- Defaults to current file's ns.
features.eval_expr = function(mode, replace, ns)
  local payload = {}
  local midlws
  local coord, form
  if mode == nil then
    form, coord = forms.form_under_cursor()
    payload.code = table.concat(form, "\n")
  elseif mode == "symbol" then
    payload.code, coord = forms.symbol_under_cursor()
  elseif mode == "top" then
    form, coord = forms.form_under_cursor(true)
    payload.code = table.concat(form, "\n")
  else
    lines, coord = forms.form_from_motion(mode)
    payload.code = table.concat(lines, "\n")
  end
  ns = ns or vim.api.nvim_call_function("AcidGetNs", {})
  if ns ~= nil or ns ~= "" then
    payload.ns = ns
  end

  if replace then
    midlws = middlewares
    .refactor(utils.merge(coord, {accessor = function(dt)
      if dt.value ~= nil then
        return dt.value
      else
        return dt.out
      end
    end}))
  else
    midlws = middlewares
      .print{}
      .clipboard{}
      .virtualtext(coord)
    end

  acid.run(ops.eval(payload):with_handler(midlws))
end


--- Sends a `(require '[...])` function to the nrepl.
-- Will send an `AcidRequired` autocommand after complete.
-- @tparam[opt] string ns Namespace to be used when evaluating the code.
-- Defaults to current file's ns.
-- @param[opt] ... extra arguments to the require function
features.do_require = function(ns, ...)
  if ns == nil then
    ns = vim.api.nvim_call_function("AcidGetNs", {})
  end
  acid.run(commands.req{ns = ns, mod = {...}}:with_handler(middlewares
    .doautocmd{autocmd = "AcidRequired"}
  ))
end

--- Sends a `(import '[...])` function to the nrepl.
-- Will send an `AcidImported` autocommand after complete.
-- @tparam string java_ns Namespace of the java symbols that are being imported.
-- @tparam {string,...} symbols List of java symbols to be imported
features.do_import = function(java_ns, symbols)
  acid.run(commands.import{java_ns = java_ns, symbols = symbols}:with_handler(middlewares
    .doautocmd{autocmd = "AcidImported"}
  ))
end

--- Navigates the definition of the given symbol.
-- @tparam[opt] string symbol Symbol to navigate to. Defaults to symbol under
-- cursor.
-- @tparam[opt] string ns Namespace to be used when evaluating the code.
-- Defaults to current file's ns.
features.go_to = function(symbol, ns)
  symbol = symbol or forms.symbol_under_cursor()
  if ns == nil then
    ns = vim.api.nvim_call_function("AcidGetNs", {})
  end

  acid.run(ops.info{symbol = symbol, ns = ns}:with_handler(middlewares.go_to{}))
end


--- Shows the docstring of the given symbol.
-- @tparam[opt] string symbol Symbol which docs will be shown. Defaults to symbol under cursor.
-- @tparam[opt] string ns Namespace to be used when evaluating the code.
-- Defaults to current file's ns.
features.docs = function(symbol, ns)
  local sym, coords = forms.symbol_under_cursor()
  local cb = vim.api.nvim_get_current_buf()

  symbol = symbol or sym

  if ns == nil then
    ns = vim.api.nvim_call_function("AcidGetNs", {})
  end

  acid.run(ops.eldoc{ns = ns, symbol = symbol}:with_handler(middlewares
    .floats{
      cb = cb,
      coords = coords,
      accessor = function(_, data)
        local lines = {}
        if data.name ~= nil then
          table.insert(lines, data.ns .. "/" .. data.name)
        elseif data.member ~= nil then
          table.insert(lines, data.member)
        end
        for _, v in ipairs(data.eldoc) do
          table.insert(lines, "[" .. table.concat(v, " ") .. "]")
        end
        if type(data.docstring) == "string" then
          table.insert(lines, "")
          for _, l in ipairs(utils.split_lines(data.docstring)) do
            table.insert(lines, l)
          end
        elseif #data.docstring > 0 then
          table.insert(lines, "")
          for _, l in ipairs(data.docstring) do
            table.insert(lines, l)
          end
        end

        return lines
      end
    }
  ))
end


--- Inject some clojure files into the nrepl session.
features.preload = function()
  local preload_commands = commands.preload{files = {"clj/acid/inject.clj"}}
  for _, cmd in ipairs(preload_commands) do
    acid.run(cmd:with_handler(middlewares.doautocmd{autocmd = "AcidPreloadedCljFns"}))
  end
end

--- Load all namespaces in the current session.
-- Will fire an `AcidLoadedAllNSs` autocommand after this is completed.
features.load_all_nss = function()
  acid.run(commands.ns_load_all{}:with_handler(middlewares.doautocmd{autocmd = "AcidLoadedAllNSs"}))
end

--- Refactor the current file to include the given argument in the
--`(:requires ...)` section.
-- @tparam string req require vector, such as `[clojure.string :as str]`.
features.add_require = function(req)
  local lines, coords = forms.form_under_cursor()
  local content = table.concat(lines, "")

  local code = "(format-code (upd-ns '" .. content .. " :require (partial add-req '" ..  req .. ")))"

    acid.run(ops.eval{code = code, ns = "acid.inject"}:with_handler(middlewares
      .refactor(coords)
    ))
end

--- Refactor the current file to remove the given argument from the
--`(:requires ...)` section.
-- @tparam string req require namespace, such as `clojure.string`.
features.remove_require = function(req)
  local lines, coords = forms.form_under_cursor()
  local content = table.concat(lines, "")

  local code = "(format-code (upd-ns '" ..  content .. " :require (partial rem-req '" ..  req .. ")))"

    acid.run(ops.eval{code = code, ns = "acid.inject"}:with_handler(middlewares
      .refactor(coords)
    ))
end

--- Refactor the current file so the `(:require ...)` form is sorted.
features.sort_requires = function()
  local lines, coords = forms.form_under_cursor()
  local content = table.concat(lines, "")

  local code = "(format-code (upd-ns '" ..  content .. " :require sort-reqs))"

    acid.run(ops.eval{code = code, ns = "acid.inject"}:with_handler(middlewares
      .refactor(coords)
    ))
end

features.thread_first = function()
  local lines, coords = forms.form_under_cursor()
  local content = table.concat(lines, "\n")
  acid.run(ops['iced-refactor-thread-first']{code = content}:with_handler(
    middlewares.refactor(utils.merge(coords, {accessor = function(dt) return dt.code end}))
  ))
end

features.thread_last = function()
  local lines, coords = forms.form_under_cursor()
  local content = table.concat(lines, "\n")
  acid.run(ops['iced-refactor-thread-last']{code = content}:with_handler(
    middlewares.refactor(utils.merge(coords, {accessor = function(dt) return dt.code end}))
  ))
end

--- Refactor the current file so the `(:require ...)` form is sorted.
features.clean_ns = function()
  local lines, coords = forms.form_under_cursor()
  local fpath = vim.api.nvim_call_function('expand', {'%:p'})

  coords.accessor = function(x)
    return x.ns
  end

    acid.run(ops['clean-ns']{path = fpath}:with_handler(middlewares
      .refactor(coords)
    ))
end

features.get_ns = function(fname)
  local ns = nil
  local lock = true
  local attempts = 8

  acid.run(ops.eval{
      code = '(get-ns "' .. fname .. '")',
      ns = "user"
    }:with_handler(function(data)
    if data.err ~= nil then
      ns = data.value
    end
    lock = false
    end), acid.admin_session())

    while lock or attempts > 0 do
      vim.api.nvim_command("sleep")
      attempts = attempts - 1
    end

    return ns
end

features.retest = function()
end

features.run_test = function(opts)
  local var_query = {}
  local payload = {}

  if opts['get-symbol'] then
    var_query.search = forms.symbol_under_cursor()
  elseif opts.symbol ~= nil then
    var_query.search = opts.symbol
  end

  if opts['get-ns'] then
    var_query['ns-query'] = {exactly = {vim.api.nvim_call_function("AcidGetNs", {})}}
  elseif opts.ns ~= nil then
    var_query['ns-query'] = {exaclty = {opts.ns}}
  elseif opts.nss ~= nil then
    var_query['ns-query'] = {exaclty = opts.nss}
  end

  if next(var_query) ~= nil then
    payload['var-query'] = var_query
  end


  acid.run(ops['test-var-query'](payload):with_handler(middlewares.print{
    accessor = function(data)
      local ret
      if data.summary ~= nil then
        ret = ""
        for k, v in pairs(data.summary) do
          ret = ret .. k .. " → " .. v .. " "
        end
    end
    return ret
  end}.quickfix{}
))
end

return features
