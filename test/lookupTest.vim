" Author:  Eric Van Dewoestine
"
" License: {{{
"   Copyright (c) 2005 - 2011, Eric Van Dewoestine
"   All rights reserved.
"
"   Redistribution and use of this software in source and binary forms, with
"   or without modification, are permitted provided that the following
"   conditions are met:
"
"   * Redistributions of source code must retain the above
"     copyright notice, this list of conditions and the
"     following disclaimer.
"
"   * Redistributions in binary form must reproduce the above
"     copyright notice, this list of conditions and the
"     following disclaimer in the documentation and/or other
"     materials provided with the distribution.
"
"   * Neither the name of Eric Van Dewoestine nor the names of its
"     contributors may be used to endorse or promote products derived from
"     this software without specific prior written permission of
"     Eric Van Dewoestine.
"
"   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
"   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
"   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
"   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
"   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
"   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
"   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
"   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
"   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
"   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" }}}

function! TestCommand() " {{{
  view test/files/vimfiles/plugin/testLookup.vim

  " from definition
  call cursor(3, 19)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/after/plugin/testLookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [1, 13])
  call vunit#AssertEquals(getline('.'), 'nmap <c-d> :TestLookupCommand')

  " from reference
  call cursor(1, 12)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/plugin/testLookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [3, 1])
  call vunit#AssertEquals(getline('.'),
    \ 'command! -nargs=* TestLookupCommand <SID>TestLookupFunc()')
endfunction " }}}

function! TestFunction() " {{{
  view test/files/vimfiles/plugin/testLookup.vim

  " from refererence
  call cursor(3, 42)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/plugin/testLookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [5, 1])
  call vunit#AssertEquals(getline('.'), 'function s:TestLookupFunc()')

  " from definition
  call cursor(5, 10)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/plugin/testLookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [3, 37])
  call vunit#AssertEquals(getline('.'),
    \ 'command! -nargs=* TestLookupCommand <SID>TestLookupFunc()')

  " autoload reference
  call cursor(7, 8)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/autoload/testlookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [1, 1])
  call vunit#AssertEquals(getline('.'), 'function! testlookup#TestFunc()')

  " autoload definition
  call cursor(1, 11)
  Lookup
  cnext " first result is the definition
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/plugin/testLookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [7, 8])
  call vunit#AssertEquals(getline('.'), '  call testlookup#TestFunc()')
endfunction " }}}

function! TestVariable() " {{{
  view test/files/vimfiles/plugin/testLookup.vim

  " from definition
  call cursor(1, 5)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/autoload/testlookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [2, 8])
  call vunit#AssertEquals(getline('.'), '  echo g:TestLookupVar')

  " from reference
  call cursor(2, 8)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/plugin/testLookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [1, 1])
  call vunit#AssertEquals(getline('.'), 'let g:TestLookupVar = 1')
endfunction " }}}

function! TestVimrc() " {{{
  view test/files/_vimrc

  " script local var definition
  call cursor(1, 5)
  Lookup
  cnext
  call vunit#AssertEquals(expand('%'), 'test/files/_vimrc')
  call vunit#AssertEquals([line('.'), col('.')], [5, 6])
  call vunit#AssertEquals(getline('.'), 'echo s:testvar')

  " from reference
  call cursor(5, 6)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/_vimrc')
  call vunit#AssertEquals([line('.'), col('.')], [1, 1])
  call vunit#AssertEquals(getline('.'), 'let s:testvar = 1')

  " command reference
  call cursor(3, 12)
  Lookup
  call vunit#AssertEquals(expand('%'), 'test/files/vimfiles/plugin/testLookup.vim')
  call vunit#AssertEquals([line('.'), col('.')], [3, 1])
  call vunit#AssertEquals(getline('.'),
    \ 'command! -nargs=* TestLookupCommand <SID>TestLookupFunc()')
endfunction " }}}

function! TestHelp() " {{{
  view test/files/vimfiles/plugin/testLookup.vim

  " let
  call cursor(1, 1)
  Lookup
  call vunit#AssertEquals(expand('%:t'), 'eval.txt')
  call vunit#AssertTrue(getline('.') =~ '\*:let\*')
  close

  " command -nargs
  call cursor(3, 11)
  Lookup
  call vunit#AssertEquals(expand('%:t'), 'map.txt')
  call vunit#AssertTrue(getline('.') =~ '\*:command-nargs\*')
  close

  " BufEnter
  call cursor(11, 11)
  Lookup
  call vunit#AssertEquals(expand('%:t'), 'autocmd.txt')
  call vunit#AssertTrue(getline('.') =~ '\*BufEnter\*')
  close

  " map <buffer>
  call cursor(14, 6)
  Lookup
  call vunit#AssertEquals(expand('%:t'), 'map.txt')
  call vunit#AssertTrue(getline('.') =~ '\*:map-<buffer>\*')
  close

  " map <buffer>
  call cursor(16, 20)
  Lookup
  call vunit#AssertEquals(expand('%:t'), 'eval.txt')
  " doesn't land the cursor on the exact expression line, but it's correct
  call vunit#AssertTrue(getline('.') =~ '\*expr-=\~')
  close
endfunction " }}}

" vim:ft=vim:fdm=marker
