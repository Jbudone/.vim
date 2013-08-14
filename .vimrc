
" python import vim " some functionality requires python support

set background=dark
set sessionoptions-=options
call pathogen#infect()
syntax on
filetype plugin indent on
" au BufNewFile,BufEnter,WinEnter,TabEnter,BufWinEnter *.md set filetype=markdown
au VimEnter,BufEnter,WinEnter,TabEnter *.less set filetype=css
au BufRead,BufNewFile *.des set syntax=levdes
" au * * ":try | :CSExactColors | catch | | endtry"
au VimEnter * silent! :CSExactColors
au BufNewFile,BufRead,VimEnter * if &ft == '' | set ft=noext | endif
set backspace=indent,eol,start


" Allow CSApprox to do its magic (color fixing)
if &term =~ '^\(xterm\|screen\)$' && $COLORTERM == 'gnome-terminal'
	set t_Co=256
endif
set t_Co=256

colorscheme distinguished

" Save local settings (folds and such)
au BufWinLeave * silent! mkview
au BufWinEnter * silent! loadview


" Indenting
set cindent
set autoindent
set tabstop=4 " 8 this is the standard?
set shiftwidth=4

" AutoComplete/Preview
" let g:AutoComplPop_CompleteoptPreview = 1
" let OmniCpp_ShowPrototypeInAbbr = 1

" Searching
set incsearch
set hlsearch


" !!!!!!!!!!!! UNDER CONSTRUCTION !!!!!!!!!!!!!!
" TODO: ANY new buffer being open which may trigger colorscheme, edit
" t:colorscheme OR is it all done through ColorScheme event anyways?
au BufReadPost,FileReadPost * let t:colorscheme = g:colors_name
au ColorScheme * let t:colorscheme = g:colors_name
au ColorScheme * highlight CTagsClass cterm=bold ctermfg=Red


" Autocomplete stuff
let g:clang_user_options='|| exit 0'
nmap <F8> :TagbarToggle<CR>



" EasyMotion Colour Setting
hi clear EasyMotionTarget
au BufEnter * hi EasyMotionTarget term=bold cterm=bold ctermfg=25 gui=bold guifg=#ff0000
au BufEnter * hi EasyMotionShade term=bold cterm=bold ctermfg=25 gui=bold guifg=#aaaaaa


