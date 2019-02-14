local utils = require("acid.utils")
local config = {}

config.values = {}

config.values.features = setmetatable({
  eval_expr = {
    handler = function(data)
      local middlewares = require("acid.middlewares")
      return middlewares.virtualtext(middlewares.ex.clipboard)(data)
    end
  },

   do_require = {
    handler = function(data)
      local middlewares = require("acid.middlewares")
      return middlewares.ex.noconfig.doautocmd{autocmd = "AcidRequired"}(data)
    end
  },

   do_import = {
    handler = function(data)
      local middlewares = require("acid.middlewares")
      return middlewares.ex.noconfig.doautocmd{autocmd = "AcidImported"}(data)
    end
  },

   go_to = {
    handler = function(data)
      local middlewares = require("acid.middlewares")
      return middlewares.ex.go_to(data)
    end
  },
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
    return setmetatable(utils.clone(config.values[branch][key]), {
        __index = function(tbl, k)
          if k == "with" then
            return function(val)
              return utils.merge(tbl, val)
            end
          else
            return rawget(tbl, k)
          end
        end
      })
    end})
end

config.middlewares = config.forname("middlewares")
config.features = config.forname("features")

return config
