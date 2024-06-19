.. Copyright (c) 2010 - 2024, Eric Van Dewoestine
   All rights reserved.

   Redistribution and use of this software in source and binary forms, with
   or without modification, are permitted provided that the following
   conditions are met:

   * Redistributions of source code must retain the above
     copyright notice, this list of conditions and the
     following disclaimer.

   * Redistributions in binary form must reproduce the above
     copyright notice, this list of conditions and the
     following disclaimer in the documentation and/or other
     materials provided with the distribution.

   * Neither the name of Eric Van Dewoestine nor the names of its
     contributors may be used to endorse or promote products derived from
     this software without specific prior written permission of
     Eric Van Dewoestine.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Lookup is a plugin for vim/nvim plugin developers which provides functionality
to quickly and easily lookup docs for vim/nvim elements, or in the case of user
defined functions, commands, or variables, find the definition or occurrences of
the element.

.. note::

   Lookup of user defined functions, commands, and variables is limited to
   vimscript. Lua support can be found via a lua lsp.

While editing a vim or lua file (or viewing a vim/nvim help file), you can
lookup the element under the cursor using:

::

    :Lookup

You can also map this command so that you simply need to hit <cr> on an element
to look it up by adding the following to a ftplugin/vim.vim file in your
vimfiles directory (%HOME%/vimfiles on Windows, ~/.vim on Linux/OSX):

.. code-block:: vim

  if bufname('%') !~ '^\(command-line\|\[Command Line\]\)$'
    nnoremap <silent> <buffer> <cr> :Lookup<cr>
  endif

Or like so when using lazy.nvim:

.. code-block:: lua

  {
    'ervandew/lookup',
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'help', 'lua', 'vim' },
        callback = function()
          vim.keymap.set('n', '<cr>', ':Lookup<cr>', { buffer = true, silent = true })
        end
      })
    end
  }

For more details please see the lookup vim docs (:help lookup).
