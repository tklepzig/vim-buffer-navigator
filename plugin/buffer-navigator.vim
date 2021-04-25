let s:bufferLineMapping = {}
let s:optionWindowWidth = ['BufferNavigatorWinWidth', 40]
let s:buffername = "buffer-navigator"
let s:fileMarker = "\x07"
let s:modifiedMarker = "\x06"

function! s:BuffersToTree(buffers)
  let tree = []
  for buffer in a:buffers
    let tree = s:AddBufferToTree(buffer, tree)
  endfor
  return tree
endfunction

function! s:AddBufferToTree(buffer, tree = [])
  let pathSegments = split(a:buffer.name, "/")

  if len(pathSegments) == 1
    return a:tree + [
          \{ "name": (a:buffer.modified ? s:modifiedMarker : "") . pathSegments[0],
          \  "bufferNumbers": [a:buffer.nr],
          \  "children": [] }
          \]
  endif

  let existingNode = s:FindInList(a:tree, { x -> x.name == pathSegments[0] })

  if type(existingNode) != v:t_dict
    let children = s:AddBufferToTree(extend(a:buffer, { "name": join(pathSegments[1:], "/") }))
    return a:tree + [
          \{ "name": pathSegments[0],
          \  "bufferNumbers": s:Flatten(s:Map({ k, v -> v.bufferNumbers }, children)),
          \  "children": children }
          \]
  endif

  return s:Map(function("s:AppendChildren", [pathSegments, a:buffer]), a:tree)
endfunction

function! s:AppendChildren(pathSegments, buffer, k, v)
  if a:v.name == a:pathSegments[0]
    let children = s:AddBufferToTree(extend(a:buffer, { "name": join(a:pathSegments[1:], "/") }), a:v.children)
    return extend(a:v, {
          \ "bufferNumbers": s:Flatten(s:Map({ k, v -> v.bufferNumbers }, children)),
          \ "children": children })
  endif
  return a:v
endfunction

function! s:TreeToLines(tree, startLineNr = 1, level = 0)
  let lines = []
  let lineNr = a:startLineNr
  for item in a:tree
    let isLeaf = len(item.children) == 0
    call add(lines, repeat("  ", a:level) . (isLeaf ? s:fileMarker : "") . item.name)
    let s:bufferLineMapping[lineNr] = item.bufferNumbers

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

function! s:BuildBufferList()
  redir => buffers
  execute('silent ls')
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
    echom tar
  endif
endfunction

function! s:Open()
  let bufnr = bufnr(s:buffername)
  if bufnr > 0 && bufexists(bufnr)
    return
  endif

  let bufferlist = s:BuildBufferList()
  let [bufferliststr,_] = s:TreeToLines(s:BuffersToTree(bufferlist))

  let currentBufferNumber = bufnr("%")
  let currentBuffer = s:FindInDict(s:bufferLineMapping, { k, v -> len(v) == 1 && v[0] == currentBufferNumber })

  aboveleft vnew
  call setline(1, bufferliststr)
  execute 'file ' . s:buffername

  if type(currentBuffer) == v:t_list
    let [lineNr,_] = currentBuffer
    call setpos(".", [0, lineNr, 1])
  endif

  let [winWidthName, winWidthDefault] = s:optionWindowWidth
  execute "vertical resize " . get(g:,winWidthName, winWidthDefault)

  setlocal buftype=nofile bufhidden=wipe nowrap noswapfile
  setlocal readonly nomodifiable nobuflisted nonumber nofoldenable
  setlocal filetype=buffernavigator
  setlocal conceallevel=2 concealcursor=nvic

  nnoremap <script> <silent> <nowait> <buffer> <CR> :call <SID>SelectBuffer()<CR>
  nnoremap <script> <silent> <nowait> <buffer> o    :call <SID>SelectBuffer()<CR>
  nnoremap <script> <silent> <nowait> <buffer> v    :call <SID>SelectBuffer("vertical s")<CR>
  nnoremap <script> <silent> <nowait> <buffer> s    :call <SID>SelectBuffer("s")<CR>
  nnoremap <script> <silent> <nowait> <buffer> z    :call <SID>ToggleZoom()<CR>
endfunction

function! s:ToggleZoom()
  let [winWidthName, winWidthDefault] = s:optionWindowWidth
  let winWith = get(g:,winWidthName, winWidthDefault)

  if winwidth(0) > winWidth
  execute "vertical resize " . winWidth
  else
    vertical resize
  endif
endfunction

function! s:Close()
  let bufnr = bufnr(s:buffername)
  if bufnr > 0 && bufexists(bufnr)
    execute 'bwipeout! ' . bufnr
  endif
endfunction

function! s:SelectBuffer(split = "")
  let lineNr = line(".")
  if has_key(s:bufferLineMapping, lineNr) && len(s:bufferLineMapping[lineNr]) == 1
    let bufnr = s:bufferLineMapping[lineNr][0]
    if bufnr > 0 && bufexists(bufnr)
      call s:Close()
      execute 'silent ' . a:split . 'buffer' bufnr
    endif
  endif
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

nnoremap <silent> <leader>b :BufferNavigatorToggle<cr>
