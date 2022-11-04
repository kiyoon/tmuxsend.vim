# vim-tmuxpaste
Vim plugin that lets you copy and paste to a different tmux pane.

![screenpaste-demo](https://user-images.githubusercontent.com/12980409/199625262-e4e6b901-11e8-47b9-8b30-91809281f6be.gif)

- For **interactive development**, similar to Jupyter Notebook. You can paste your code on a bash shell or an ipython interpreter.
- Detects vim/neovim and ipython running, and paste within an appropriate paste mode.


Note that it:
- Uses many system calls. Tested mainly on Ubuntu and Windows WSL.


## Features
- Press \<num\>- to copy and paste lines to tmux pane \<num\>.
  - For example, `1-` will paste selection (or current line) to pane 1 on the current window.
- If number not specified, then it will paste to pane 0.
- If the number is >= 10, it will paste to the pane on another window.
  - For example, 12- will paste selection (or current line) to window 1 pane 2.
  - 123- will paste selection (or current line) to window 12 pane 3.
-
- Use \<leader\>- (typically `\-`) to copy using the unique pane identifier.
  - For example, `5\-` will paste selection (or current line) to the %5 pane.
  - Use `set -g pane-border-format "#D"` in the tmux.conf to see the pane identifier.
- Use _ instead of - to copy without hitting Return.
- Use \<C-\_\> to copy into the tmux buffer. You can paste using C-b \] (or commonly C-a \] depending on your setup.).


## Installation

Use your favourite plugin manager. I use [vim-plug](https://github.com/junegunn/vim-plug).  
TL; DR: just add the following lines to your `.vimrc`. It will install vim-plug and this plugin all together.
```vim
" Install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

call plug#begin()
Plug 'kiyoon/vim-tmuxpaste'
call plug#end()
```
