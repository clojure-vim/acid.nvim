-- luacheck: globals vim
local forms = require("acid.forms")
local floats = {}

floats.cache_index = {}
floats.cache = {}

-- FIXME Needs to close the window
floats.set = function(_)
  if vim.api.nvim_open_win == nil then
    return function(middleware)
      return function(data)
        return middleware(data)
      end
    end
  end

  return function(middleware)
    return function(data)
      if data.status then
        return
      end

      local spl = function(txt)
        local result = {}
           local regex = ("([^%s]+)"):format("\n")
           for each in txt:gmatch(regex) do
              table.insert(result, each)
           end
           return result
        end

      local cur_win = vim.api.nvim_get_current_win()

      local buff = vim.api.nvim_create_buf(false, true)

      local lines = {}

      if data.ex ~= nil then
        lines = spl(data.ex)
      elseif data.err ~= nil then
        lines = spl(data.err)
      elseif data.out ~= nil then
        lines = spl(data.out)
      elseif data.value ~= nil and data.value ~= "nil" then
        lines = spl(data.value)
        vim.api.nvim_buf_set_option(buff, "filetype", "clojure")
      end

      vim.api.nvim_buf_set_lines(buff, 0, -1, false, lines)

      local _, coords = forms.form_under_cursor()

      local winid = vim.api.nvim_open_win(buff, false, 40, #lines, {
        relative = "win",
        row = coords.to[1],
        col = coords.to[2]
      })

      vim.api.nvim_win_set_option(winid, "number", false)
      vim.api.nvim_win_set_option(winid, "relativenumber", false)


      return middleware(data)
    end
  end
end

floats.middleware = floats.set

return floats
