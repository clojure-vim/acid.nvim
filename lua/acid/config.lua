local utils = require("acid.utils")
local config = {}

local with_handler = function(handler)
  return function(map)
    map.handler = handler
    return map
  end
end

config.values = {}

config.values.features = setmetatable({
  eval_expr = with_handler(function(data)
      local middlewares = require("acid.middlewares")
      return middlewares.virtualtext(middlewares.ex.clipboard)(data)
    end),

   do_require = with_handler(function(data)
      return require("acid.middlewares").ex.noconfig.doautocmd{autocmd = "AcidRequired"}(data)
    end),

   ns_load_all = function()
     return with_handler(function(data)
        return require("acid.middlewares").ex.noconfig.doautocmd{autocmd = "AcidLoadedAllNSs"}(data)
      end){}
    end,

   preload = function()
     return with_handler(function(data)
        return require("acid.middlewares").ex.noconfig.doautocmd{autocmd = "AcidPreloadedCljFns"}(data)
      end){ files = {"clj/acid/inject.clj"} }
    end,

   add_require = function(cfg)
     return {
        code = cfg.code,
        handler = function(data)
          return require("acid.middlewares").ex.noconfig.refactor(cfg)(data)
        end
      }
    end,

   do_hl = function(cfg)
     return {
        code = cfg.code,
        handler = function(data)
          return require("acid.middlewares").ex.noconfig.exec(cfg)(data)
        end
      }
    end,

   remove_require = function(cfg)
     return {
        code = cfg.code,
        handler = function(data)
          return require("acid.middlewares").ex.noconfig.refactor(cfg)(data)
        end
      }
    end,

   sort_requires = function(cfg)
     return {
        code = cfg.code,
        handler = function(data)
          return require("acid.middlewares").ex.noconfig.refactor(cfg)(data)
        end
      }
    end,

   do_import = with_handler(function(data)
      return require("acid.middlewares").ex.noconfig.doautocmd{autocmd = "AcidImported"}(data)
    end),

   go_to = with_handler(function(data)
      return require("acid.middlewares").ex.go_to(data)
    end)
}, {__index = function(tbl, k)
  return rawget(tbl, k) or {}
end}
)

config.values.middlewares = setmetatable({
  clipboard = {
    accessor = function(data) return data.value end,
    register = "c",
    options = '"'
  }
}, {__index = function(tbl, k)
  return rawget(tbl, k) or {}
end
})

config.forname = function(branch)
  return setmetatable({}, {__index = function(_, key)
    return utils.clone(config.values[branch][key])
    end})
end

config.middlewares = config.forname("middlewares")
config.features = config.forname("features")

return config
