let s:fileMarker = "07"
let s:modifiedMarker = "06"
let s:optionHighlightRules = ['BufferNavigatorHighlightRules', []]

exec 'syntax match BufferNavigatorFileMarker #\m\%d' . s:fileMarker . '# conceal containedin=ALL'
exec 'syntax match BufferNavigatorModifiedMarker #\m\%d' . s:modifiedMarker . '# conceal containedin=ALL'
exec 'syntax match BufferNavigatorDir #\m^.*$# contains=BufferNavigatorFile'
exec 'syntax match BufferNavigatorFile #\m\%d' . s:fileMarker . '.*#'
exec 'syntax match BufferNavigatorModifiedFile #\m\%d' . s:fileMarker . '\%d' . s:modifiedMarker . '.*# containedin=ALL'

for rule in get(g:,s:optionHighlightRules[0], s:optionHighlightRules[1])
  let [name, kind, regexp, ctermbg, ctermfg, guibg, guifg] = rule
  if kind == "file"
    exec 'syntax match ' . name . ' #\m\%d' . s:fileMarker . '' . regexp . '# containedin=BufferNavigatorFile'
  elseif kind == "dir"
    exec 'syntax match ' . name . ' #\m' . regexp . '#'
  endif
  exec 'highlight ' . name . ' ctermbg='. ctermbg . ' ctermfg=' . ctermfg . ' guibg=' . guibg . ' guifg=' . guifg
endfor

highlight BufferNavigatorFile ctermbg=NONE ctermfg=75 guibg=NONE guifg=Blue
highlight BufferNavigatorModifiedFile ctermbg=NONE ctermfg=214 guibg=NONE guifg=Orange
highlight BufferNavigatorDir ctermbg=NONE ctermfg=white guibg=NONE guifg=White
