-- luacheck: globals vim

--- nRepl connectivity
-- @module acid.nrepl
local nvim = vim.api
local log = require("acid.log")
local utils = require("acid.utils")
local connections = require("acid.connections")

local pending = {}
local nrepl = {}

local deps = {
  ['nrepl/nrepl'] = '{:mvn/version "0.6.0"}',
  ['org.clojure/clojurescript'] =  '{:mvn/version "1.10.439"}',
  ['cider/piggieback'] = '{:mvn/version "0.4.0"}',
  ['cider/cider-nrepl'] = '{:mvn/version "0.24.0"}',
  ['refactor-nrepl'] = '{:mvn/version "2.5.0"}',
  ['iced-nrepl'] = '{:mvn/version "1.0.0"}'
}

--- List of supported middlewares and the wrappers to invoke when spawning a nrepl process.
-- @table middlewares
nrepl.middlewares = {
  ['nrepl/nrepl'] = {},
  ['cider/cider-nrepl'] = {'cider.nrepl/cider-middleware'},
  ['cider/piggieback'] = {'cider.piggieback/wrap-cljs-repl'},
  ['refactor-nrepl'] = {'refactor-nrepl.middleware/wrap-refactor'},
  ['iced-nrepl'] = {'iced.nrepl/wrap-iced'}
}

local get_deps = function(selected)
  return "{:deps {" ..
  table.concat(
    utils.map(selected, function(k)
      return k .. " " .. deps[k]
      end)
    , ", "
    )
  .. "}}"
end

local supplied = function(fname)
  return table.concat(vim.api.nvim_call_function("readfile", {fname}), "\n")
end

local build_cmd = function(obj)
  local opts = {
    "clojure",
    "-Sdeps",
    get_deps(obj.selected),
    "-m",
    "nrepl.cmdline",
    "--middleware",
    "[" ..
      table.concat(utils.join(
        unpack(utils.map(obj.selected, function(dep) return nrepl.middlewares[dep] end))
      ), " ") ..
      "]"
  }

  if obj.deps_file ~= nil then
    opts[3] = supplied(obj.deps_file)
  end

  if obj.alias ~= nil then
    table.insert(opts, 4, "-C" .. table.concat(obj.alias, ""))
    table.insert(opts, 4, "-R" .. table.concat(obj.alias, ""))
  end

  if obj.port ~= nil then
    table.insert(opts, "-p")
    table.insert(opts, tostring(obj.port))
  end

  if obj.bind ~= nil then
    table.insert(opts,"-b")
    table.insert(opts, obj.bind)
  end

  if obj.host ~= nil or obj.connect ~= nil then
    table.insert(opts,"-c")
  end

  if obj.host ~= nil then
    table.insert(opts,"-h")
    table.insert(opts, obj.host)
  end

  return opts
end

nrepl.cache = {}

--- Default middlewares that will be used by the nrepl server
-- @table default_middlewares
nrepl.default_middlewares = {'nrepl/nrepl', 'cider/cider-nrepl', 'refactor-nrepl'}

--- Starts a tools.deps nrepl server
-- @tparam table obj Configuration for the nrepl process to be spawn
-- @tparam[opt] string obj.pwd Path where the nrepl process will be started
-- @tparam[opt] table obj.middlewares List of middlewares.
-- @tparam[opt] string obj.alias aliases on the local deps.edn
-- @tparam[opt] string obj.connect -c parameter for the nrepl process
-- @tparam[opt] string obj.bind -b parameter for the nrepl process
-- @tparam[opt] boolean obj.skip_autocmd don't fire an autocmd after starting this repl
-- @treturn boolean Whether it was possible to spawn a nrepl process
nrepl.start = function(obj)
  local pwd = obj.pwd or vim.api.nvim_call_function("getcwd", {})

  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  local selected = obj.middlewares or nrepl.default_middlewares
  local bind = obj.bind
  local cmd = obj.cmd or build_cmd{
    selected = selected,
    port = obj.port,
    alias = obj.alias,
    bind = obj.bind,
    host = obj.host,
    connect = obj.connect,
    deps_file = obj.deps_file
  }

  bind = bind or "127.0.0.1"

  local ret = nvim.nvim_call_function('jobstart', {
      cmd , {
        on_stdout = "AcidJobHandler",
        on_stderr = "AcidJobHandler",
        on_exit = "AcidJobCleanup",
        cwd = pwd
      }
    })

   if ret <= 0 then
     -- TODO log, inform..
     return
   end

   local conn = {bind, obj.port}

   nrepl.cache[pwd] = {
     skip_autocmd = obj.skip_autocmd,
     job = ret,
     addr = conn
   }

  local ix = connections.add(conn)

  pending[ret] = {pwd = pwd, ix = ix}
  return true
end

--- Stops a nrepl process managed by acid
-- @tparam table obj Configuration for the nrepl process to be stopped
-- @tparam string obj.pwd Path where the nrepl process was started
nrepl.stop = function(obj)
  local pwd = obj.pwd

  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  nvim.nvim_call_function("jobstop", {nrepl.cache[pwd].job})
  connections.unselect(pwd)
  connections.remove(pwd, nrepl.cache[pwd].addr)
  nrepl.cache[obj.pwd] = nil
end

nrepl.cleanup = function(job_id)
  nrepl.handle._store[job_id] = nil
  local pwd = utils.search(nrepl.cache, function(obj)
    return obj.job == job_id
  end)

  if pwd ~= nil then
    nrepl.stop{pwd = pwd}
  end
end

nrepl.handle = {
  _store = {},
  stdout = function(dt, ch)
    nrepl.handle._store[ch] = nrepl.handle._store[ch] or {}
    if pending[ch] ~= nil then
      for _, ln in ipairs(dt) do
        if string.sub(ln, 1, 20) == "nREPL server started" then
          local opts = pending[ch]
          local port = ln:match("%d+")
          connections.store[opts.ix][2] = port
          connections.select(opts.pwd, opts.ix)
          pending[ch] = nil
          if not nrepl.cache[opts.pwd].skip_autocmd then
            log.msg("Connected on port", tostring(port))
            vim.api.nvim_command("doautocmd User AcidConnected")
          end
        end
      end
    end
    table.insert(nrepl.handle._store[ch], dt)
  end,
  stderr = function(dt, ch)
    nrepl.handle._store[ch] = nrepl.handle._store[ch] or {}
    table.insert(nrepl.handle._store[ch], dt)
  end,

--- Debugs nrepl connection by returning the captured output
-- @tparam[opt] int ch Neovim's job id of given nrepl process. When not supplied return all.
-- @treturn table table with the captured outputs for given (or all) nrepl process(es).
  show = function(ch)
    if ch ~= nil then
      return {[ch] = nrepl.handle._store[ch]}
    else
      return nrepl.handle._store
    end
  end
}

return nrepl
