#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
mkdir -p "$repo_dir/.tmp/tests"
test_dir="$(mktemp -d "$repo_dir/.tmp/tests/install.XXXXXX")"
export VIM_SPEC_HOME="$test_dir/home with spaces"
mkdir -p "$VIM_SPEC_HOME/.vim/autoload" "$VIM_SPEC_HOME/.vim/colors"
printf '" old vimrc\n' > "$VIM_SPEC_HOME/.vimrc"
printf '" old plug\n' > "$VIM_SPEC_HOME/.vim/autoload/plug.vim"
printf '" keep custom colors\n' > "$VIM_SPEC_HOME/.vim/colors/custom.vim"
bash "$repo_dir/install.sh" --skip-plugins
test "$(readlink "$VIM_SPEC_HOME/.vimrc")" = "$repo_dir/vimrc"
test "$(readlink "$VIM_SPEC_HOME/.vim/autoload/plug.vim")" = "$repo_dir/vendor/plug.vim"
backup_dir="$(find "$VIM_SPEC_HOME/.vim/config-backups" -mindepth 1 -maxdepth 1 -type d)"
test "$(cat "$backup_dir/vimrc")" = '" old vimrc'
test "$(cat "$backup_dir/plug.vim")" = '" old plug'
test -f "$VIM_SPEC_HOME/.vim/colors/custom.vim"
for directory in backup swap undo; do
    test -d "$VIM_SPEC_HOME/.vim/$directory"
done
bash "$repo_dir/install.sh" --skip-plugins
test "$(find "$VIM_SPEC_HOME/.vim/config-backups" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = 1

cat > "$test_dir/check.vim" <<'VIM'
call assert_equal('', v:errmsg, '配置启动无错误')
call assert_equal(1, &number)
call assert_equal(0, &relativenumber)
call assert_equal(11, len(g:plugs))
call assert_equal($VIM_SPEC_HOME . '/.vim/backup//', &backupdir)
new example.py
call assert_equal('python', &filetype)
call assert_equal(4, &shiftwidth)
new example.json
call assert_equal('json', &filetype)
call assert_equal(2, &shiftwidth)
execute 'edit ' . fnameescape($VIM_SPEC_HOME . '/sample file.txt')
call setline(1, 'first')
write
call setline(1, 'second')
write
call assert_equal(['second'], readfile($VIM_SPEC_HOME . '/sample file.txt'))
call assert_false(empty(glob($VIM_SPEC_HOME . '/.vim/backup/*')), '生成文件备份')
call assert_false(empty(glob($VIM_SPEC_HOME . '/.vim/undo/*')), '生成撤销历史')
if !empty(v:errors)
    call writefile(v:errors, $VIM_SPEC_HOME . '/errors.log')
    cquit
endif
qa!
VIM
vim -N -i NONE -u "$VIM_SPEC_HOME/.vimrc" -es -S "$test_dir/check.vim"
if vim -N -i NONE -u "$VIM_SPEC_HOME/.vimrc" -es "+source $repo_dir/scripts/check-plugins.vim" '+qa'; then
    echo '失败：缺失插件没有被检测出来。' >&2
    exit 1
fi
if bash "$repo_dir/install.sh" --invalid; then
    echo '失败：无效参数被接受。' >&2
    exit 1
fi
echo '通过：首次安装、备份、重复安装、带空格路径、自定义文件保留、配置加载、语言缩进、缺失插件和无效参数检查。'
