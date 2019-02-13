local utils = require("acid.utils")

return function(opts)
  return function(data)
    if not utils.find(data.status, "no-info") then
      return
    end

    return opts.handler(data) -- Will need to transform first though
  end
end
