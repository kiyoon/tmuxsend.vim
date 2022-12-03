" tmuxpaste.vim - Paste your code to another tmux pane.
" Maintainer:   Kiyoon Kim <https://kiyoon.kim/>
" Version:      1.0
"
" Press <num>- to copy and paste lines to tmux pane <num>.
" For example, 1- will paste selection (or current line)
" to pane 1 on the current window.
"
" If number not specified, then it will paste to pane 0.
"
" If the number is >= 10, it will paste to the pane on another window.
" For example, 12- will paste selection (or current line)
" to window 1 pane 2.
" 123- will paste selection (or current line)
" to window 12 pane 3.
"
" Use <leader>- (typically \-) to copy using the unique pane identifier.
" For example, 5\- will paste selection (or current line)
" to the %5 pane.
" Use `set -g pane-border-format "#D"` in the tmux.conf to see the pane identifier.
"
" Use _ instead of - to copy without hitting Return.
" Use <C-_> to copy into the tmux buffer. You can paste using C-b ] (or commonly C-a ] depending on your setup.).

if exists('g:loaded_tmuxpaste') || &compatible
  finish
else
  let g:loaded_tmuxpaste = 'yes'
endif


let plugin_dir = fnamemodify(fnamemodify(resolve(expand('<sfile>:p')), ':h'), ':h')


function! NvimTreeFilePath()
	" Get file path if NvimTree is open
	if has('nvim') && &filetype == 'NvimTree'
lua << EOF
		nt_api = require('nvim-tree.api')
		vim.l.filepath = nt_api.get_node_at_cursor().absolute_path
EOF
		return l:filepath
	endif

	return ''
endfunction

function! DetectRunningProgram(paneIdentifier)
	" Detects if VIM or iPython is running on a tmux pane.
	" Returns: 'vim', 'ipython', or 'others'
	"
	let l:runningProgram = system(g:plugin_dir . "/scripts/tmux_pane_current_command_full.sh '" . a:paneIdentifier . "'")
	if v:shell_error != 0
		" echo "Can't find the tmux pane using the identifier " . a:paneIdentifier
		return 'error'
	endif

	if empty(runningProgram)
		return '-shell'
	else
		let l:programName = trim(system('tmux display -pt ' . a:paneIdentifier . " '#{pane_current_command}'"))
		if l:programName ==# 'vi' || l:programName ==# 'vim' || l:programName ==# 'nvim'
			return 'vim'
		elseif stridx(l:runningProgram, '/ipython ') > 0
			return 'ipython'
		endif
	endif
	return 'others'
endfunction

function! TmuxAddBuffer(content, stripEmptyLines)
	" Add content to the Tmux buffer.
	" Paste using C-a ]
	
	" NvimTree is open. Get the file path instead of copying the content.
	if has('nvim') && &filetype == 'NvimTree'
lua << EOF
		print('nvimtree detected')
		nt_api = require('nvim-tree.api')
		vim.g.kiyoontmuxpasteContent = nt_api.tree.get_node_under_cursor().absolute_path
		if vim.g.kiyoontmuxpasteContent == nil then
			nt_nodes = nt_api.tree.get_nodes()
			vim.g.kiyoontmuxpasteContent = nt_nodes.absolute_path 	-- root dir path
		end
EOF
		let l:content = " '" . g:kiyoontmuxpasteContent . "'"
	else
		let l:content = a:content
	endif
	
	if a:stripEmptyLines == 0
		" When splitting, do not strip the empty lines back and forth. (keepempty=1)
		" Stripping can result in not overwriting the file when it's empty.
	
		let splitContent = split(l:content, '\n', 1)
	else
		let splitContent = split(l:content, '\n', 0)
	endif

	if empty(splitContent)
		" If the content is empty, vimscript may not write a file,
		" and tmux does not update the buffer with an empty string.
		call system("tmux set-buffer -b vim-tmuxpaste '\n'")
	else
		let tempname = tempname()
		call writefile(splitContent, tempname, 'b')
		call system("tmux load-buffer -b vim-tmuxpaste " . tempname)
		call delete(tempname)
	endif
endfunction

