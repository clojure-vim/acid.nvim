-- luacheck: globals vim
local forms = require("acid.forms")
local utils = require("acid.utils")
local floats = {}

floats.cache = {}

floats.config = {
  accessor = function(_, data)
    if data.ex ~= nil then
      return utils.split_lines(data.ex)
    elseif data.err ~= nil then
      return utils.split_lines(data.err)
    elseif data.out ~= nil then
      return utils.split_lines(data.out)
    elseif data.value ~= nil and data.value ~= "nil" then
      return utils.split_lines(data.value)
    end
  end,
  get_positions = function(_, lines)
  local cwin = vim.api.nvim_call_function("win_getid", {})
  local width = vim.api.nvim_call_function("winwidth", {cwin})
  local height = #lines
  local win_height = vim.api.nvim_call_function("winheight", {cwin})

    return {
      width = width,
      height = height,
      row = win_height - height,
      col = 0,
      relative = "win"
    }
  end
}

-- FIXME Needs to close the window
floats.middleware = function(config)
  if vim.api.nvim_open_win == nil then
    return function(middleware)
      return function(data)
        return middleware(data)
      end
    end
  end

  return function(middleware)
    return function(data)
      floats.close(config.cb)
      config.buff = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(config.buff, "bufhidden", "wipe")

      local lines = config:accessor(data)

      vim.api.nvim_buf_set_lines(config.buff, 0, -1, false, lines)

      local pos = config:get_positions(lines)

      config.winid = vim.api.nvim_open_win(config.buff, false, pos.width, pos.height, {
        relative = pos.relative,
        row = pos.row,
        col = pos.col
      })

      vim.api.nvim_win_set_option(config.winid, "number", false)
      vim.api.nvim_win_set_option(config.winid, "relativenumber", false)

      floats.cache[config.cb] = config.winid

      vim.api.nvim_call_function("execute", {{
          "function! DynamicAcidSetCleaner" .. config.cb .. "(...)",
          "lua require('acid.middlewares.floats').set_cleaner(" .. config.cb .. ")",
          "endfunction"
      }})

    vim.api.nvim_call_function("timer_start",{
        "50", "DynamicAcidSetCleaner" .. config.cb
      })

      return middleware(data)
    end
  end
end

floats.set_cleaner = function(buffer)
  vim.api.nvim_command(
    [[au CursorMoved * once call luaeval('require("acid.middlewares.floats").close(]] ..
    buffer ..
    ")', v:null)"
  )

  vim.api.nvim_command(
    [[au CursorMovedI * once call luaeval('require("acid.middlewares.floats").close(]] ..
    buffer ..
    ")', v:null)"
  )
end

floats.close = function(buffer)
  local winid = floats.cache[buffer]

  if winid ~= nil then
    vim.api.nvim_win_close(winid, true)
    floats.cache[buffer] = nil
  end
end

return floats
