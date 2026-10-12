let s:missing = []
for [s:name, s:plugin] in items(g:plugs)
    if !isdirectory(s:plugin.dir . '/.git') || empty(glob(s:plugin.dir . '/*'))
        call add(s:missing, s:name)
    endif
endfor
if !empty(s:missing)
    echomsg '插件安装失败：' . join(s:missing, ', ')
    if !empty($VIM_SPEC_PLUGIN_LOG)
        for s:buffer in getbufinfo()
            if getbufvar(s:buffer.bufnr, '&filetype') ==# 'vim-plug'
                call writefile(getbufline(s:buffer.bufnr, 1, '$'), $VIM_SPEC_PLUGIN_LOG)
                call setfperm($VIM_SPEC_PLUGIN_LOG, 'rw-------')
                break
            endif
        endfor
    endif
    cquit
endif