" [[ jumps without { } being in 1st column
map [[ ?{<CR>w99[{
" map ][ \}<CR>b99]}
map ]] j0[[%/{<CR>
" map [] k$][%?}<CR>



" If you prefer the Omni-Completion tip window to close when a selection is
" made, these lines close it on movement in insert mode or when leaving
" insert mode
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif
inoremap <expr> <CR> pumvisible() ? "\<CR>\<CR>" : "\<CR>"




" delete without yanking
" nnoremap <leader>d "_d
" vnoremap <leader>d "_d

" replace currently selected text with default register
" without yanking it
vnoremap <leader>p "_dP


" ######## JB Moving Tricks ####################################


" move to nearest <>[]{}() ,. /\ -=_+ `~!@#$%^&* ;: '"
function! JBGetMove(flags)
	let pos = searchpos("<\\|>\\|]\\|[\\|)\\|(\\|}\\|{\\|,\\|\\.\\|/\\|\\\\\\|-\\|=\\|+\\|_\\|;\\|:\\|`\\|\\~\\|!\\|@\\|#\\|\\$\\|%\\|\\^\\|&\\|*\\|\\\"\\|'\\||",a:flags)
	return pos
endfunction

" move to the nearest character within a:chars
" TODO: end portion (mark, silent exec)
" TODO: backwards search in vmode gets WRONG column (getpos('v') ==
" getpos('.') is wrong)
let jtimes=0
let jcall=0
let jcalled=0
function! JBMoveTo(chars,flags,mode)
	" setup our needles in the haystack 
	let needles=[]
	let i=0
	while i<len(a:chars)
		let needles=add(needles,a:chars[i])
		let i+=1
	endwhile
	

	" search for the first matching needle in the haystack
	let dowhile=1
	let pos=[0,0]
	let origpos = getpos('.')
	let curpos = getpos('.')
	let vmode = 0
	if (a:mode == "v" || a:mode == "V" || a:mode == "\<C-V>")
		" must move cursor to end of selection
		let vmode = 1
		if (a:flags =~ "b")
			let curpos = getpos('.')
		else
			let curpos = getpos("'>")
		endif

		" NOTE: there is a weird vimscript thing where visualmode forces the
		" map to be called once for each line in the selection
		" This fix does a count for the number of lines selected, then
		" decrements until we're on the last call
		if !g:jcall
			let g:jcall=1
			let g:jtimes=abs(curpos[1] - origpos[1])
			if (g:jtimes==0)
				let g:jcall=0
			else
				return
			endif
		else
			let g:jtimes-=1
			if g:jtimes>0
				return
			endif
			let g:jcall=0
		endif

	let g:jcalled=getpos("'<")[2]
		call cursor(curpos[1], curpos[2])

	endif
	while pos[0]!=0 || dowhile==1
		let dowhile=0
		let pos=JBGetMove(a:flags)
		if pos[0]!=0
			for needle in needles
				if needle==getline(pos[0])[pos[1]-1]
					if (vmode == 1)
						exec 'normal! v'
						call cursor(origpos[1], origpos[2])
						mark '
						silent exec 'normal! gv'
					endif
					call cursor(pos[0], pos[1])
					return
				endif
			endfor
		endif
	endwhile
	mark '
	silent exec 'normal! gv'
	call cursor(curpos[1], curpos[2])
endfunction

" get number of spaces on given line
function! JBGetSpacesAt(lnum)
	let line=getline(a:lnum)
	let i=0
	let spaces=0
	while i<len(line)
		if char2nr(line[i]) == 32 " space
			let spaces+=1
		elseif char2nr(line[i]) == 9 " tab
			let spaces+=&tabstop
		else
			return spaces
		endif
		
		let i+=1
	endwhile
	return 0
endfunction

" jump to next line with indentation <= indentation on current line
" a:direction - +1 for downwards, -1 for upwards
let jbl1=0
let jbl2=0
let jbl3=0
let jbl4=0
function! JBJumpNextIndentLine(direction,exactmatch,mode)
	let curpos=getpos('.')
	let origpos=getpos('.')
	let newpos=getpos('.')
	let curindent=JBGetSpacesAt(curpos[1])
	let lnum=curpos[1]
	let foundindent=-1

	" upwards motion
	if a:direction<0
		let lnum-=1
		while lnum>0
			let foundindent=JBGetSpacesAt(lnum)
			if (foundindent==curindent || (a:exactmatch==0 && foundindent<curindent)) && len(getline(lnum))>0
				break
			endif
			let lnum-=1
		endwhile
	elseif a:direction>0
		let lnum+=1
		let numlines=line('$')
		while lnum<=numlines
			let foundindent=JBGetSpacesAt(lnum)
			if (foundindent==curindent || (a:exactmatch==0 && foundindent<curindent)) && len(getline(lnum))>0
				break
			endif
			let lnum+=1
		endwhile
	endif


	let newpos = [lnum, foundindent]

	if (newpos==curpos)
		return
	endif






	let vmode = 0
	if (a:mode == "v" || a:mode == "V" || a:mode == "\<C-V>")
		" must move cursor to end of selection
		let vmode = 1
		if (a:direction>0)
			let curpos = [0, getpos("'>")[1], col('.')]
		else
			let curpos = [0, getpos(".")[1], col('.')]
		endif

		" NOTE: there is a weird vimscript thing where visualmode forces the
		" map to be called once for each line in the selection
		" This fix does a count for the number of lines selected, then
		" decrements until we're on the last call
		if !g:jcall
			let g:jcall=1
			let g:jtimes=abs(getpos("'<")[1] - getpos("'>")[1])
			if (g:jtimes==0)
				let g:jcall=0
			else
				return
			endif
		else
			let g:jtimes-=1
			if g:jtimes>0
				return
			endif
			let g:jcall=0
		endif

		if (vmode == 1)
			exec 'normal! v'
			call cursor(origpos[1], origpos[2])
			mark '
			silent exec 'normal! gv'
		endif
		call cursor(lnum, foundindent)

	else
		call cursor(lnum, foundindent)
		normal ^
	endif

	echo lnum + "," + foundindent


endfunction

nnoremap <C-k> :call JBJumpNextIndentLine(-1,0,'n')<CR>
nnoremap <C-j> :call JBJumpNextIndentLine( 1,0,'n')<CR>
nnoremap <C-n> :call JBJumpNextIndentLine( 1,1,'n')<CR>
nnoremap <C-m> :call JBJumpNextIndentLine(-1,1,'n')<CR>
vnoremap <C-k> :call JBJumpNextIndentLine(-1,0,visualmode())<CR>
vnoremap <C-j> :call JBJumpNextIndentLine( 1,0,visualmode())<CR>
vnoremap <C-n> :call JBJumpNextIndentLine( 1,1,visualmode())<CR>
vnoremap <C-m> :call JBJumpNextIndentLine(-1,1,visualmode())<CR>

" let move_symbols='<>[](){},./\\-=+_;:`~!@#$%^&*"\|'."'"
let move_symbols=',./\\-=_;:?$(){}[]'
nnoremap <C-l> :call JBMoveTo(move_symbols,'W','n')<CR>
nnoremap <C-h> :call JBMoveTo(move_symbols,'Wb','n')<CR>
vnoremap <C-l> :call JBMoveTo(move_symbols,'W',visualmode())<CR>
vnoremap <C-h> :call JBMoveTo(move_symbols,'Wb',visualmode())<CR>



" ######## JB Arg Spacing ####################################

function! JB_SpaceArg()
	let curpos=getpos('.')
	normal vi(S  
	call cursor(curpos[1], curpos[2]+1)
endfunction

nnoremap <C-@> :call JB_SpaceArg()<CR>



" ######## Rainbow Parentheses ####################################

au VimEnter,BufEnter,WinEnter,TabEnter * call JB_Rainbow()
function! JB_Rainbow()
	" NOTE: errors in php, so lets not bother wasting the same amount of time
	" that everyone else has so far :(
	let RainbowEnabledLanguages = ['cpp','c','javascript','haskell','java','noext']
	if index(RainbowEnabledLanguages,&ft) != -1
		RainbowParenthesesEnable
	endif
endfunction

" ######## MatchAlways Tags ######################################
let g:mta_filetypes = {
	\ 'html' : 1,
	\ 'xhtml' : 1,
	\ 'xml' : 1,
	\ 'jinja' : 1,
	\ 'php' : 1,
	\}



" ######## Show Syntax ###########################################
map <F12> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" ######## Easy tab switching ####################################
map <Left> gT
map <Right> gt

set mouse=a " tty mouse (scroll up/down properly)
map <F4> :TlistToggle<CR>
" autocmd CursorMoved * exe printf('match IncSearch /\V\<%s\>/', escape(expand('<cword>'), '/\'))
:let g:session_autoload = 'no'
:set completefunc=ClangComplete
:set completeopt=menu,menuone

:set tags+=/usr/local/include/tags
:set tags+=/usr/include/tags
