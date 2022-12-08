# tmuxsend.vim
Vim plugin that lets you copy and paste to a different tmux pane.  
Or, you can just copy to the tmux buffer for later.

<img src="https://user-images.githubusercontent.com/12980409/205471326-27ef838a-c164-42a7-a576-2f5af3be95a8.gif" width="100%"/>

- For **interactive development**, similar to Jupyter Notebook. You can paste your code on a bash shell or an ipython interpreter.
- Detects vim/neovim and ipython running, and paste within an appropriate paste mode.

Tested and working on Ubuntu, macOS and Windows WSL.

## Compatible plugins
- It will detect [Nvim-Tree](https://github.com/nvim-tree/nvim-tree) and copy-paste the file's absolute path.  
- It works great with [tmux-side-nvim-tree](https://github.com/kiyoon/tmux-side-nvim-tree)! Make your terminal like an IDE.


## Key bindings
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
```vim
Plug 'kiyoon/tmuxsend.vim'
```

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
Recommended to change Nvim-Tree's keybinding (remove '-' and use 'u' instead):

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
