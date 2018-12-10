-- luacheck: globals vim
local nvim = vim.api
local utils = require("acid.utils")
local connections = require("acid.connections")

local deps = {
  ['nrepl/nrepl'] = '{:mvn/version "0.5.1"}',
  ["org.clojure/clojurescript"] =  '{:mvn/version "1.10.439"}',
  ['cider/piggieback'] = '{:mvn/version "0.3.8"}',
  ['cider/cider-nrepl'] = '{:mvn/version "0.18.0"}',
  ['refactor-nrepl'] = '{:mvn/version "2.4.0"}',
  ['iced-nrepl'] = '{:mvn/version "0.2.3"}'
}

local middlewares = {
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

local build_cmd = function(selected, portno)
  return {
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
        table.unpack(utils.map(selected, function(dep) return middlewares[dep] end))
      ), " ") ..
      "]"

  }end


local nrepl = {}


nrepl.cache = {}

-- Starts a tools.deps version
nrepl.start = function(obj)
  local selected = obj.middlewares or {'nrepl/nrepl', 'cider/cider-nrepl', 'refactor-nrepl'}

  obj.port = tostring(obj.port or math.random(1024, 65534))

   local ret = nvim.nvim_call_function('jobstart', {
       build_cmd(selected, obj.port), {
         on_stdout = "AcidJobHandler",
         on_stderr = "AcidJobHandler",
         cwd = obj.pwd
     }
     })

   if ret < 0 then
     -- log, inform..
     return
   end

   nrepl.cache[obj.pwd] = ret

  local ix = connections:add{"127.0.0.1", obj.port}

  if obj.pwd then
    connections:select(obj.pwd, ix)
  end

  return obj.id
end

nrepl.stop = function(obj)
  nvim.nvim_call_function("jobstop", {nrepl.cache[obj.id]})

  if obj.pwd then
    connections:unselect(obj.pwd)
  end
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
