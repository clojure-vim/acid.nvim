-- luacheck: globals table
local utils = {}

utils.interleave_first = function(tbl, itn)
  local new = {}
  for _, v in ipairs(tbl) do
    table.insert(new, itn)
    table.insert(new, v)
  end

  return new
end

utils.map = function(tbl, fn)
  local new = {}

  for _, v in ipairs(tbl) do
    table.insert(new, fn(v))
  end

  return new
end

utils.merge = function(...)
  local _new = {}

  for _, tbl in ipairs(table.pack(...)) do
    for k, v in pairs(tbl) do
      _new[k] = v
    end
  end

  return _new
end

utils.join = function(...)
  local _new = {}

  for _, tbl in ipairs(table.pack(...)) do
    for _, v in ipairs(tbl) do
       table.insert(_new, v)
    end
  end

  return _new
end

return utils

