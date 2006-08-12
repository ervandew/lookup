" Author:  Eric Van Dewoestine
" Version: ${eclim.version}
"
" Description: {{{
"   see http://eclim.sourceforge.net/vim/vim/find.html
"
" License:
"
" Copyright (c) 2005 - 2006
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"      http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.
"
" }}}

" Global Variables {{{
if !exists("g:EclimVimPaths")
  let g:EclimVimPaths = &runtimepath
endif
if !exists("g:EclimVimFindSingleResult")
  " possible values ('split', 'edit', 'lopen')
  let g:EclimVimFindSingleResult = "split"
endif
" }}}

" Script Variables {{{
  let s:search{'cmd_def'} = 'command\s.\{-}\<<name>\>'
  let s:search{'cmd_ref'} = ':\s*<name>\>'
  let s:search{'func_def'} = 'fu\(n\|nc\|nct\|ncti\|nctio\|nction\)\?[!]\?\s\+<name>\>'
  let s:search{'func_ref'} = '\<<name>\>'
  let s:search{'var_def'} = '\<let\s\+\(g:\)\?<name>\>'
  let s:search{'var_ref'} = '\<<name>\>'

  let s:count{'cmd_def'} = '1'
  let s:count{'cmd_ref'} = ''
  let s:count{'func_def'} = '1'
  let s:count{'func_ref'} = ''
  let s:count{'var_def'} = ''
  let s:count{'var_ref'} = ''

  let s:type{'cmd_def'} = 'user defined command'
  let s:type{'cmd_ref'} = s:type{'cmd_def'}
  let s:type{'func_def'} = 'user defined function'
  let s:type{'func_ref'} = s:type{'func_def'}
  let s:type{'var_def'} = 'global variable'
  let s:type{'var_ref'} = s:type{'var_def'}

  let s:valid{'cmd_def'} = '^\w\+$'
  let s:valid{'cmd_ref'} = s:valid{'cmd_def'}
  let s:valid{'func_def'} = '\(:\|#\|^\)[A-Z]\w\+$'
  let s:valid{'func_ref'} = s:valid{'func_def'}
  let s:valid{'var_def'} = '^\w\+$'
  let s:valid{'var_ref'} = s:valid{'var_def'}

  let s:extract{'cmd_def'} = '\(.*:\|.*\s\|^\)\(.*\%<col>c.\{-}\)\(\W.*\|\s.*\|$\)'
  let s:extract{'cmd_ref'} = s:extract{'cmd_def'}
  let s:extract{'func_def'} = '\(.*\s\|^\)\(.*\%<col>c.\{-}\)\((.*\|\s.*\|$\)'
  let s:extract{'func_ref'} = s:extract{'func_def'}
  let s:extract{'var_def'} =
    \ "\\(.*g:\\|.*[[:space:]\"'(\\[{,]\\)" .
    \ "\\(.*\\%<col>c.\\{-}\\)" .
    \ "\\([[:space:]\"')\\]},].*\\|$\\)"
  let s:extract{'var_ref'} = s:extract{'var_def'}

  let s:trim{'cmd_def'} = ''
  let s:trim{'cmd_ref'} = s:trim{'cmd_def'}
  let s:trim{'func_def'} = ''
  let s:trim{'func_ref'} = s:trim{'func_def'}
  let s:trim{'var_def'} = '^\(g:\)\(.*\)'
  let s:trim{'var_ref'} = s:trim{'var_def'}
" }}}

" FindByContext(name, bang) {{{
" Contextual find that determines the type of element under the cursor and
" executes the appropriate find.
function! eclim#vim#find#FindByContext (bang)
  let line = getline('.')

  let element = substitute(line,
    \ "\\(.*[[:space:]\"'(\\[{]\\|^\\)\\(.*\\%" .
    \ col('.') . "c.\\{-}\\s*(\\).*",
    \ '\2', '')

  " on a function
  if line =~ '\%' . col('.') . 'c[[:alnum:]#:]\+\s*('
    let element = substitute(element, '\s*(.*', '', '')
    let type = 'func'

  " on a command ref
  elseif line =~ '\W:\w*\%' . col('.') . 'c'
    let element = substitute(line, '.*:\(.*\%' . col('.') . 'c\w*\).*', '\1', '')
    let type = 'cmd'

  " on a command def
  elseif line =~ '^\s*:\?\<command\>.*\s\w*\%' . col('.') . 'c\w*\(\s\|$\)'
    let element = substitute(line, '.*\s\(.*\%' . col('.') . 'c\w*\).*', '\1', '')
    let type = 'cmd'

  " on a variable
  else
    let element = substitute(line,
      \ "\\(.*[[:space:]\"'(\\[{]\\|^\\)\\(.*\\%" .
      \ col('.') . "c.\\{-}\\)\\([[:space:]\"')\\]}].*\\|$\\)",
      \ '\2', '')

    let type = 'var'
  endif

  if element == line || element !~ '^[[:alnum:]:#]\+$'
    return
  endif

  let def = substitute(s:search{type . '_def'}, '<name>', element, '')

  " on a definition, search for references
  if line =~ def
    call s:Find(element, a:bang, type . '_ref')

  " on a reference, search for definition.
  else
    call s:Find(element, a:bang, type . '_def')
  endif
