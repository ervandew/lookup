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

" Global Variables {{{
if !exists("g:LookupRuntimePath")
  " possible values ('all', 'relative')
  let g:LookupRuntimePath = 'relative'
endif
if !exists("g:LookupSingleResultAction")
  " possible values ('split', 'edit', 'copen')
  let g:LookupSingleResultAction = 'edit'
endif
" }}}

" Script Variables {{{
  let s:vimdirs = '^\(autoload\|ftdetect\|ftplugin\|indent\|syntax\|plugin\)$'
  let s:keywords = {
      \ '-complete':    'command-completion',
      \ '-nargs':       'E175',
      \ '-range':       'E177',
      \ '-count':       'E177',
      \ '-bang':        'E177',
      \ '-bar':         'E177',
      \ '-buffer':      'E177',
      \ '-register':    'E177',
      \ 'silent':       ':silent',
    \ }

  let s:search = {
      \ 'aug_def': 'aug\(r\|ro\|rou\|roup\)\?!\?\s\+<element>\>',
      \ 'aug_ref': 'au\(g\|gr\|gro\|grou\|group\|t\|to\|toc\|tocm\|tocmd\)\?!\?\s\+<element>\>',
      \ 'cmd_def': 'command!\?\s.\{-}\<<element>\>',
      \ 'cmd_ref': '\<<element>\>',
      \ 'func_def': 'fu\(n\|nc\|nct\|ncti\|nctio\|nction\)\?!\?\s\+<element>\>',
      \ 'func_ref': '\<<element>\>',
      \ 'var_def': '\<let\s\+\(g:\)\?<element>\>',
      \ 'var_ref': '\<<element>\>',
    \ }

  let s:count = {
      \ 'cmd_def': '1',
      \ 'func_def': '1',
    \ }

  let s:syntax_to_help = {
      \ 'vimAutoCmd': 'autocmd',
      \ 'vimAutoEvent': '<element>',
      \ 'vimAutoGroupKey': 'augroup',
      \ 'vimCommand': ':<element>',
      \ 'vimFuncKey': ':<element>',
      \ 'vimFuncName': '<element>()',
      \ 'vimGroup': 'hl-<element>',
      \ 'vimHLGroup': 'hl-<element>',
      \ 'vimLet': ':<element>',
      \ 'vimMap': ':<element>',
      \ 'vimMapModKey': ':map-<<element>>',
      \ 'vimNotFunc': ':<element>',
      \ 'vimOper': 'expr-<element>',
      \ 'vimOption': "'<element>'",
      \ 'vimUserAttrbCmplt': ':command-completion-<element>',
      \ 'vimUserAttrbKey': ':command-<element>',
      \ 'vimUserCommand': ':<element>',
    \ }
" }}}

function! lookup#Lookup(bang) " {{{
  let line = getline('.')
  let syntax = synIDattr(synID(line('.'), col('.'), 1), 'name')

  let type = ''
  let element = substitute(
    \ line, '.\{-}\(\(<[a-zA-Z]\+>\)\?[[:alnum:]_:#]*' .
    \ '\%' . col('.') . 'c[[:alnum:]_:#]*\).*', '\1', '')

  if element =~? '^<sid>'
    let element = 's:' . element[5:]
  endif

  " on a function
  if element =~ '^[[:alnum:]#_:]\+$' &&
   \ (element =~ '^[A-Z]' || element =~ '[#:]') &&
   \ line =~ '[[:alnum:]_:#]*\%' . col('.') . 'c[[:alnum:]_:#]*\s*('
    let type = 'func'

  " on a command ref
  elseif element =~ '^:[A-Z]\w*$' ||
       \ (element =~ '^[A-Z]\w*$' && syntax == 'vimIsCommand')
    let type = 'cmd'
    if element =~ '^:'
      let element = element[1:]
    endif

  " on a variable
  elseif element =~ '^[bgsl]:\w\+$'
    let type = 'var'

  " on an augroup name
  elseif line =~ 'aug\(r\|ro\|rou\|roup\)\?!\?\s\+\w*\%' . col('.') . 'c\w*'
    let type = 'aug'

  " doc lookup
  else
    let char = line[col('.') - 1]
    if element == '' && char =~ '\W' && char !~ '\s'
      let element = substitute(line, '.\{-}\(\W*\%' . col('.') . 'c\W*\).*', '\1', '')
      let element = substitute(element, '\(^.\{-}\s\+\|\s\+.\{-}$\)', '', 'g')
    endif

    let help = get(s:syntax_to_help, syntax, '')
    if help == ''
      let base = synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name')
      if base == 'Statement'
        let help = ':<element>'
      endif

      " vim variables
      if element =~ '^v:'
        let help = '<element>'
      endif

      " option refrence
      if line =~ '&' . element . '\>'
        let help = s:syntax_to_help['vimOption']
      endif
    endif

    if help != ''
      exec 'help ' . substitute(help, '<element>', element, '')
      return
    endif
  endif

  if type != ''
    let def = substitute(s:search[type . '_def'], '<element>', element, '')

    " on a definition, search for references
    if line =~ def
      call s:Find(element, a:bang, type . '_ref')

    " on a reference, search for definition.
    else
      call s:Find(element, a:bang, type . '_def')
    endif
  endif
