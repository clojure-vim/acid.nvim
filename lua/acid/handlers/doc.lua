local utils = require("acid.utils")

return function(data)
  if not utils.find(data.status, "no-info") then
    return
  end

  return data -- Will need to transform first though
end
