# tmuxsend.vim
Vim plugin that lets you copy and paste to a different tmux pane.  
Or, you can just copy to the tmux buffer for later.

<img src="https://user-images.githubusercontent.com/12980409/205471326-27ef838a-c164-42a7-a576-2f5af3be95a8.gif" width="100%"/>

- For **interactive development**, similar to Jupyter Notebook. You can paste your code on a bash shell or an ipython interpreter.
- Detects vim/neovim and ipython running, and paste within an appropriate paste mode.

Tested and working on Ubuntu, macOS and Windows WSL.

## Compatible Plugins
- It will detect [Nvim-Tree](https://github.com/nvim-tree/nvim-tree) and copy-paste the file's absolute path.  
- It works great with [treemux](https://github.com/kiyoon/treemux) which shows Nvim-Tree within tmux! Make your terminal like an IDE.

## Installation

Use your favourite plugin manager. I use [vim-plug](https://github.com/junegunn/vim-plug).  
```vim
Plug 'kiyoon/tmuxsend.vim'
```

## Features and Key Bindings

The plugin does NOT come with default key bindings.  
Example configs:  

```vim
" vimscript config
nnoremap <silent> - <Plug>(tmuxsend-smart)	" `1-` sends a line to pane .1
xnoremap <silent> - <Plug>(tmuxsend-smart)	" same, but for visual mode block
nnoremap <silent> _ <Plug>(tmuxsend-plain)	" `1_` sends a line to pane .1 without adding a new line
xnoremap <silent> _ <Plug>(tmuxsend-plain)
nnoremap <silent> <space>- <Plug>(tmuxsend-uid-smart)	" `3<space>-` sends to pane %3
xnoremap <silent> <space>- <Plug>(tmuxsend-uid-smart)
nnoremap <silent> <space>_ <Plug>(tmuxsend-uid-plain)
xnoremap <silent> <space>_ <Plug>(tmuxsend-uid-plain)
nnoremap <silent> <C-_> <Plug>(tmuxsend-tmuxbuffer)		" `<C-_>` yanks to tmux buffer
xnoremap <silent> <C-_> <Plug>(tmuxsend-tmuxbuffer)
```

```lua
-- lua config
local tsend_map_modes = {"n", "x"}
local tsend_map_opts = {noremap = true, silent = true}
vim.keymap.set(tsend_map_modes, "-", "<Plug>(tmuxsend-smart)", tsend_map_opts)
vim.keymap.set(tsend_map_modes, "_", "<Plug>(tmuxsend-plain)", tsend_map_opts)
vim.keymap.set(tsend_map_modes, "<space>-", "<Plug>(tmuxsend-uid-smart)", tsend_map_opts)
vim.keymap.set(tsend_map_modes, "<space>_", "<Plug>(tmuxsend-uid-plain)", tsend_map_opts)
vim.keymap.set(tsend_map_modes, "<C-_>", "<Plug>(tmuxsend-tmuxbuffer)", tsend_map_opts)
```

1. All functions support normal (n) and visual (x) modes. Normal mode mappings will send a single line.
2. Smart / plain modes.
  - smart: detect running program on the destination, and add new lines if they're shell or ipython.
  - plain: do not add new line and send exactly the selected part.
3. Choose pane with relative ID or unique ID (uid).
  - uid makes it possible to send over sessions.
  - For example, `5-` will paste selection (or current line) to the .5 pane.
  - `5<space>-` will paste selection (or current line) to the %5 pane.
  - Use `set -g pane-border-format "#D"` in the tmux.conf to see the pane unique identifier.
4. Choose window by giving number >= 10.
  - For example, `12-` will paste selection (or current line) to window 1 pane 2.
  - `123-` will paste selection (or current line) to window 12 pane 3.
5. Use `<C-_>` to copy into the tmux buffer. You can paste using `Prefix + ]`
6. Omitting the number (e.g. running `-`) will use the previous pane again.



## Recommended tmux.conf settings
```tmux
# Set the base index for windows to 1 instead of 0.
set -g base-index 1

# Set the base index for panes to 1 instead of 0.
setw -g pane-base-index 1

# Show pane details.
set -g pane-border-status top
set -g pane-border-format ' .#P (#D) #{pane_current_command} '
```

## Recommended Nvim-Tree settings
If using the example key bindings above, it is recommended to change Nvim-Tree's keybinding (remove '-' and use 'u' instead):

```lua
require("nvim-tree").setup({
  -- ...
  view = {
	mappings = {
	  list = {
		{ key = "u", action = "dir_up" },
	  },
	},
  },
  remove_keymaps = {
	  '-',
  }
  -- ...
})
```

## Related project
- [vim-slime](https://github.com/jpalardy/vim-slime)
  - Differences: vim-slime focuses on sending to REPL for development, whereas tmuxsend.vim is for more general purpose.
  - tmuxsend.vim can choose which pane to send, even in different windows, different session etc. 
  - tmuxsend.vim can detect the target pane's running program for a better experience (e.g. detects vim and paste in paste mode)
  - tmuxsend.vim does not rely on LSP so it's lighter. Just grab the exact part you need.
    - Tip: use LSP text objects ([treesitter](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)) to easily select function/class/if/loop etc.  
  - tmuxsend.vim can send [Nvim-Tree](https://github.com/nvim-tree/nvim-tree)'s files with absolute path to another pane.
- [vim-screenpaste](https://github.com/kiyoon/vim-screenpaste) if you're using screen.