endfunction " }}}

function! s:Find(element, bang, context) " {{{
  let element = a:element
  echoh Statement | echo "Searching for '" . element . "'..." | echoh Normal

  let cnt = get(s:count, a:context, '')
  let search = substitute(s:search[a:context], '<element>', element, '')

  call setqflist([])

  let save_opt = &eventignore
  set eventignore=all
  try
    " if a script local function search current file.
    if element =~ '^[ls]:.*'
      if a:context =~ '_ref'
        let search = '\(<SID>\|s:\)' . element[2:] . '\>'
      endif
      let command = cnt . 'vimgrepadd /' . search . '/gj %'
      silent! exec command

    " search globally
    else
      for path in s:Paths()
        if isdirectory(path)
          let path .= '/**/*.vim'
        endif
        let path = escape(substitute(path, '\', '/', 'g'), ' ')
        let command = cnt . 'vimgrepadd /' . search . '/gj' . ' ' . path
        " must use silent! otherwise an error on one path may suppress finding
        " of results on subsiquent paths even w/ a try/catch (vim bug most
        " likely)
        silent! exec command
        if a:context == 'def' && len(getqflist()) > 0
          break
        endif
      endfor
    endif
  finally
    let &eventignore = save_opt
  endtry

  let qflist = getqflist()
  if len(qflist) == 0
    echoh WarningMsg | echo "No results found for '" . element . "'." | echoh Normal
  else
    if a:bang != ''
      copen
    elseif len(qflist) == 1
      if g:LookupSingleResultAction == 'edit'
        cfirst
        if foldclosed(line('.')) != -1
          foldopen!
        endif
      elseif g:LookupSingleResultAction == 'split'
        let file = bufname(qflist[0].bufnr)
        if file != expand('%')
          let winnr = bufwinnr(bufnr('^' . file))
          if winnr != -1
            exec winnr . 'winc w'
          else
            silent exec 'split ' . escape(file, ' ')
          endif
        endif
        call cursor(qflist[0].lnum, qflist[0].col)
        if foldclosed(line('.')) != -1
          foldopen!
        endif
      else
        copen
      endif
    else
      cfirst
      if foldclosed(line('.')) != -1
        foldopen!
      endif
    endif

    if exists('g:EclimSignLevel')
      for result in qflist
        let result['type'] = 'i'
      endfor
      call setqflist(qflist)
      call eclim#display#signs#Update()
    endif
  endif
endfunction " }}}

function! s:Paths() " {{{
  if g:LookupRuntimePath == 'relative'
    let file = expand('%:t')
    let path = expand('%:p:h')

    " for vimrc files, look for relative .vim or vimfiles directory
    if file =~ '^[._]g\?vimrc$'
      if isdirectory(path . '/.vim')
        return [expand('%:p'), path . '/.vim']
      elseif isdirectory(path . '/vimfiles')
        return [expand('%:p'), path . '/vimfiles']
      endif
    endif

    while fnamemodify(path, ':t') !~ s:vimdirs
      let path = fnamemodify(path, ':h')
      " we hit the root of the filesystem, so just use the file's directory
      if path == '/' || path =~ '^[a-zA-Z]:\\$'
        return [expand('%:p:h')]
      endif
    endwhile
    let path = fnamemodify(path, ':h')
    " handle vim's after directory
    if fnamemodify(path, ':t') == 'after'
      let path = fnamemodify(path, ':h')
    endif
    return [path]
  endif

  return split(&rtp, ',')
endfunction " }}}

" vim:ft=vim:fdm=marker
