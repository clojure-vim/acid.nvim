local utils = require("acid.utils")

local composable = function(map)
  map.type = "command"

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
  return map
end

local nop = function(_) return end

local new = function(op)
  return composable{}:with_payload{op = op}
end

local for_op = function(op)
  return function(map)
    return new(op)
    :with_handler(nop)
    :update_payload(function(orig) return utils.merge(orig, map) end)
  end
end

return setmetatable({}, {__index = function(_, op)
  return for_op(op)
  end
})
