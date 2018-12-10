"function! s:require()
  "if exists("g:acid_alt_test_paths")
    "let test_paths = add(g:acid_alt_test_paths, "test")
  "else
    "let test_paths = ["test"]
  "endif

  "if exists(':AcidRequire')
    "for test_path in test_paths
      "if expand("%") =~ ".*".test_path.".*"
        "return
      "endif
    "endfor

    "AcidRequire
  "endif
"endfunction

function! AcidJobHandler(id, data, stream)
  call luaeval('require("acid.nrepl").handle[_A[1]](_A[2], _A[3])', [a:stream, a:data, a:id])
endfunction
