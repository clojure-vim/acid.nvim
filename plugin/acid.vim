if !exists("g:acid_skip_test_paths")
  let g:acid_skip_test_paths = 1
endif

if !exists("g:acid_start_admin_nrepl")
  let g:acid_start_admin_nrepl = 0
endif

if !exists("g:acid_no_require_on_save")
  let g:acid_no_require_on_save = 0
endif

let g:acid_no_default_keymappings = get(g:, 'acid_no_default_keymappings', 0)

function! AcidWrappedSend(payload, handler)
  let conn = luaeval("require('acid.connections').attempt_get(_A)", getcwd())
  if type(conn) == type(v:null)
    call luaeval("require('acid.log').msg(_A)", "No active connection to a nrepl session. Aborting")
    return
  endif

  let luafn = "function(data) vim.api.nvim_call_function(_A[2], {data}) end"

  call luaeval("require('acid.core').register_callback(_A[1], ".luafn.", _A[3])", [conn, a:handler, a:payload.id])
  call AcidSendNrepl(a:payload, conn)
endfunction

function! <SID>require()
  if g:acid_no_require_on_save || (exists("b:acid_no_require_on_save") && b:acid_no_require_on_save)
    return
  endif
  if !luaeval("require('acid').connected()", v:null)
    return
  endif

  if g:acid_skip_test_paths
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
  endif
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

function! AcidCleanNs()
  call search("(ns")
  exec "normal vaf\<Esc>"
  lua require("acid.features").clean_ns()
endfunction

function! AcidMotion(mode)
  exec 'lua require("acid.features").eval_expr("'.a:mode.'", false)'
endfunction

function! AcidEvalInplace(mode)
  exec 'lua require("acid.features").eval_expr("'.a:mode.'", true)'
endfunction

function! AcidSendEval(handler)
  let ns = AcidGetNs()
  if ns == ""
    let ns = "user"
  endif
  call inputsave()
  let code = input(ns."=> ")
  call inputrestore()
  echo
  call luaeval("require('acid.features')." . a:handler ."(_A[1], _A[2])", [code, ns])
endfunction

function! AcidEval(code)
  call luaeval("require('acid.features').eval_print(_A)", a:code)
endfunction

function! AcidJobHandler(id, data, stream)
  call luaeval('require("acid.nrepl").handle[_A[1]](_A[2], _A[3])', [a:stream, a:data, a:id])
endfunction

function! AcidJobCleanup(id, data, _)
  call luaeval('require("acid.nrepl").cleanup(_A[1])', [a:id])
endfunction


map <Plug>(acid-interrupt)        <Cmd>lua require("acid.features").interrupt()<CR>
map <Plug>(acid-go-to)            <Cmd>lua require("acid.features").go_to()<CR>
map <Plug>(acid-go-to)            <Cmd>lua require("acid.features").go_to()<CR>
map <Plug>(acid-docs)             <Cmd>lua require("acid.features").docs()<CR>

map <Plug>(acid-eval-cmdline)     <Cmd>call AcidSendEval("eval_cmdline")<CR>

map <Plug>(acid-motion-op)        <Cmd>set opfunc=AcidMotion<CR>g@
map <Plug>(acid-eval-symbol)      <Cmd>call AcidMotion("symbol")<CR>
map <Plug>(acid-eval-visual)      <Cmd>call AcidMotion("visual")<CR>
map <Plug>(acid-eval-top-expr)    <Cmd>lua require("acid.features").eval_expr("top")<CR>
map <Plug>(acid-eval-expr)        <Cmd>lua require("acid.features").eval_expr()<CR>

map <Plug>(acid-eval-print)       <Cmd>call AcidSendEval("eval_print")<CR>

map <Plug>(acid-replace-op)       <Cmd>set opfunc=AcidEvalInplace<CR>g@
map <Plug>(acid-replace-symbol)   <Cmd>call AcidEvalInplace("symbol")<CR>
map <Plug>(acid-replace-visual)   <Cmd>call AcidEvalInplace("visual")<CR>

map <Plug>(acid-replace-top-expr) <Cmd>lua require("acid.features").eval_expr("top", true)<CR>
map <Plug>(acid-replace-expr)     <Cmd>lua require("acid.features").eval_expr(nil, true)<CR>

map <Plug>(acid-thread-first)     <Cmd>lua require("acid.features").thread_first()<CR>
map <Plug>(acid-thread-last)      <Cmd>lua require("acid.features").thread_last()<CR>

map <Plug>(acid-virtualtext-clear-line) <Cmd>call luaeval("require('acid.middlewares.virtualtext').clear(_A)", line('.'))<CR>
map <Plug>(acid-virtualtext-toggle)     <Cmd>call luaeval("require('acid.middlewares.virtualtext').toggle()", v:null)<CR>
map <Plug>(acid-virtualtext-clear-all)  <Cmd>call luaeval("require('acid.middlewares.virtualtext').clear(nil)", v:null)<CR>

