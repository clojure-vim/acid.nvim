-- luacheck: globals vim
local nvim = vim.api
local utils = require("acid.utils")
local connections = require("acid.connections")

local nrepl = {}

local deps = {
  ['nrepl/nrepl'] = '{:mvn/version "0.6.0"}',
  ['org.clojure/clojurescript'] =  '{:mvn/version "1.10.439"}',
  ['cider/piggieback'] = '{:mvn/version "0.4.0"}',
  ['cider/cider-nrepl'] = '{:mvn/version "0.21.1"}',
  ['refactor-nrepl'] = '{:mvn/version "2.4.0"}',
  ['iced-nrepl'] = '{:mvn/version "0.4.1"}'
}

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

local build_cmd = function(selected, portno, bind, host, connect)
  local opts = {
    "clojure",
    "-Sdeps",
    get_deps(selected),
    "-m",
    "nrepl.cmdline",
    "-p",
    portno,
    "--middleware",
    "[" ..
      table.concat(utils.join(
        unpack(utils.map(selected, function(dep) return nrepl.middlewares[dep] end))
      ), " ") ..
      "]"
  }

  if bind ~= nil then
    table.insert(opts,"-b")
    table.insert(opts, bind)
  end

  if host ~= nil or connect ~= nil then
    table.insert(opts,"-c")
  end

  if host ~= nil then
    table.insert(opts,"-h")
    table.insert(opts, host)
  end

  return opts
end


nrepl.cache = {}

nrepl.default_middlewares = {'nrepl/nrepl', 'cider/cider-nrepl', 'refactor-nrepl'}

-- Starts a tools.deps version
nrepl.start = function(obj)
  local pwd = obj.pwd

  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  local selected = obj.middlewares or nrepl.default_middlewares
  local port = tostring(obj.port or math.random(1024, 65534))
  local bind = obj.bind
  local cmd = obj.cmd or build_cmd(selected, port, obj.bind, obj.host, obj.connect)

  bind = bind or "127.0.0.1"

   local ret = nvim.nvim_call_function('jobstart', {
       cmd , {
         on_stdout = "AcidJobHandler",
         on_stderr = "AcidJobHandler",
         cwd = pwd
       }
     })

   if ret <= 0 then
     -- TODO log, inform..
     return
   end

   nrepl.cache[pwd] = {
     job = ret,
     addr = {bind, port}
   }

  local ix = connections:add{"127.0.0.1", port}
  connections:select(pwd, ix)

  return true
end

nrepl.stop = function(obj)
  local pwd = obj.pwd

  if not utils.ends_with(pwd, "/") then
    pwd = pwd .. "/"
  end

  nvim.nvim_call_function("jobstop", {nrepl.cache[pwd].job})
  connections:unselect(pwd)
  connections:remove(nrepl.cache[pwd].addr)
  nrepl.cache[obj.pwd] = nil
end

nrepl.handle = {
  _store = {},
  stdout = function(dt, ch)
    nrepl.handle._store[ch] = nrepl.handle._store[ch] or {}
    table.insert(nrepl.handle._store[ch], dt)
  end,
  stderr = function(dt, ch)
    nrepl.handle._store[ch] = nrepl.handle._store[ch] or {}
    table.insert(nrepl.handle._store[ch], dt)
  end,
  show = function(ch)
    if ch ~= nil then
      return nrepl.handle._store[ch]
    else
      return nrepl.handle._store
    end
  end
}

return nrepl
