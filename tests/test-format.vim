execute 'lcd ' . fnameescape($VIM_SPEC_HOME)
let s:path = $VIM_SPEC_HOME . '/format sample ; $(touch injected).py'
call writefile(['disk'], s:path)
execute 'edit ' . fnameescape(s:path)
call setline(1, 'unsaved')
setlocal readonly
call assert_equal(0, FormatCode(), '只读文件')
call assert_equal(['disk'], readfile(s:path))
setlocal noreadonly
setlocal nomodifiable
call assert_equal(0, FormatCode(), '不可修改缓冲区')
setlocal modifiable
setlocal buftype=nofile
call assert_equal(0, FormatCode(), '特殊缓冲区')
setlocal buftype=
setlocal filetype=text
call assert_equal(0, FormatCode(), '不支持的文件类型')
call assert_equal(1, &modified)
setlocal filetype=python
call setfperm($VIM_SPEC_TEST_TOOL, 'rw-------')
call assert_equal(0, FormatCode(), '缺失工具')
call assert_equal(['disk'], readfile(s:path))
call assert_equal(1, &modified)
call setfperm($VIM_SPEC_TEST_TOOL, 'rwx------')
let $VIM_SPEC_FORMAT_FAIL = '1'
let g:format_reload_count = 0
augroup FormatTest
    autocmd!
    autocmd BufReadPost * let g:format_reload_count += 1
augroup END
call assert_equal(0, FormatCode(), '格式化工具失败')
call assert_equal('unsaved', getline(1))
call assert_equal(['unsaved'], readfile(s:path))
call assert_equal(0, g:format_reload_count, '失败不重新加载文件')
let $VIM_SPEC_FORMAT_FAIL = '0'
call setline(1, 'pending')
call assert_equal(1, FormatCode(), '格式化成功')
call assert_equal(['formatted'], readfile(s:path))
call assert_equal('formatted', getline(1))
call assert_equal(0, &modified)
call assert_equal(1, g:format_reload_count)
call assert_equal([s:path], readfile($VIM_SPEC_HOME . '/formatter-argument.log'), '文件路径作为完整单个参数')
call assert_false(filereadable($VIM_SPEC_HOME . '/injected'), '无 Shell 注入')
enew
setlocal filetype=python
call setline(1, 'unnamed')
call assert_equal(0, FormatCode(), '未命名文件')
call assert_equal(1, &modified)
if !empty(v:errors)
    call writefile(v:errors, $VIM_SPEC_HOME . '/errors.log')
    cquit
endif
qa!
