" tmuxsend.vim - Send your code to another tmux pane.
" Maintainer:   Kiyoon Kim <https://kiyoon.kim/>
" Version:      1.1

if exists('g:loaded_tmuxsend') || &compatible
  finish
else
  let g:loaded_tmuxsend = 'yes'
  let g:tmuxsend_previous_pane = '.0'
endif


let plugin_dir = fnamemodify(fnamemodify(resolve(expand('<sfile>:p')), ':h'), ':h')


function! tmuxsend#NvimTreeFilePath()
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

function! tmuxsend#DetectRunningProgram(paneIdentifier)
	" Detects if VIM or iPython is running on a tmux pane.
	" Returns: 'vim', 'ipython', or 'others'
	"
	let l:runningProgram = trim(system(g:plugin_dir . "/scripts/tmux_pane_current_command_full.sh '" . a:paneIdentifier . "'"))
	if v:shell_error != 0
		" echo "Can't find the tmux pane using the identifier " . a:paneIdentifier
		return 'error'
	endif

	if empty(l:runningProgram)
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

function! tmuxsend#TmuxAddBuffer(content, buffername, stripEmptyLines)
	" Add content to the Tmux buffer.
	" Paste using C-a ]
	
	" NvimTree is open. Get the file path instead of copying the content.
	if has('nvim') && &filetype == 'NvimTree'
lua << EOF
		nt_api = require('nvim-tree.api')
		vim.g.kiyoontmuxsendContent = nt_api.tree.get_node_under_cursor().absolute_path
		if vim.g.kiyoontmuxsendContent == nil then
			nt_nodes = nt_api.tree.get_nodes()
			vim.g.kiyoontmuxsendContent = nt_nodes.absolute_path 	-- root dir path
		end
EOF
		let l:content = " '" . g:kiyoontmuxsendContent . "'"
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
		call system("tmux set-buffer -b " . a:buffername . " '\n'")
	else
		let tempname = tempname()
		call writefile(splitContent, tempname, 'b')
		call system("tmux load-buffer -b " . a:buffername . " " . tempname)
		call delete(tempname)
	endif
endfunction

function! tmuxsend#TmuxPaste(targetPane, content, addReturn, targetProgram)
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
		call tmuxsend#TmuxAddBuffer(a:content, 'vim-tmuxsend-temp', 1)
	else
		call tmuxsend#TmuxAddBuffer(a:content, 'vim-tmuxsend-temp', 0)
	endif

	call system("tmux paste-buffer -t '" . a:targetPane . "' -b vim-tmuxsend-temp -p")

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

	let g:tmuxsend_previous_pane = a:targetPane
endfunction

function! tmuxsend#NumToPaneID(count)
	" Pass v:count as input.
	" Returns the tmux pane identifier.
	" If count < 10, then it will find the pane within the same window. (.1, .2, ...)
	" If count >= 10, then it will find the window and pane with the index. (11 -> 1.1, 12 -> 1.2, 123 -> 12.3, ...)
	if a:count == 0
		return g:tmuxsend_previous_pane
	endif

	return string(a:count)[:-2] . '.' . string(a:count)[-1:]
endfunction

" Commands that only work in a TMUX session.
if !empty($TMUX)
	" 1. save count to pasteTarget
	" 2. yank using @s register.
	" 3. detect if vim or ipython is running
	" 4. execute paste command.
	nnoremap <Plug>(tmuxsend-smart) :<C-U>let pasteTarget=tmuxsend#NumToPaneID(v:count)<CR>"syy:call tmuxsend#TmuxPaste(pasteTarget, @s, 1, tmuxsend#DetectRunningProgram(pasteTarget))<CR>
	xnoremap <Plug>(tmuxsend-smart) :<C-U>let pasteTarget=tmuxsend#NumToPaneID(v:count)<CR>gv"sy:call tmuxsend#TmuxPaste(pasteTarget, @s, 1, tmuxsend#DetectRunningProgram(pasteTarget))<CR>
	"""""""""""""""
	" Same thing but <num>_ to paste without detecting running programs and without the return at the end.
	nnoremap <Plug>(tmuxsend-plain) :<C-U>let pasteTarget=tmuxsend#NumToPaneID(v:count)<CR>"syy:call tmuxsend#TmuxPaste(pasteTarget, @s, 0, 'nodetect')<CR>
	xnoremap <Plug>(tmuxsend-plain) :<C-U>let pasteTarget=tmuxsend#NumToPaneID(v:count)<CR>gv"sy:call tmuxsend#TmuxPaste(pasteTarget, @s, 0, 'nodetect')<CR>

	""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
else
	nnoremap <Plug>(tmuxsend-smart) :<C-U>echo 'You are not in a tmux session. Use unique pane identifier. e.g. 5\- sends text to %5.'<CR>
	xnoremap <Plug>(tmuxsend-smart) :<C-U>echo 'You are not in a tmux session. Use unique pane identifier. e.g. 5\- sends text to %5.'<CR>
	nnoremap <Plug>(tmuxsend-plain) :<C-U>echo 'You are not in a tmux session. Use unique pane identifier. e.g. 5\- sends text to %5.'<CR>
	xnoremap <Plug>(tmuxsend-plain) :<C-U>echo 'You are not in a tmux session. Use unique pane identifier. e.g. 5\- sends text to %5.'<CR>
endif

" pasting using the unique pane identifier. 5\- will paste to the pane %5.
nnoremap <Plug>(tmuxsend-uid-smart) :<C-U>let pasteTarget='%' . v:count<CR>"syy:call tmuxsend#TmuxPaste(pasteTarget, @s, 1, tmuxsend#DetectRunningProgram(pasteTarget))<CR>
xnoremap <Plug>(tmuxsend-uid-smart) :<C-U>let pasteTarget='%' . v:count<CR>gv"sy:call tmuxsend#TmuxPaste(pasteTarget, @s, 1, tmuxsend#DetectRunningProgram(pasteTarget))<CR>

nnoremap <Plug>(tmuxsend-uid-plain) :<C-U>let pasteTarget='%' . v:count<CR>"syy:call tmuxsend#TmuxPaste(pasteTarget, @s, 0, 'nodetect')<CR>
xnoremap <Plug>(tmuxsend-uid-plain) :<C-U>let pasteTarget='%' . v:count<CR>gv"sy:call TmuxPaste(pasteTarget, @s, 0, 'nodetect')<CR>

"""""""""""""""
" Copy to tmux buffer. You don't need to be on a tmux session to do this.
nnoremap <Plug>(tmuxsend-tmuxbuffer) "syy:call tmuxsend#TmuxAddBuffer(@s, 'vim-tmuxsend', 0)<CR>
xnoremap <Plug>(tmuxsend-tmuxbuffer) "sy:call tmuxsend#TmuxAddBuffer(@s, 'vim-tmuxsend', 0)<CR>
