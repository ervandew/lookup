let g:TestLookupVar = 1

command! -nargs=* TestLookupCommand <SID>TestLookupFunc()

function s:TestLookupFunc()
  echo g:TestLookupVar
  call testlookup#TestFunc()
endfunction

augroup test_lookup
  autocmd BufEnter <buffer> echo 'foo'
augroup END

map <buffer> <c-c> :TestLookupCommand<cr>

if g:TestLookupVar =~? '1'
  echo '1'
endif
