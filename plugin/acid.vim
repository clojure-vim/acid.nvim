if !exists("g:acid_skip_test_paths")
  let g:acid_skip_test_paths = 1
endif

let g:acid_no_default_keymappings = get(g:, 'acid_no_default_keymappings', 0)

function! AcidWrappedSend(payload, handler)
  let conn = luaeval("require('acid.connections').attempt_get(_A)", getcwd())
  if type(conn) == type(v:null)
    call luaeval("require('acid.log').msg(_A)", "No active connection to a nrepl session. Aborting")
    return
  endif

  let luafn = "function(data) vim.api.nvim_call_function(_A[2], {data}) end"

  let session = luaeval("require('acid.core').register_callback(_A[1], ".luafn.")", [conn, a:handler])
  call AcidSendNrepl(a:payload, session, conn)
endfunction

function! s:require()
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

function! AcidMotion(mode)
  exec 'lua require("acid.features").eval_expr("'.a:mode.'")'
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

map <Plug>(acid-go-to)        <Cmd>lua require("acid.features").go_to()<CR>
map <Plug>(acid-docs)         <Cmd>lua require("acid.features").docs()<CR>
map <Plug>(acid-eval-cmdline) <Cmd>call AcidSendEval("eval_cmdline")<CR>
map <Plug>(acid-motion-op)    <Cmd>set opfunc=AcidMotion<CR>g@
map <Plug>(acid-eval-symbol)  <Cmd>call AcidMotion("symbol")<CR>
map <Plug>(acid-eval-visual)  <Cmd>call AcidMotion("visual")<CR>
map <Plug>(acid-eval-expr)    <Cmd>lua require("acid.features").eval_expr()<CR>
map <Plug>(acid-eval-print)   <Cmd>call AcidSendEval("eval_print")<CR>

map <Plug>(acid-virtualtext-clear-line) <Cmd>call luaeval("require('acid.middlewares.virtualtext').clear(_A)", line('.'))<CR>
map <Plug>(acid-virtualtext-toggle)     <Cmd>call luaeval("require('acid.middlewares.virtualtext').toggle()", v:null)<CR>
map <Plug>(acid-virtualtext-clear-all)  <Cmd>call luaeval("require('acid.middlewares.virtualtext').clear(nil)", v:null)<CR>

augroup acid
  autocmd!
  autocmd BufWritePost *.clj call s:require()

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
    autocmd FileType clojure nmap <buffer> <silent> gd     <Plug>(acid-go-to)
    autocmd FileType clojure nmap <buffer> <silent> K      <Plug>(acid-docs)
    autocmd FileType clojure nmap <buffer> <silent> <C-c>x <Plug>(acid-eval-cmdline)
    autocmd FileType clojure imap <buffer> <silent> <C-c>x <Plug>(acid-eval-cmdline)
    autocmd FileType clojure nmap <buffer> <silent> cp     <Plug>(acid-motion-op)
    autocmd FileType clojure vmap <buffer> <silent> cp     <Plug>(acid-eval-visual)
    autocmd FileType clojure nmap <buffer> <silent> cps    <Plug>(acid-eval-symbol)
    autocmd FileType clojure nmap <buffer> <silent> cpp    <Plug>(acid-eval-expr)
    autocmd FileType clojure nmap <buffer> <silent> cqp    <Plug>(acid-eval-print)

    autocmd FileType clojure map <buffer> <silent> <C-c>ll <Plug>(acid-virtualtext-clear-line)
    autocmd FileType clojure map <buffer> <silent> <C-c>ln <Plug>(acid-virtualtext-toggle)
    autocmd FileType clojure map <buffer> <silent> <C-c>la <Plug>(acid-virtualtext-clear-all)
  augroup END
endif

command! -nargs=? AcidClearVtext lua require('acid.middlewares.virtualtext').clear(<f-args>)
command! -nargs=* AcidRequire lua require('acid.features').do_require(<f-args>)
command! -nargs=1 AcidAddRequire call AcidFnAddRequire("[<args>]")
command! -nargs=* AcidEval call AcidEval("<args>")
