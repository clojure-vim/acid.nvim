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

local cache = setmetatable({}, {
    __index = function(_, k)
      return nrepl.cache[k]
    end,
  __newindex = function(_, k, v)
    if nrepl.cache[k] ~= nil then
      nrepl.stop{pwd = k}
    end
    nrepl.cache[k] = v
  end
})

nrepl.default_middlewares = {'nrepl/nrepl', 'cider/cider-nrepl', 'refactor-nrepl'}

-- Starts a tools.deps version
nrepl.start = function(obj)
  local selected = obj.middlewares or nrepl.default_middlewares

  obj.port = tostring(obj.port or math.random(1024, 65534))

   local ret = nvim.nvim_call_function('jobstart', {
       build_cmd(selected, obj.port), {
         on_stdout = "AcidJobHandler",
         on_stderr = "AcidJobHandler",
         cwd = obj.pwd
     }
     })

   if ret < 0 then
     -- TODO log, inform..
     return
   end

   cache[obj.pwd] = math.floor(ret)

  local ix = connections:add{"127.0.0.1", obj.port}
  connections:select(obj.pwd, ix)

  return true
end

nrepl.stop = function(obj)
  nvim.nvim_call_function("jobstop", {cache[obj.pwd]})
  connections:remove(cache[obj.pwd])
  connections:unselect(obj.pwd)
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
