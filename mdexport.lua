local inspect = require("inspect")
local tap = function(x)
  local remove_mt = function(item, path)
  if path[#path] ~= inspect.METATABLE then return item end
  end
  print(inspect(x, {process = remove_mt}))
  return x
end
local format_param = function(nm, descr, mods)
  local p_str
  if mods.opt then
    p_str = "*" .. nm .. "*"
  else
    p_str = nm
  end

  if mods['type'] ~= nil then
    p_str = p_str .. " **(" .. mods['type'] .. ")**"
  end

  p_str = p_str .. ":" .. descr

  return p_str
end

local format_ret = function(ret)
  local p_str = ""

  if ret['type'] ~= nil then
    p_str = "**(" .. ret['type'] .. ")** "
  end

  p_str = p_str .. ret.text

  return p_str
end

return {
   filter = function (t)
      for ix, mod in ipairs(t) do
        if ix > 1 then
          print("")
          print("---")
          print("")
        end
        print("# " .. mod.name)
        print(mod.summary)

        for _, fn in ipairs(mod.items) do
          print("")
          if fn['type'] == 'function' then
            print("## `" .. mod.name .. "." .. fn.name .. fn.args .. "`")
            if fn.summary ~= nil then
              print(fn.summary)
              print("")
            end
            for _, nm in ipairs(fn.params) do
              print(format_param(nm, fn.params.map[nm], fn.modifiers.param[nm] or {}))
              print("")
              if fn.subparams[nm] ~= nil then
                print("Parameters for table `" .. nm .. "` are:")
                print("")
                for _, subp in ipairs(fn.subparams[nm]) do
                  print("* " .. format_param(subp, fn.params.map[subp], fn.modifiers.param[subp]))
                end
              end
            end
            if fn.retgroups ~= nil then
              print("")
              for _, retg in ipairs(fn.retgroups) do
                for _, ret in ipairs(retg) do
                  print(format_ret(ret))
                  print("")
                end
              end
            end
          elseif fn['type'] == 'table' then
            print("## `" .. fn.name .. "`")
            if fn.summary ~= nil then
              print(fn.summary)
              print("")
            end
            print("Values:")
            print("")
            for _, v in ipairs(fn.params) do
            print("* `" .. v .. "`")
            end
          end

        end
      end
   end
}
