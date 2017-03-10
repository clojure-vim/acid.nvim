if exists('g:acid_init')
  finish
endif

function! s:init()
  if exists('g:acid_init')
    return 1
  endif
  AcidInit
endfunction

function! s:require()
  if (exists('g:acid_auto_require')
        \ && g:acid_auto_require
        \ && expand('%') !~ 'test/.*_test.clj')
    AcidRequire
  endif
endfunction

augroup acid
  au!
  au FileType clojure
      \ call s:init()
  au BufEnter,BufWritePost *.clj call s:require()
augroup END

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
