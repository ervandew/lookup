" Author:  Eric Van Dewoestine
"
" License: {{{
"   Copyright (c) 2005 - 2024, Eric Van Dewoestine
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
      \ 'cmd_def': 'command!\?\s\(-\w\+\(=\S\+\)\?\_s*\\\?\s*\)*\<<element>\>',
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
" }}}

function! lookup#Lookup(bang, element) " {{{
  let element = a:element
  let line = getline('.')
  if element == ''
    if &ft == 'help'
      let ts = v:false
      if has('nvim')
        let ts = luaeval(
          \ 'vim.treesitter.highlighter.active[' . bufnr() . '] ~= nil'
        \ )
      endif

      if has('nvim') && ts == v:true
        let link = luaeval(
          \ 'vim.treesitter.get_node():parent():type()'
        \ ) == 'taglink'
      else
        let synid = synID(line('.'), col('.'), 1)
        let link = synIDattr(synid, "name") == 'helpHyperTextJump'
      endif

      if link
        let element = substitute(
          \ line,
          \ '.\{-}|\(.\{-}\%' . col('.') . 'c.\{-}\)|.*',
          \ '\1',
          \ ''
        \)
        if element == line
          let element = ''
        endif
      endif
    endif
    if element == ''
      let element = substitute(
        \ line, '.\{-}\(\(<[a-zA-Z]\+>\)\?[[:alnum:]_:#.&]*' .
        \ '\%' . col('.') . 'c[[:alnum:]_:#.&]*(\?\).*', '\1', '')
    endif
  endif

   " option reference
  if element =~ '^&'
    let element = "'" . element[1:] . "'"
  " vim global in lua
  elseif element =~ '^vim\.g\.'
    let element = substitute(element, 'vim\.g\.', 'g:', '')
  " option reference (in lua)
  elseif element =~ '^vim.[bgw]\?o\(pt\)\?\(_local\|_global\)\?\.'
    let element = substitute(element, '.*\.', '', '')
    let element = substitute(element, ':.*', '', '')
    let element = "'" . element . "'"
  elseif element =~ '^vim\.api\.'
    let element = element[8:]
  elseif element =~ '^vim\.fn\.'
    let element = element[7:]
  elseif element =~ '^vim\.uv\.'
    let element = element[4:]
  endif

  let help_entries = getcompletion(element, 'help')
  call filter(help_entries, 'v:val =~ "^[:'']\\?' . element . '\\w*\\W*$"')

  if len(help_entries)
    exec 'help ' . element
    return v:true
  endif

  let type = ''

  if element =~? '^<sid>'
    let element = 's:' . element[5:]
  endif

  " on a variable or script scoped function
  if element =~ '^[bgsl]:\w\+(\?$'
    let type = 'var'

    " edge case for script scoped function
    if element =~ '^s:' &&
      \ line =~ '[[:alnum:]_:#]*\%' . col('.') . 'c[[:alnum:]_:#]*\s*('
      let type = 'func'
    endif

  " on a function
  elseif element =~ '^[[:alnum:]#_]\+(\?$' &&
       \ (element =~ '^[A-Z]' || element =~ '[#]') &&
       \ (line == '' || line =~ '[[:alnum:]_#]*\%' . col('.') . 'c[[:alnum:]_#]*\s*(')
    let type = 'func'

  " on a command ref
  elseif element =~ '^:[A-Z]\w*$'
    let type = 'cmd'
    if element =~ '^:'
      let element = element[1:]
    endif

  " on an augroup name
  elseif line =~ 'aug\(r\|ro\|rou\|roup\)\?!\?\s\+\w*\%' . col('.') . 'c\w*'
    let type = 'aug'
  endif

  if type != ''
    if element =~ '($'
      let element = element[:-2]
    endif

    let def = substitute(s:search[type . '_def'], '<element>', element, '')

    " on a definition, search for references
    if line =~ def
      return s:Find(element, a:bang, type . '_ref')
    endif

    " on a reference, search for definition.
    return s:Find(element, a:bang, type . '_def')
  endif
  return v:false
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
    return v:false
  endif

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

  return v:true
endfunction " }}}

function! s:Paths() " {{{
  if g:LookupRuntimePath == 'relative'
    let file = expand('%:t')
    let path = expand('%:p:h')

    " for vimrc files, look for relative .vim or vimfiles directory
    if file =~ '^[._]g\?vimrc'
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
