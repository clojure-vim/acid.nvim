local utils = require("acid.utils")
local doc = {}

doc.middleware = function(_)
  return function(middleware)
    return function(data)
      if not utils.find(data.status, "no-info") then
        return
      end

      return middleware(data) -- Will need to transform first though
    end
  end
end

return doc
