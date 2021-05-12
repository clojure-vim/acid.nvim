-- luacheck: globals vim
local quickfix = {}



quickfix.name = "quickfix"

quickfix.config = {}

vim.fn.setqflist({}, ' ', {
  title = "[acid] clojure.test failures",
})

quickfix.config.qflistid = vim.fn.getqflist({id = 0,
  title = "[acid] clojure.test failures",
}).id

quickfix.set = function(config)
  return function(middleware)
    return function(data)
      if data.results ~= nil then
        local qf = {}
        for ns, tests in pairs(data.results) do
          for test, asserts in pairs(tests) do
            for _, assert in ipairs(asserts) do
              if assert.type ~= "pass" then
                local fpath = vim.fn.globpath(
                  vim.fn.getcwd(),
                  '**/' .. assert.file,
                  false,
                  true)[1]
                local obj = {
                  module = ns .. "/" .. test,
                  lnum  = assert.line,
                  nr = assert.index + 1,
                  valid = assert.context,
                  type = 'F',
                  filename = fpath
                }

                if assert.type == 'fail' then
                  obj.text = assert.actual .. " != " .. assert.expected
                elseif assert.type == 'error' then
                  obj.text = assert.error
                end

                table.insert(qf, obj)
              end
            end
          end
        end
        vim.fn.setqflist({}, 'r', {
            id = config.qflistid,
            items = qf
          })
      end

      return middleware(data)
    end
  end
end

quickfix.middleware = quickfix.set

return quickfix
