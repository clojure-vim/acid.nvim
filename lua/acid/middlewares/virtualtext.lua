-- luacheck: globals vim
local virtualtext = {}
local forms = require("acid.forms")

virtualtext.name = "virtualtext"

virtualtext.ns = vim.api.nvim_create_namespace("acid")

virtualtext.toggle = function()
  local cb = vim.api.nvim_get_current_buf()
  local coords = forms.get_form_boundaries(true)

  local extmarks = vim.api.nvim_buf_get_extmarks(cb, virtualtext.ns, coords.from, coords.to, {details = true})

  local nxt = extmarks[1]

  nxt[4].priority = 10
  nxt[4].id = nxt[1]

  -- TODO fix
  nxt[4].end_line = nxt[4].end_row
  nxt[4].end_row = nil

  vim.api.nvim_buf_set_extmark(
    0,
    virtualtext.ns,
    nxt[2],
    nxt[3] ,
    nxt[4]
    )


  --if #possible_vts > 1 then
    --current_ix = current_ix - 1
    --if current_ix == 0 then
      --current_ix = #possible_vts
    --end
  --end

  --vim.api.nvim_buf_set_virtual_text(cb, virtualtext.ns, ln, possible_vts[current_ix], {})
  --vim.api.nvim__buf_redraw_range(cb, ln, ln)
  --virtualtext.cache_index[key] = current_ix

end

virtualtext.middleware = function(config)
  return function(middleware)
    return function(data)
      if data.status then
        return
      end

      local vt = {}

      if data.ex ~= nil then
        table.insert(vt, {data.ex, "Exception"})
      elseif data.err ~= nil then
        table.insert(vt, {data.err, "Error"})
      elseif data.out ~= nil then
          table.insert(vt, {data.out:gsub("\n", "\\n"), "String"})
      elseif data.value ~= nil and data.value ~= "nil" then
        table.insert(vt, {data.value, "Function"})
      elseif data.value == "nil" then
        table.insert(vt, {"nil", "Delimiter"})
      end

      if #vt > 0 then
        table.insert(vt, 1, {";; => ", "Comment"})

        vim.api.nvim_buf_set_extmark(
          0,
          virtualtext.ns,
          config.from[1] - 1,
          config.from[2] - 1 ,
          {
            end_line = config.to[1] - 1,
            end_col = config.to[2] - 1,
            virt_text = vt
        })

        -- TODO split_lines
        --vim.api.nvim_buf_set_virtual_text(cb, virtualtext.ns, ln, vt, {})
        --vim.api.nvim__buf_redraw_range(cb, ln, ln)

      end
      return middleware(data)
    end
  end
end

virtualtext.clear = function(ln)
  local cb = vim.api.nvim_get_current_buf()
  local from, to

  if ln ~= nil then
    from = ln
    to = ln + 1
  else
    from = 0
    to = -1
  end

  vim.api.nvim_buf_clear_namespace(cb, virtualtext.ns, from, to)
end

return virtualtext
