-- luacheck: globals table vim
local utils = {}

utils.pack = function (...)
  return {n=select('#',...); ...}
end

utils.trim = vim.trim or function(str)
  return vim.api.nvim_call_function("trim", {str})
end

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

  for _, tbl in ipairs(utils.pack(...)) do
    for k, v in pairs(tbl) do
      _new[k] = v
    end
  end

  return _new
end

utils.join = function(...)
  local _new = {}

  for _, tbl in ipairs(utils.pack(...)) do
    for _, v in ipairs(tbl) do
       table.insert(_new, v)
    end
  end

  return _new
end

utils.ends_with = function(str, ending)
  return ending == "" or string.sub(str, -#ending) == ending
end

utils.clone = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utils.clone(orig_key)] = utils.clone(orig_value)
        end
        setmetatable(copy, utils.clone(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

utils.split_lines = function(txt)
  local result = {}
  local regex = ("([^%s]+)"):format("\n")
  for each in txt:gmatch(regex) do
    table.insert(result, each)
  end
  return result
end

utils.random = function(sz)
  local gen = {
    [[head -c 100 /dev/urandom]],
    [[md5sum]],
    [[awk '{print toupper($1)}']],
    [[xargs -I{} echo "obase=10; ibase=16; {}"]],
    [[bc]] ,
    [[tr '\n' ' ']],
    [[sed 's/\\* //g']],
  }

  local random = vim.api.nvim_call_function("system", {
      table.concat(gen, " | ")
    })

  return tonumber(random:sub(1, sz))
end

utils.uuid = function()
 return vim.api.nvim_call_function("AcidNewUUID", {})
end

utils.ulid = require("acid.extra.ulid")

utils.keys = function(tbl)
  local new = {}
  for k, _ in pairs(tbl) do
    table.insert(new, k)
  end
  return new
end

utils.LRU = function(sz)
  return {
    __newindex = function(tbl, key, value)
      local lru = rawget(tbl, "__lru_tbl")
      if lru == nil then
        lru = {}
        rawset(tbl, "__lru_tbl", lru)
      end

      table.insert(lru, key)

      if (#utils.keys(lru) - 1 >= sz) then
        local old = table.remove(lru, 1)
        rawset(tbl, old, nil)
      end

      rawset(tbl, "__lru_tbl", lru)

      rawset(tbl, key, value)
    end
  }
end

return utils

