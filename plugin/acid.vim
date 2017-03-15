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

function! s:init()
  if exists('g:acid_init')
    return 1
  endif
  AcidInit
endfunction

function! s:require_on_save()
  if expand("%r") !~ ".*test.*"
    AcidRequire
  endif
endfunction

autocmd FileType clojure call s:init()
autocmd BufWritePost,BufNewFile *.clj call s:require_on_save()
