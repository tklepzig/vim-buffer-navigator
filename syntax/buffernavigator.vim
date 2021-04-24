" hide the file marker
exec 'syntax match BufferNavigatorFileMarker #\%d' . char2nr(s:fileMarker) . '# conceal containedin=ALL'
exec 'syntax match BufferNavigatorModifiedMarker #\%d' . char2nr(s:modifiedMarker) . '# conceal containedin=ALL'

" all lines are directories
exec 'syntax match BufferNavigatorDir "\v^.*$"'

" ...except the ones with the marker in it
exec 'syntax match BufferNavigatorFile #^\s*\%d' . char2nr(s:fileMarker) . '.*$#'

" highlight modified files
exec 'syntax match BufferNavigatorModifiedFile #^\s*\%d' . char2nr(s:fileMarker) . '\%d' . char2nr(s:modifiedMarker) . '.*$#'

highlight BufferNavigatorFile ctermbg=NONE ctermfg=Blue guibg=NONE guifg=Blue
highlight BufferNavigatorModifiedFile ctermbg=NONE ctermfg=214 guibg=NONE guifg=Orange
highlight BufferNavigatorDir ctermbg=NONE ctermfg=White guibg=NONE guifg=White
