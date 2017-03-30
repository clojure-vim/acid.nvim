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
  exec a:callback s:ret
endfunction

function! AcidPrompt(callback)
  call inputsave()
  let s:ret = input(a:callback . " → ")
  call inputrestore()
  exec a:callback s:ret
endfunction

function! AcidShorthand(callback, shorthand)
  let s:tmp = getreg('s')
  let s:iskw = &iskeyword
  setl iskeyword+=/
  silent exec a:shorthand
  exec "setl iskeyword=".s:iskw
  let s:ret = getreg('s')
  call setreg('s', s:tmp)
  exec a:callback s:ret
endfunction

function! s:require()
  if exists("g:acid_alt_test_paths")
    let test_paths = add(g:acid_alt_test_paths, "test")
  else
    let test_paths = ["test"]
  endif

  if exists(':AcidRequire')
    for test_path in test_paths
      if expand("%") !~ ".*".test_path.".*"
        return
      endif
    endfor

    AcidRequire
  endif
endfunction

autocmd VimEnter * AcidInit
autocmd BufWritePost,BufReadPost *.clj call s:require()
