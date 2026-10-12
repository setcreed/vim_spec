let s:missing = []
for [s:name, s:plugin] in items(g:plugs)
    if !isdirectory(s:plugin.dir . '/.git') || empty(glob(s:plugin.dir . '/*'))
        call add(s:missing, s:name)
    endif
endfor
if !empty(s:missing)
    echomsg '插件安装失败：' . join(s:missing, ', ')
    cquit
endif
