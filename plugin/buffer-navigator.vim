let s:optionWindowWidth = ['BufferNavigatorWidth', 40]
let s:optionHighlightRules = ['BufferNavigatorHighlightRules', []]
let s:optionMode = ['BufferNavigatorMode', 'tree']
let s:optionMapKeys = ['BufferNavigatorMapKeys', 1]
let s:optionAmbiguousDirNames = ['BufferNavigatorAmbiguousDirNames', []]

let s:bufferLineMapping = {}
let s:currentMode = get(g:,s:optionMode[0], s:optionMode[1])
let s:ambigousDirNames = get(g:,s:optionAmbiguousDirNames[0], s:optionAmbiguousDirNames[1])
let s:buffername = "buffer-navigator"
let s:fileMarker = "\x07"
let s:modifiedMarker = "\x06"
let s:previousWinId = -1

function! s:BuffersToTree(buffers)
  let tree = []
  for buffer in a:buffers
    let tree = s:AddBufferToTree(buffer, tree)
  endfor
  return tree
endfunction

function! s:AddBufferToTree(buffer, tree)
  let pathSegments = split(a:buffer.name, "/")

  if len(pathSegments) == 1
    return a:tree + [
          \{ "name": (a:buffer.modified ? s:modifiedMarker : "") . pathSegments[0],
          \  "bufferNumber": a:buffer.nr,
          \  "children": [] }
          \]
  endif

  let existingNode = s:FindInList(a:tree, { x -> x.name ==# pathSegments[0] })

  if type(existingNode) != v:t_dict
    let children = s:AddBufferToTree(extend(a:buffer, { "name": join(pathSegments[1:], "/") }), [])
    return a:tree + [
          \{ "name": pathSegments[0],
          \  "bufferNumber": s:Flatten(s:Map({ k, v -> v.bufferNumber }, children)),
          \  "children": children }
          \]
  endif

  return s:Map(function("s:AppendChildren", [pathSegments, a:buffer]), a:tree)
endfunction

function! s:AppendChildren(pathSegments, buffer, k, v)
  if a:v.name ==# a:pathSegments[0]
    let children = s:AddBufferToTree(extend(a:buffer, { "name": join(a:pathSegments[1:], "/") }), a:v.children)
    return extend(a:v, {
          \ "bufferNumber": s:Flatten(s:Map({ k, v -> v.bufferNumber }, children)),
          \ "children": children })
  endif
  return a:v
endfunction

function! s:TreeToLines(tree, startLineNr, level)
  let lines = []
  let lineNr = a:startLineNr
  for item in a:tree
    let isLeaf = len(item.children) == 0
    call add(lines, repeat("  ", a:level) . (isLeaf ? s:fileMarker : "") . item.name)
    let s:bufferLineMapping[lineNr] = item.bufferNumber

    if len(item.children) > 0
      let [childrenLines, newStartLineNr] = s:TreeToLines(item.children, lineNr + 1, a:level + 1)
      let lines = lines + childrenLines
      let lineNr = newStartLineNr
    else
      let lineNr += 1
    endif
  endfor
  return [lines, lineNr]
endfunction

function! s:BuildBufferList(sortByLastOpened)
  redir => buffers
  execute('silent ls' . (a:sortByLastOpened ? ' t' : ''))
  redir END

  let bufferlist = []
  for buf in split(buffers, '\n')
    let bufattr = split(buf, '"')[0]
    let bufnr = str2nr(bufattr)
    let name = bufname(bufnr)
    let modified = getbufinfo(bufnr)[0].changed
    if empty(name)
      let name = "[No Name]"
    endif

    call add(bufferlist, {"nr": bufnr, "name": fnamemodify(name, ":p:~:."), "modified": modified})
  endfor
  return bufferlist
endfunction

function! s:Toggle()
  let bufnr = bufnr(s:buffername)
  if bufnr > 0 && bufexists(bufnr)
    call s:Close()
  else
    call s:Open()
  endif
endfunction

function! s:Focus()
  let bufnr = bufnr(s:buffername)
  if bufnr > 0 && bufexists(bufnr)
    let targetWinNr = filter(range(1, winnr('$')), { i, winnr -> winbufnr(winnr) == bufnr })
    if len(targetWinNr) > 0
      " TODO: focus line with current open buffer (extract logic from Open())
      execute targetWinNr[0] . 'wincmd w'
    endif
  endif
endfunction

function! s:BuildMRUEntry(buffer)
    let pathSegments = split(a:buffer.name, "/")

    if len(pathSegments) == 1
      return s:fileMarker . (a:buffer.modified ? s:modifiedMarker : "") . pathSegments[0]
    endif

    if len(pathSegments) == 2 || index(s:ambigousDirNames, pathSegments[-2]) == -1
      return pathSegments[-2] . "/" . s:fileMarker . (a:buffer.modified ? s:modifiedMarker : "") . pathSegments[-1]
    endif

    return pathSegments[-3] . "/" . pathSegments[-2] . "/" . s:fileMarker . (a:buffer.modified ? s:modifiedMarker : "") . pathSegments[-1]
endfunction

function! s:PrintMRU()
  let s:bufferLineMapping = {}
  let bufferlist = s:BuildBufferList(1)
  let currentBufferNumber = bufnr("#")
  let lines = []
  let lineNr = 1

  for buffer in bufferlist
    if buffer.nr == currentBufferNumber 
      continue
    endif

    call add(lines, s:BuildMRUEntry(buffer))

    let s:bufferLineMapping[lineNr] = buffer.nr
    let lineNr += 1
  endfor
  call setline(1, lines)
endfunction

function! s:PrintLines()
  let s:bufferLineMapping = {}
  let bufferlist = s:BuildBufferList(0)
  let [bufferLines, _] = s:TreeToLines(s:BuffersToTree(bufferlist), 1, 0)
  call setline(1, bufferLines)
endfunction

function! s:Open()
  let bufnr = bufnr(s:buffername)
  if bufnr > 0 && bufexists(bufnr)
    return
  endif

  let s:previousWinId = win_getid()
  aboveleft vnew
  execute 'file ' . s:buffername
  execute "vertical resize " . get(g:,s:optionWindowWidth[0], s:optionWindowWidth[1])

  setlocal filetype=buffernavigator

  call s:Refresh(1)

  " TODO: Use autocmd FileType?
  nnoremap <script> <silent> <nowait> <buffer> <CR> :call <SID>SelectBuffer("", 0)<CR>
  nnoremap <script> <silent> <nowait> <buffer> o    :call <SID>SelectBuffer("", 0)<CR>
  nnoremap <script> <silent> <nowait> <buffer> v    :call <SID>SelectBuffer("vertical s", 0)<CR>
  nnoremap <script> <silent> <nowait> <buffer> s    :call <SID>SelectBuffer("s", 0)<CR>
  nnoremap <script> <silent> <nowait> <buffer> p    :call <SID>SelectBuffer("", 1)<CR>
  nnoremap <script> <silent> <nowait> <buffer> r    :call <SID>Refresh(1)<CR>
  nnoremap <script> <silent> <nowait> <buffer> m    :call <SID>ToggleMode()<CR>
  nnoremap <script> <silent> <nowait> <buffer> x    :call <SID>CloseBuffers()<CR>
  nnoremap <script> <silent> <nowait> <buffer> z    :call <SID>ToggleZoom()<CR>
endfunction

function! s:ToggleMode()
  let s:currentMode = s:currentMode == "tree" ? "mru" : "tree"
  call setpos(".", [0, 1, 1])
  call s:Refresh(1)
endfunction

function! s:ToggleZoom()
  let winWidth = get(g:,s:optionWindowWidth[0], s:optionWindowWidth[1])

  if winwidth(0) > winWidth
  execute "vertical resize " . winWidth
  else
    vertical resize
  endif
endfunction

function! s:Close()
  let bufnr = bufnr(s:buffername)
  if bufnr > 0 && bufexists(bufnr)
    if s:previousWinId > 0
      call win_gotoid(s:previousWinId)
    endif
    execute 'bwipeout! ' . bufnr
  endif
endfunction

function! s:SelectBuffer(split, preview)
  let bufnr = s:BufNrFromCurrentLine()

  if type(bufnr) == v:t_list && len(bufnr) > 1
    return
  endif

  let nr = type(bufnr) == v:t_list ? bufnr[0] : bufnr
  if nr > 0 && bufexists(nr)
    if s:previousWinId > 0 && win_gettype(s:previousWinId) != "unknown"
      call win_execute(s:previousWinId, 'silent ' . a:split . 'buffer' . nr)
    else
      " the previous window does not exist anymore (maybe because
      " it was closed via 'x', ...), therefore open the buffer directly in the
      " current window where the buffer navigator is open
      execute 'silent ' . a:split . 'buffer' . nr
    endif

      if !a:preview
        call s:Close()
      endif
  endif
endfunction

function! s:Refresh(selectCurrentBuffer)
  let previousLineNr = line(".")
  setlocal noreadonly modifiable
  call deletebufline("%", 1, "$")
  if s:currentMode == "tree"
    call s:PrintLines()
  else 
    call s:PrintMRU()
  endif
  setlocal readonly nomodifiable

  if !a:selectCurrentBuffer || s:currentMode == "mru"
    call setpos(".", [0, previousLineNr, 1])
  else
    let currentBufferNumber = bufnr("#")
    let currentBuffer = s:FindInDict(s:bufferLineMapping, { k, v -> type(v) == v:t_number && v == currentBufferNumber })
    if type(currentBuffer) == v:t_list
      let [lineNr,_] = currentBuffer
      call setpos(".", [0, lineNr, 1])
    endif
  endif
endfunction

function! s:CloseBuffers()
  let bufnr = s:BufNrFromCurrentLine()
  let bufnrs = type(bufnr) == v:t_number ? [bufnr] : bufnr
  execute 'silent bdelete' . join(bufnrs, ' ')
  call s:Refresh(0)
endfunction

function! s:BufNrFromCurrentLine()
  let lineNr = line(".")
  if has_key(s:bufferLineMapping, lineNr)
    return s:bufferLineMapping[lineNr]
  endif
  return -1
endfunction

function! s:Map(fn, l)
  let new_list = deepcopy(a:l)
  call map(new_list, a:fn)
  return new_list
endfunction

function! s:FindInList(list, fn)
  for item in a:list
    if a:fn(item)
      return item
    endif
  endfor
endfunction

function! s:FindInDict(dict, fn)
  for [key, value] in items(a:dict)
    if a:fn(key, value)
      return [key, value]
    endif
  endfor
endfunction

function! s:Flatten(list)
  let val = []
  for elem in a:list
    if type(elem) == v:t_list
      call extend(val, s:Flatten(elem))
    else
      call add(val, elem)
    endif
    unlet elem
  endfor
  return val
endfunction

command! BufferNavigatorOpen :call <SID>Open()
command! BufferNavigatorClose :call <SID>Close()
command! BufferNavigatorFocus :call <SID>Focus()
command! BufferNavigatorToggle :call <SID>Toggle()

if get(g:, s:optionMapKeys[0], s:optionMapKeys[1])
  nnoremap <silent> <leader>b :BufferNavigatorToggle<cr>
endif
