
augroup acid
  au!
  au FileType clojure
      \ nmap <buffer> <C-F> :AcidGoToDefinition<CR>
  au BufEnter,BufWritePost *.clj AcidRequire
augroup END
