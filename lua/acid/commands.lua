local utils = require("acid.utils")
local composable = function(map)

  map.update_payload = function(this, fn)
    local old_payload_fn = this.payload

    this.payload = function()
      return fn(old_payload_fn())
    end
    return this
  end

  map.with_handler = function(this, fn)
    this.handler = fn
    return this
  end

  map.with_payload = function(this, value)
    this.payload = function() return value end
    return this
  end

  map.build = function(this)
    return this.payload(), this.handler
  end

  return setmetatable(map, {
      __call = function(this)
        return this:build()
      end
    })
end

local new = function(op)
  return composable{}:with_payload{op = op}
end

local for_op = function(op)
  return function(map)
    return new(op):update_payload(function(orig) return utils.merge(orig, map) end)
  end
end

local setup = function(...)
  local commands = {}
  for _, v in ipairs(table.pack(...)) do
    commands[v] = for_op(v)
  end

  return commands
end

return setup(
  "eval",
  "spec-form",
  "info",
  "find-symbol",
  "eldoc",
  "format-code",
  "format-edn",
  "ns-load-all",
  "load-file",
  "macroexpand",
  "rename-file-or-dir"
)
