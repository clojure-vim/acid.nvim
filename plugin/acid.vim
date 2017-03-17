function! AcidOpfunc(callback, block)
  let s:tmp = getreg('s')
  if a:block == 'line'
    normal! '[V']"sy
  elseif a:block == 'visual'
    normal! `<v`>"sy
  else
    normal! `[v`]"sy
  endif
  let s:ret = getreg('s')
  call setreg('s', s:tmp)
  exec a:callback 'opfunc' s:ret
endfunction

function! s:require()
  if exists(':AcidRequire') && expand("%r") !~ ".*test.*"
    AcidRequire
  endif
endfunction

autocmd VimEnter * AcidInit
autocmd BufWritePost,BufReadPost *.clj call s:require()
