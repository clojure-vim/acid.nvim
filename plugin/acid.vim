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

function! AcidFnAddRequire(req)
  call search("(ns")
  exec "normal vaf\<Esc>"
  exec 'lua require("acid.features").add_require("'.a:req.'")'
endfunction

function! AcidMotion(mode)
  exec 'lua require("acid.features").eval_expr("'.a:mode.'")'
endfunction

function! AcidSendEval(handler)
  let ns = AcidGetNs()
  if ns == v:null
    let ns = "user"
  endif
  call inputsave()
  let code = input(ns."=> ")
  call inputrestore()
  call luaeval("require('acid.features')." . a:handler ."(_A[1], _A[2])", [code, ns])
endfunction



augroup acid
  autocmd BufWritePost *.clj call s:require()

  autocmd User AcidConnected lua require("acid.features").preload()
  autocmd User AcidConnected lua require("acid.features").load_all_nss()

  autocmd User AcidRequired call s:mute()
  autocmd User AcidPreloadedCljFns call s:mute()
  autocmd User AcidLoadedAllNSs call s:mute()
  autocmd User AcidImported call s:mute()

  au FileType clojure nmap <buffer> <silent> <C-]> <Cmd>lua require("acid.features").go_to()<CR>
  au FileType clojure nmap <buffer> <silent> K <Cmd>lua require("acid.features").docs()<CR>
  au FileType clojure nmap <buffer> <silent> <C-c>x <Cmd>call AcidSendEval("eval_cmdline")<CR>
  au FileType clojure imap <buffer> <silent> <C-c>x <Cmd>call AcidSendEval("eval_cmdline")<CR>
  au FileType clojure map <buffer> <silent> cp <Cmd>set opfunc=AcidMotion<CR>g@
  au FileType clojure map <buffer> <silent> cpp <Cmd>lua require("acid.features").eval_expr()<CR>

  au FileType clojure map <buffer> <silent> <C-c>ll <Cmd>call luaeval("require('acid.middlewares.virtualtext').clear(_A)", line('.'))<Cr>
  au FileType clojure map <buffer> <silent> <C-c>ln <Cmd>call luaeval("require('acid.middlewares.virtualtext').toggle()", v:null)<Cr>
  au FileType clojure map <buffer> <silent> <C-c>la <Cmd>call luaeval("require('acid.middlewares.virtualtext').clear(nil)", v:null)<Cr>
augroup END

function! AcidJobHandler(id, data, stream)
  call luaeval('require("acid.nrepl").handle[_A[1]](_A[2], _A[3])', [a:stream, a:data, a:id])
endfunction

command! -nargs=? AcidClearVtext lua require('acid.middlewares.virtualtext').clear(<f-args>)
command! -nargs=* AcidRequire lua require('acid.features').do_require(<f-args>)
command! -nargs=1 AcidAddRequire call AcidFnAddRequire("[<args>]")
