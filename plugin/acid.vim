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

  call luaeval("require('acid.features').do_require(_A)", ns)
endfunction

function! s:mute()
endfunction

function! AcidMotion(mode)
  exec 'lua require("acid.features").eval_expr("'.a:mode.'")'
endfunction

map <silent> cpp <Cmd>set opfunc=AcidMotion<CR>g@
map <silent> <C-c>l <Cmd>call luaeval("require('acid.middlewares.virtualtext').clear(_A)", line('.'))<Cr>
map <silent> <C-c><C-l> <Cmd>call luaeval("require('acid.middlewares.virtualtext').clear(nil)", v:null)<Cr>


augroup acid
  autocmd BufWritePost *.clj call s:require()
  autocmd User AcidRequired call s:mute()
augroup END

function! AcidJobHandler(id, data, stream)
  call luaeval('require("acid.nrepl").handle[_A[1]](_A[2], _A[3])', [a:stream, a:data, a:id])
endfunction

command! -nargs=? AcidClearVtext lua require('acid.middlewares.virtualtext').clear(<f-args>)
command! -nargs=* AcidRequire lua require('acid.features').do_require(<f-args>)
