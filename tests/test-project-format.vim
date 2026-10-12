execute 'lcd ' . fnameescape($VIM_SPEC_HOME)
let s:cwd = getcwd()
for [s:project, s:expected] in [['project-a with spaces', 'prettier-2'], ['project-b', 'prettier-3'], ['project-c', 'global-prettier']]
    let s:root = $VIM_SPEC_HOME . '/' . s:project
    let s:file = s:root . '/src/sample.js'
    execute 'edit ' . fnameescape(s:file)
    call setline(1, 'before')
    call assert_equal(1, FormatCode())
    call assert_equal(s:expected, getline(1))
    call assert_equal(s:expected . '|' . s:root . '|' . s:file, readfile($VIM_SPEC_HOME . '/tool-calls.log')[-1])
    call assert_equal(s:cwd, getcwd(), '不改变 Vim 工作目录')
endfor
" 本地版本存在时，即使没有全局 Prettier 也应可用。
call setfperm($VIM_SPEC_TEST_BIN . '/prettier', 'rw-------')
execute 'edit ' . fnameescape($VIM_SPEC_HOME . '/project-a with spaces/src/local-only.js')
call setline(1, 'local')
call assert_equal(1, FormatCode())
call assert_equal('prettier-2', getline(1))

execute 'edit ' . fnameescape($VIM_SPEC_HOME . '/sample.go')
" 模拟 vim-go 的 BufWritePre 钩子，验证手动保存不会额外格式化。
let g:go_fmt_autosave = 1
let g:go_imports_autosave = 1
let g:save_format_count = 0
augroup GoFormatTest
    autocmd!
    autocmd BufWritePre *.go if g:go_fmt_autosave || g:go_imports_autosave | let g:save_format_count += 1 | endif
augroup END
let s:before = len(readfile($VIM_SPEC_HOME . '/tool-calls.log'))
call setline(1, 'pending')
call assert_equal(1, FormatCode())
call assert_equal('goimports', getline(1))
call assert_equal(s:before + 1, len(readfile($VIM_SPEC_HOME . '/tool-calls.log')))
call assert_equal(0, g:save_format_count)
call assert_equal(1, g:go_fmt_autosave)
call assert_equal(1, g:go_imports_autosave)
call setline(1, 'ordinary save')
write
call assert_equal(1, g:save_format_count, '普通保存仍然触发钩子')
call setfperm($VIM_SPEC_TEST_BIN . '/goimports', 'rw-------')
call setline(1, 'fallback')
call assert_equal(1, FormatCode())
call assert_equal('gofmt', getline(1))
call assert_equal(1, g:save_format_count)
let $VIM_SPEC_FORMAT_FAIL = '1'
call setline(1, 'failure')
call assert_equal(0, FormatCode())
call assert_equal('failure', getline(1))
call assert_equal(1, g:go_fmt_autosave)
call assert_equal(1, g:go_imports_autosave)
if !empty(v:errors)
    call writefile(v:errors, $VIM_SPEC_HOME . '/project-errors.log')
    cquit
endif
qa!