endfunction " }}}

" FindCommandDef(name, bang) {{{
" Finds the definition of the supplied user defined command.
function! eclim#vim#find#FindCommandDef (name, bang)
  call s:Find(a:name, a:bang, 'cmd_def')
endfunction " }}}

" FindCommandRef(name, bang) {{{
" Finds the definition of the supplied user defined command.
function! eclim#vim#find#FindCommandRef (name, bang)
  call s:Find(a:name, a:bang, 'cmd_ref')
endfunction " }}}

" FindFunctionDef(name, bang) {{{
" Finds the definition of the supplied user defined function.
function! eclim#vim#find#FindFunctionDef (name, bang)
  call s:Find(a:name, a:bang, 'func_def')
endfunction " }}}

" FindFunctionRef(name, bang) {{{
" Finds the definition of the supplied user defined function.
function! eclim#vim#find#FindFunctionRef (name, bang)
  call s:Find(a:name, a:bang, 'func_ref')
endfunction " }}}

" FindVariableDef(name, bang) {{{
" Finds the definition of the supplied variable.
function! eclim#vim#find#FindVariableDef (name, bang)
  call s:Find(a:name, a:bang, 'var_def')
endfunction " }}}

" FindVariableRef(name, bang) {{{
" Finds the definition of the supplied variable.
function! eclim#vim#find#FindVariableRef (name, bang)
  call s:Find(a:name, a:bang, 'var_ref')
endfunction " }}}

" Find(name, bang, context) {{{
function! s:Find (name, bang, context)
  let name = a:name
  if name == ''
    let line = getline('.')
    let regex = substitute(s:extract{a:context}, '<col>', col('.'), 'g')
    let name = substitute(line, regex, '\2', '')
  endif

  " last chance to clean up the extracted value.
  let regex = s:trim{a:context}
  if regex != ''
    let name = substitute(name, regex, '\2', '')
  endif

  if name !~ s:valid{a:context}
    call eclim#util#EchoInfo('Not a valid ' . s:type{a:context} . ' name.')
    return
  endif

  call eclim#util#EchoInfo("Searching for '" . name . "'...")

  let cnt = s:count{a:context}
  let search = substitute(s:search{a:context}, '<name>', name, '')

  call setloclist(0, [])

  let save_opt = &eventignore
  set eventignore=all
  try
    " if a script local function search current file.
    if name =~ '^s:.*'
      silent! exec cnt . 'lvimgrepadd /' . search . '/gj' . ' ' . expand('%:p')

    " search globally
    else
      for path in split(g:EclimVimPaths, ',')
        " ignore eclim added dir as parent dir will be searched
        if path =~ '\<eclim$'
          continue
        endif

        silent! exec cnt . 'lvimgrepadd /' . search . '/gj' . ' ' . path . '/**/*.vim'
        if a:context == 'def' && len(getloclist(0)) > 0
          break
        endif
      endfor
    endif
  finally
    let &eventignore = save_opt
  endtry

  let loclist = getloclist(0)
  if len(loclist) == 0
    call eclim#util#EchoInfo("No results found for '" . name . "'.")
  elseif len(loclist) == 1
    if g:EclimVimFindSingleResult == 'edit'
      lfirst
    elseif g:EclimVimFindSingleResult == 'split'
      let file = bufname(loclist[0].bufnr)
      if file != expand('%')
        silent exec "split " . file
      endif
      call cursor(loclist[0].lnum, loclist[0].col)
    else
      lopen
    endif
  elseif a:bang != ''
    lopen
  else
    lfirst
  endif
  call eclim#util#EchoInfo('')
endfunction " }}}

" vim:ft=vim:fdm=marker