function! TmuxPaste(targetPane, content, addReturn, targetProgram)
	" Paste content to the targetPane.
	" If addReturn is 1, then add a return at the end.
	" targetProgram: 'vim', 'ipython', or 'others'
	
	" Check if the targetPane is present.
	call system("tmux list-panes -t '" . a:targetPane . "'")
	if v:shell_error != 0
		echo "Can't find the tmux pane using the identifier " . a:targetPane
		return 'error'
	endif

	if a:targetProgram ==# 'ipython'
		" If the target pane is running ipython, strip empty lines to make it clean.
		call TmuxAddBuffer(a:content, 1)
	else
		call TmuxAddBuffer(a:content, 0)
	endif

	call system("tmux paste-buffer -t '" . a:targetPane . "' -b vim-tmuxpaste -p")

	if a:addReturn == 1
		call system("tmux send-keys -t '" . a:targetPane . "' " . 'Enter')
		if a:targetProgram ==? 'ipython' && len(split(a:content, "\n", 0)) > 1
			" ipython needs two empty lines to execute the code.
			" with an exception that it is a single line.
			call system("tmux send-keys -t '" . a:targetPane . "' " . 'Enter')
		endif
	endif

	let pastedPaneName = trim(system("tmux display -pt '" . a:targetPane . "' '#{session_name}:#{window_index}.#{pane_index}'"))
	echo 'Paste to tmux: ' . pastedPaneName . ' (' . a:targetProgram . ')'
	redraw!
endfunction

function! NumberToPaneIdentifier(count)
	" Pass v:count as input.
	" Returns the tmux pane identifier.
	" If count < 10, then it will find the pane within the same window. (.1, .2, ...)
	" If count >= 10, then it will find the window and pane with the index. (11 -> 1.1, 12 -> 1.2, 123 -> 12.3, ...)
	return string(a:count)[:-2] . '.' . string(a:count)[-1:]
endfunction

" Commands that only work in a TMUX session.
if !empty($TMUX)
	" 1. save count to pasteTarget
	" 2. yank using @s register.
	" 3. detect if vim or ipython is running
	" 4. execute paste command.
	nnoremap <silent> - :<C-U>let pasteTarget=NumberToPaneIdentifier(v:count)<CR>"syy:call TmuxPaste(pasteTarget, @s, 1, DetectRunningProgram(pasteTarget))<CR>
	vnoremap <silent> - :<C-U>let pasteTarget=NumberToPaneIdentifier(v:count)<CR>gv"sy:call TmuxPaste(pasteTarget, @s, 1, DetectRunningProgram(pasteTarget))<CR>
	"""""""""""""""
	" Same thing but <num>_ to paste without detecting running programs and without the return at the end.
	nnoremap <silent> _ :<C-U>let pasteTarget=NumberToPaneIdentifier(v:count)<CR>"syy:call TmuxPaste(pasteTarget, @s, 0, 'nodetect')<CR>
	vnoremap <silent> _ :<C-U>let pasteTarget=NumberToPaneIdentifier(v:count)<CR>gv"sy:call TmuxPaste(pasteTarget, @s, 0, 'nodetect')<CR>

	""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
else
	noremap <silent> - :<C-U>echo 'You are not in a tmux session. Use unique pane identifier. e.g. 5\- sends text to %5.'<CR>
	noremap <silent> _ :<C-U>echo 'You are not in a tmux session. Use unique pane identifier. e.g. 5\- sends text to %5.'<CR>
endif

" pasting using the unique pane identifier. 5\- will paste to the pane %5.
nnoremap <silent> <leader>- :<C-U>let pasteTarget='%' . v:count<CR>"syy:call TmuxPaste(pasteTarget, @s, 1, DetectRunningProgram(pasteTarget))<CR>
vnoremap <silent> <leader>- :<C-U>let pasteTarget='%' . v:count<CR>gv"sy:call TmuxPaste(pasteTarget, @s, 1, DetectRunningProgram(pasteTarget))<CR>

nnoremap <silent> <leader>_ :<C-U>let pasteTarget='%' . v:count<CR>"syy:call TmuxPaste(pasteTarget, @s, 0, 'nodetect')<CR>
vnoremap <silent> <leader>_ :<C-U>let pasteTarget='%' . v:count<CR>gv"sy:call TmuxPaste(pasteTarget, @s, 0, 'nodetect')<CR>

"""""""""""""""
" Copy to tmux buffer. You don't need to be on a tmux session to do this.
nnoremap <silent> <C-_> "syy:call TmuxAddBuffer(@s, 0)<CR>
vnoremap <silent> <C-_> "sy:call TmuxAddBuffer(@s, 0)<CR>
