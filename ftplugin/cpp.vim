colorscheme asu1dark

hi! link CTagsClass Type 
hi! link CTagsGlobalVariable Tag
hi! link CTagsLocalVariable Tag
hi! link CTagsMember Tag
hi! link CTagsFunction Function

au VimEnter,BufEnter,WinEnter,TabEnter *.h set textwidth=60
au VimEnter,BufEnter,WinEnter,TabEnter *.cpp set textwidth=120
