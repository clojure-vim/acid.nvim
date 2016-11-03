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