map <Plug>(acid-output-open)      <Cmd>call luaeval("require('acid.output').open()", v:null)<CR>
map <Plug>(acid-output-close)     <Cmd>call luaeval("require('acid.output').close()", v:null)<CR>
map <Plug>(acid-output-clear)     <Cmd>call luaeval("require('acid.output').clear()", v:null)<CR>

map <Plug>(acid-run-tests)       <Cmd>lua require("acid.features").run_test{}<CR>
map <Plug>(acid-run-tests-here)  <Cmd>lua require("acid.features").run_test{['get-ns'] = true}<CR>
map <Plug>(acid-run-the-tests)   <Cmd>lua require("acid.features").run_test{['get-symbol'] = true, ['get-ns'] = true}<CR>

augroup acid
  autocmd!
  autocmd BufWritePost *.clj call <SID>require()

  autocmd User AcidConnected lua require("acid.sessions").new_session()
  autocmd User AcidConnected lua require("acid.features").preload()
  autocmd User AcidConnected lua require("acid.features").load_all_nss()

  autocmd User AcidRequired call s:mute()
  autocmd User AcidPreloadedCljFns call s:mute()
  autocmd User AcidLoadedAllNSs call s:mute()
  autocmd User AcidImported call s:mute()
augroup END

if !g:acid_no_default_keymappings
  augroup acid-keymappings
    autocmd!
    autocmd FileType clojure nmap <buffer> <silent> <C-c><C-c> <Plug>(acid-interrupt)
    autocmd FileType clojure nmap <buffer> <silent> gd         <Plug>(acid-go-to)
    autocmd FileType clojure nmap <buffer> <silent> K          <Plug>(acid-docs)
    autocmd FileType clojure nmap <buffer> <silent> <C-c>x     <Plug>(acid-eval-cmdline)
    autocmd FileType clojure imap <buffer> <silent> <C-c>x     <Cmd>call AcidSendEval("eval_cmdline")<CR>

    autocmd FileType clojure nmap <buffer> <silent> ctf        <Plug>(acid-thread-first)
    autocmd FileType clojure nmap <buffer> <silent> ctl        <Plug>(acid-thread-last)

    autocmd FileType clojure nmap <buffer> <silent> cp         <Plug>(acid-motion-op)
    autocmd FileType clojure vmap <buffer> <silent> cp         <Plug>(acid-eval-visual)
    autocmd FileType clojure nmap <buffer> <silent> cps        <Plug>(acid-eval-symbol)
    autocmd FileType clojure nmap <buffer> <silent> cpt        <Plug>(acid-eval-top-expr)
    autocmd FileType clojure nmap <buffer> <silent> cpp        <Plug>(acid-eval-expr)
    autocmd FileType clojure nmap <buffer> <silent> cqp        <Plug>(acid-eval-print)

    autocmd FileType clojure nmap <buffer> <silent> <C-c>ta    <Plug>(acid-run-tests)
    autocmd FileType clojure nmap <buffer> <silent> <C-c>tt    <Plug>(acid-run-tests-here)
    autocmd FileType clojure nmap <buffer> <silent> <C-c>tj    <Plug>(acid-run-the-tests)

    autocmd FileType clojure nmap <buffer> <silent> cr         <Plug>(acid-replace-op)
    autocmd FileType clojure vmap <buffer> <silent> cr         <Plug>(acid-replace-visual)
    autocmd FileType clojure nmap <buffer> <silent> crs        <Plug>(acid-replace-symbol)
    autocmd FileType clojure nmap <buffer> <silent> crt        <Plug>(acid-replace-top-expr)
    autocmd FileType clojure nmap <buffer> <silent> crr        <Plug>(acid-replace-expr)

    autocmd FileType clojure map <buffer> <silent> <C-c>ll     <Plug>(acid-virtualtext-clear-line)
    autocmd FileType clojure map <buffer> <silent> <C-c>ln     <Plug>(acid-virtualtext-toggle)
    autocmd FileType clojure map <buffer> <silent> <C-c>la     <Plug>(acid-virtualtext-clear-all)

    autocmd FileType clojure map <buffer> <silent> <C-c>oo     <Plug>(acid-output-open)
    autocmd FileType clojure map <buffer> <silent> <C-c>ox     <Plug>(acid-output-close)
    autocmd FileType clojure map <buffer> <silent> <C-c>ol     <Plug>(acid-output-clear)
  augroup END
endif

if g:acid_start_admin_nrepl
  lua require('acid').admin_session_start()
endif

command! -nargs=0 AcidConnectNrepl lua require('acid.nrepl').start{}
command! -nargs=? AcidClearVtext lua require('acid.middlewares.virtualtext').clear(<f-args>)
command! -nargs=* AcidRequire lua require('acid.features').do_require(<f-args>)
command! -nargs=1 AcidAddRequire call AcidFnAddRequire("[<args>]")
command! -nargs=* AcidEval call AcidEval("<args>")
