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

utils.find = function(coll, val)
  if coll == nil then
    return false
  end

  local check
  local tp = type(val)

  if tp == "string" then
    check = function(k, v)
      return k == val or v == val
    end
  elseif tp == "number" then
    check = function(_, v)
      return v == val
    end
  elseif tp == "function" then
    check = val
  else
    return false
  end

  for i, v in pairs(coll) do
    if check(i, v) then
      return true
    end
  end
  return false
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

utils.ends_with = function(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end


return utils

