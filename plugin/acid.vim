function! s:require()
  if !luaeval("require('acid').connected()", v:null)
    return
  endif

  if exists("g:acid_alt_test_paths")
    let test_paths = add(g:acid_alt_test_paths, "test")
  else
    let test_paths = ["test"]
  endif

  for test_path in test_paths
    if expand("%") =~ ".*".test_path.".*"
      return
    endif
  endfor
  let ns = AcidGetNs()

  call luaeval("require('acid').run(require('acid.features').req(_A))", {"ns": ns})
endfunction

function! s:mute()
endfunction

function! AcidMotion(mode)
  exec 'lua require("acid.frontend").eval_expr("'.a:mode.'")'
endfunction

map <silent> cpp <Cmd>set opfunc=AcidMotion<CR>g@


augroup acid
  autocmd BufWritePost *.clj call s:require()
  autocmd User AcidRequired call s:mute()
augroup END

function! AcidJobHandler(id, data, stream)
  call luaeval('require("acid.nrepl").handle[_A[1]](_A[2], _A[3])', [a:stream, a:data, a:id])
endfunction

command! -nargs=? AcidClearVtext lua require('acid.middlewares.virtualtext').clear(<f-args>)
