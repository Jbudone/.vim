
"set background=light
set sessionoptions-=options
call pathogen#infect()
syntax on
filetype plugin indent on
au BufNewFile,BufRead * if &ft == '' | set ft=noext | endif


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
nnoremap <leader>d "_d
vnoremap <leader>d "_d

" replace currently selected text with default register
" without yanking it
vnoremap <leader>p "_dP



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
